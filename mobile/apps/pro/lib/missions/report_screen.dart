import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';
import 'signature_screen.dart';

/// Compte rendu d'une intervention en cours : constantes, observations, actes, consommables,
/// photos, signature, puis clôture. Tant qu'il n'est pas validé, il s'enregistre en brouillon.
class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({required this.missionId, super.key});

  final String missionId;

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  final Map<Vital, TextEditingController> _vitals = <Vital, TextEditingController>{
    for (final vital in Vital.values) vital: TextEditingController(),
  };
  final TextEditingController _observations = TextEditingController();
  final Map<Vital, String> _vitalErrors = <Vital, String>{};
  List<ReportLine> _acts = <ReportLine>[];
  List<ReportLine> _consumables = <ReportLine>[];

  Intervention? _intervention;
  Mission? _mission;
  Object? _loadError;
  bool _busy = false;
  bool _cashCollected = false;
  String? _error;
  String? _observationsError;
  String? _info;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final controller in _vitals.values) {
      controller.dispose();
    }
    _observations.dispose();
    super.dispose();
  }

  bool get _isRemote => _mission?.isRemote ?? false;

  Future<void> _load() async {
    setState(() => _loadError = null);

    try {
      final intervention = await ref.read(proApiProvider).intervention(widget.missionId);
      // Le montant à encaisser vient de la liste des missions : pas de nouvelle lecture du dossier.
      final missions = await ref.read(missionsProvider.future);
      if (!mounted) {
        return;
      }

      for (final vital in Vital.values) {
        final value = intervention.vitals[vital];
        _vitals[vital]!.text = value == null ? '' : formatMeasure(value);
      }
      _observations.text = intervention.observations ?? '';

      setState(() {
        _intervention = intervention;
        _acts = List<ReportLine>.of(intervention.acts);
        _consumables = List<ReportLine>.of(intervention.consumables);
        _mission = missions.where((mission) => mission.id == widget.missionId).firstOrNull;
      });
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _loadError = failure);
      }
    }
  }

  /// Lit le formulaire. Renvoie `null` (et affiche les erreurs) si une constante est invraisemblable.
  ReportDraft? _draft() {
    final l10n = context.l10n;
    final values = <Vital, num>{};
    final errors = <Vital, String>{};

    for (final vital in Vital.values) {
      final text = _vitals[vital]!.text.trim().replaceAll(',', '.');
      if (text.isEmpty) {
        continue;
      }
      final value = num.tryParse(text);
      if (value == null || !vital.accepts(value)) {
        errors[vital] = l10n.vitalOutOfRange(formatMeasure(vital.min), formatMeasure(vital.max));
      } else {
        values[vital] = value;
      }
    }

    setState(() {
      _vitalErrors
        ..clear()
        ..addAll(errors);
    });

    if (errors.isNotEmpty) {
      return null;
    }

    return ReportDraft(
      vitals: values,
      observations: _observations.text.trim(),
      acts: _acts,
      consumables: _consumables,
    );
  }

  /// Exécute un appel au serveur qui renvoie l'intervention à jour.
  Future<bool> _run(Future<Intervention> Function() call, {String? info}) async {
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });

    try {
      final intervention = await call();
      if (mounted) {
        setState(() {
          _intervention = intervention;
          _info = info;
        });
      }
      return true;
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _save() async {
    final draft = _draft();
    if (draft == null) {
      return;
    }
    await _run(() => ref.read(proApiProvider).saveReport(widget.missionId, draft), info: context.l10n.reportSaved);
  }

  Future<void> _addPhoto() async {
    final photo = await ref.read(documentPickerProvider).pick(fromCamera: true);
    if (photo == null || !mounted) {
      return;
    }
    await _run(
      () => ref.read(proApiProvider).addReportPhoto(widget.missionId, bytes: photo.bytes, filename: photo.filename),
    );
  }

  Future<void> _sign() async {
    final signature = await Navigator.of(context).push<CollectedSignature>(
      MaterialPageRoute<CollectedSignature>(
        builder: (context) => SignatureScreen(initialName: _intervention?.signedByName ?? _mission?.patientName),
      ),
    );
    if (signature == null || !mounted) {
      return;
    }
    await _run(
      () => ref
          .read(proApiProvider)
          .signReport(widget.missionId, png: signature.png, signedByName: signature.signedByName),
    );
  }

  Future<void> _addLine({required bool act}) async {
    final line = await showDialog<ReportLine>(
      context: context,
      builder: (dialogContext) => _LineDialog(act: act),
    );
    if (line == null || !mounted) {
      return;
    }
    setState(() => act ? _acts = <ReportLine>[..._acts, line] : _consumables = <ReportLine>[..._consumables, line]);
  }

  Future<void> _complete() async {
    final l10n = context.l10n;
    final draft = _draft();
    if (draft == null) {
      return;
    }

    final missingObservations = (draft.observations ?? '').isEmpty;
    setState(() {
      _observationsError = missingObservations ? l10n.reportObservationsRequired : null;
      // À distance, le patient ne peut pas signer sur ce téléphone : la signature n'est pas demandée.
      _error = !missingObservations && !_isRemote && !(_intervention?.isSigned ?? false)
          ? l10n.reportSignatureRequired
          : null;
    });
    if (missingObservations || _error != null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.reportCompleteTitle),
        content: Text(l10n.reportCompleteBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.reportComplete)),
        ],
      ),
    );
    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    // Les dernières saisies sont enregistrées avant la validation, qui fige le compte rendu.
    final api = ref.read(proApiProvider);
    final done = await _run(() async {
      await api.saveReport(widget.missionId, draft);
      return api.complete(widget.missionId, cashCollected: _cashCollected);
    });
    if (!done || !mounted) {
      return;
    }

    ref.invalidate(missionsProvider);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.reportCompleted)));
    context.go(NcRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final textTheme = Theme.of(context).textTheme;
    final intervention = _intervention;

    if (intervention == null) {
      return NcPage(
        appBar: AppBar(),
        title: l10n.reportTitle,
        actions: <Widget>[if (_loadError != null) NcPrimaryButton(label: l10n.retry, onPressed: _load)],
        children: <Widget>[
          if (_loadError != null)
            NcNotice(message: failureMessage(context, _loadError!), kind: NcNoticeKind.error)
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final amount = _mission?.amountToCollect ?? 0;

    return NcPage(
      appBar: AppBar(),
      title: l10n.reportTitle,
      subtitle: _mission == null ? null : '${_mission!.serviceName}\n${_mission!.patientName}',
      actions: <Widget>[
        NcPrimaryButton(
          key: const ValueKey<String>('report-complete'),
          label: l10n.reportComplete,
          icon: Icons.check_circle_outline,
          isLoading: _busy,
          onPressed: _busy ? null : _complete,
        ),
        NcSecondaryButton(
          key: const ValueKey<String>('report-save'),
          label: l10n.reportSaveDraft,
          onPressed: _busy ? null : _save,
        ),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(key: const ValueKey<String>('report-error'), message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        if (_info != null) ...<Widget>[
          NcNotice(message: _info!),
          const SizedBox(height: NcSpacing.md),
        ],
        NcSectionTitle(l10n.reportVitalsTitle),
        for (final vital in Vital.values)
          Padding(
            padding: const EdgeInsets.only(bottom: NcSpacing.sm),
            child: TextField(
              key: ValueKey<String>('vital-${vital.name}'),
              controller: _vitals[vital],
              keyboardType: TextInputType.numberWithOptions(decimal: vital.isDecimal),
              // Les mesures se lisent de gauche à droite, même en arabe.
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(labelText: vitalLabel(l10n, vital), errorText: _vitalErrors[vital]),
            ),
          ),
        const SizedBox(height: NcSpacing.md),
        TextField(
          key: const ValueKey<String>('report-observations'),
          controller: _observations,
          minLines: 3,
          maxLines: 8,
          maxLength: 5000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.reportObservations, errorText: _observationsError),
        ),
        const SizedBox(height: NcSpacing.md),
        _Lines(
          title: l10n.reportActsTitle,
          addLabel: l10n.reportActAdd,
          addKey: 'report-add-act',
          lines: _acts,
          onAdd: () => _addLine(act: true),
          onRemove: (line) => setState(() => _acts = _acts.where((item) => item != line).toList()),
        ),
        _Lines(
          title: l10n.reportConsumablesTitle,
          addLabel: l10n.reportConsumableAdd,
          addKey: 'report-add-consumable',
          lines: _consumables,
          onAdd: () => _addLine(act: false),
          onRemove: (line) => setState(() => _consumables = _consumables.where((item) => item != line).toList()),
        ),
        NcSectionTitle(l10n.reportPhotosTitle),
        Text(
          l10n.reportPhotosCount(intervention.photosCount),
          key: const ValueKey<String>('report-photos-count'),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: NcSpacing.sm),
        NcSecondaryButton(
          key: const ValueKey<String>('report-add-photo'),
          label: l10n.reportPhotoAdd,
          icon: Icons.photo_camera_outlined,
          onPressed: _busy ? null : _addPhoto,
        ),
        const SizedBox(height: NcSpacing.lg),
        if (!_isRemote) ...<Widget>[
          NcSectionTitle(l10n.reportSignatureTitle),
          Row(
            children: <Widget>[
              Icon(
                intervention.isSigned ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                color: intervention.isSigned
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: NcSpacing.sm),
              Expanded(
                child: Text(
                  intervention.isSigned ? l10n.reportSignedBy(intervention.signedByName ?? '') : l10n.reportNotSigned,
                  key: const ValueKey<String>('report-signature-state'),
                  style: textTheme.bodyLarge,
                ),
              ),
            ],
          ),
          const SizedBox(height: NcSpacing.sm),
          NcSecondaryButton(
            key: const ValueKey<String>('report-sign'),
            label: intervention.isSigned ? l10n.reportSignAgain : l10n.reportSign,
            icon: Icons.draw_outlined,
            onPressed: _busy ? null : _sign,
          ),
        ],
        if (amount > 0) ...<Widget>[
          const SizedBox(height: NcSpacing.lg),
          NcSurface(
            color: _cashCollected ? Theme.of(context).colorScheme.primaryContainer : null,
            padding: const EdgeInsetsDirectional.fromSTEB(NcSpacing.md, NcSpacing.xs, NcSpacing.sm, NcSpacing.xs),
            child: SwitchListTile(
              key: const ValueKey<String>('report-cash'),
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.payments_outlined),
              title: Text(l10n.reportCashCollected(l10n.priceDirhams(formatDirhams(amount, language)))),
              value: _cashCollected,
              onChanged: _busy ? null : (value) => setState(() => _cashCollected = value),
            ),
          ),
        ],
      ],
    );
  }
}

/// Liste d'actes ou de consommables, avec ajout et retrait.
class _Lines extends StatelessWidget {
  const _Lines({
    required this.title,
    required this.addLabel,
    required this.addKey,
    required this.lines,
    required this.onAdd,
    required this.onRemove,
  });

  final String title;
  final String addLabel;
  final String addKey;
  final List<ReportLine> lines;
  final VoidCallback onAdd;
  final ValueChanged<ReportLine> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(bottom: NcSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          NcSectionTitle(title),
          for (final line in lines)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                line.quantity == 1 ? line.label : l10n.reportLineWithQuantity(line.label, formatMeasure(line.quantity)),
              ),
              trailing: IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(line),
              ),
            ),
          const SizedBox(height: NcSpacing.sm),
          NcSecondaryButton(key: ValueKey<String>(addKey), label: addLabel, icon: Icons.add, onPressed: onAdd),
        ],
      ),
    );
  }
}

/// Saisie libre d'un acte ou d'un consommable. Les référentiels arriveront avec leur
/// gestion au back-office.
class _LineDialog extends StatefulWidget {
  const _LineDialog({required this.act});

  final bool act;

  @override
  State<_LineDialog> createState() => _LineDialogState();
}

class _LineDialogState extends State<_LineDialog> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _quantity = TextEditingController(text: '1');
  String? _labelError;
  String? _quantityError;

  @override
  void dispose() {
    _label.dispose();
    _quantity.dispose();
    super.dispose();
  }

  void _confirm() {
    final l10n = context.l10n;
    final label = _label.text.trim();
    final quantity = num.tryParse(_quantity.text.trim().replaceAll(',', '.'));
    // Un acte se compte en entiers ; un consommable peut être fractionné.
    final validQuantity =
        quantity != null && quantity > 0 && quantity <= 100 && (!widget.act || quantity == quantity.roundToDouble());

    setState(() {
      _labelError = label.length < 2 ? l10n.fieldRequired : null;
      _quantityError = validQuantity ? null : l10n.fieldRequired;
    });
    if (_labelError != null || _quantityError != null) {
      return;
    }

    Navigator.of(context).pop(ReportLine(label: label, quantity: widget.act ? quantity!.round() : quantity!));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(widget.act ? l10n.reportActAdd : l10n.reportConsumableAdd),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const ValueKey<String>('line-label'),
            controller: _label,
            maxLength: 200,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.reportLineLabel, errorText: _labelError),
          ),
          TextField(
            key: const ValueKey<String>('line-quantity'),
            controller: _quantity,
            keyboardType: TextInputType.numberWithOptions(decimal: !widget.act),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(labelText: l10n.reportLineQuantity, errorText: _quantityError),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.cancel)),
        TextButton(onPressed: _confirm, child: Text(l10n.add)),
      ],
    );
  }
}
