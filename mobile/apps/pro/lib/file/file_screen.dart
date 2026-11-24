import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Dossier du professionnel : un bloc par justificatif exigé, avec son état, puis l'envoi.
class FileScreen extends ConsumerStatefulWidget {
  const FileScreen({this.embedded = false, super.key});

  /// Affiché dans un onglet de l'accueil : pas de bouton de retour.
  final bool embedded;

  @override
  ConsumerState<FileScreen> createState() => _FileScreenState();
}

class _FileScreenState extends ConsumerState<FileScreen> {
  static const String _insurance = 'rc_insurance';

  /// Type du justificatif en cours d'envoi.
  String? _uploading;
  bool _submitting = false;
  String? _error;
  DateTime? _insuranceExpiry;

  /// Le renouvellement de l'assurance reste replié tant qu'on ne le demande pas.
  bool _renewingInsurance = false;

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _insuranceExpiry ?? now.add(const Duration(days: 365)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null && mounted) {
      setState(() {
        _insuranceExpiry = picked;
        _error = null;
      });
    }
  }

  Future<void> _upload(String type, {required bool fromCamera}) async {
    final expiry = _insuranceExpiry;

    if (type == _insurance && expiry == null) {
      setState(() => _error = context.l10n.docExpiryRequired);
      return;
    }

    setState(() {
      _uploading = type;
      _error = null;
    });

    try {
      final picked = await ref.read(documentPickerProvider).pick(fromCamera: fromCamera);
      if (picked == null) {
        return;
      }
      await ref.read(professionalFileProvider.notifier).uploadDocument(
            type: type,
            document: picked,
            expiresAt: type == _insurance ? apiDate(expiry!) : null,
          );
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failure.firstErrorFor('file') ?? failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = null);
      }
    }
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ref.read(professionalFileProvider.notifier).submit();
      if (mounted) {
        context.go(NcRoutes.home);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final file = ref.watch(professionalFileProvider).value;

    if (file == null) {
      return NcPage(
        appBar: widget.embedded ? null : AppBar(),
        title: l10n.proFileTitle,
        children: const <Widget>[Center(child: CircularProgressIndicator())],
      );
    }

    final editable = file.status.isEditable;

    return NcPage(
      appBar: widget.embedded ? null : AppBar(leading: BackButton(onPressed: () => context.go(NcRoutes.home))),
      title: l10n.proFileTitle,
      header: NcDetailHeader(
        icon: Icons.folder_outlined,
        title: l10n.proFileTitle,
        subtitle: file.categoryName,
        // Avancement : les justificatifs exigés déjà validés.
        badge: NcStepIndicator(
          key: const ValueKey<String>('file-progress'),
          label: l10n.docProgress(
            file.requiredDocuments.where((type) => file.documentOf(type)?.status == 'approved').length,
            file.requiredDocuments.length,
          ),
          current: file.requiredDocuments.where((type) => file.documentOf(type)?.status == 'approved').length,
          total: file.requiredDocuments.length,
        ),
      ),
      actions: <Widget>[
        if (editable)
          NcPrimaryButton(
            label: l10n.proSubmit,
            icon: Icons.send_outlined,
            isLoading: _submitting,
            onPressed: file.canSubmit && _uploading == null ? _submit : null,
          ),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        if (file.status == VerificationStatus.rejected && (file.statusReason ?? '').isNotEmpty) ...<Widget>[
          NcNotice(message: l10n.proReason(file.statusReason!), kind: NcNoticeKind.warning),
          const SizedBox(height: NcSpacing.md),
        ],
        if (editable && !file.canSubmit) ...<Widget>[
          NcNotice(message: l10n.proSubmitIncomplete),
          const SizedBox(height: NcSpacing.md),
        ],
        NcSectionTitle(l10n.proDocumentsTitle),
        // Les justificatifs exigés d'abord, puis les facultatifs (l'assurance personnelle).
        for (final type in <String>[...file.requiredDocuments, ...file.optionalDocuments])
          _DocumentBlock(
            type: type,
            document: file.documentOf(type),
            isOptional: file.optionalDocuments.contains(type),
            isMissing: file.missingDocuments.contains(type) ||
                (file.optionalDocuments.contains(type) && file.documentOf(type) == null),
            isUploading: _uploading == type,
            // Un renouvellement d'assurance reste possible une fois le dossier validé.
            canUpload: _uploading == null && (editable || type == _insurance),
            insuranceExpiry: type == _insurance ? _insuranceExpiry : null,
            onPickExpiry: type == _insurance ? _pickExpiry : null,
            isRenewing: _renewingInsurance,
            onRenew: () => setState(() => _renewingInsurance = true),
            onUpload: (fromCamera) => _upload(type, fromCamera: fromCamera),
          ),
      ],
    );
  }
}

class _DocumentBlock extends StatelessWidget {
  const _DocumentBlock({
    required this.type,
    required this.document,
    required this.isMissing,
    required this.isUploading,
    required this.canUpload,
    required this.onUpload,
    required this.isRenewing,
    required this.onRenew,
    this.isOptional = false,
    this.insuranceExpiry,
    this.onPickExpiry,
  });

  final String type;
  final ProfessionalDocument? document;
  final bool isMissing;

  /// Justificatif facultatif : il peut être déposé, mais le dossier est complet sans lui.
  final bool isOptional;
  final bool isUploading;
  final bool canUpload;
  final void Function(bool fromCamera) onUpload;
  final DateTime? insuranceExpiry;
  final VoidCallback? onPickExpiry;

  /// Vrai quand le professionnel a demandé à remplacer un justificatif encore valable.
  final bool isRenewing;
  final VoidCallback onRenew;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final current = document;
    final status = current?.status;

    final (String label, NcBadgeTone tone, IconData icon) = switch (status) {
      'approved' => (l10n.docStatusApproved, NcBadgeTone.success, Icons.check_circle_outline),
      'pending' => (l10n.docStatusPending, NcBadgeTone.progress, Icons.hourglass_empty),
      'rejected' => (
          l10n.docStatusRejected(current?.rejectionReason ?? ''),
          NcBadgeTone.danger,
          Icons.error_outline,
        ),
      'expired' => (l10n.docStatusExpired, NcBadgeTone.danger, Icons.event_busy_outlined),
      _ => (isOptional ? l10n.docOptional : l10n.docStatusMissing, NcBadgeTone.neutral, Icons.upload_file_outlined),
    };

    final expiresAt = current?.expiresAt;
    // Le dépôt est nécessaire quand le justificatif manque, a été refusé ou a expiré.
    final needsUpload = isMissing || status == 'rejected' || status == 'expired';
    // L'assurance se renouvelle aussi quand elle est encore valable, mais seulement sur demande :
    // trois boutons en permanence sous un justificatif approuvé laissaient croire qu'il manquait quelque chose.
    final showUpload = canUpload && (needsUpload || (onPickExpiry != null && isRenewing));
    final showRenew = canUpload && !needsUpload && onPickExpiry != null && !isRenewing;

    return NcSurface(
      key: ValueKey<String>('document-$type'),
      margin: const EdgeInsets.only(bottom: NcSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              NcIconBubble(
                icon: documentTypeIcon(type),
                background: ncToneColors(tone).$1,
                foreground: ncToneColors(tone).$2,
              ),
              const SizedBox(width: NcSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(documentTypeLabel(l10n, type), style: textTheme.titleMedium),
                    const SizedBox(height: NcSpacing.xs + 2),
                    NcStatusBadge(label: label, icon: icon, tone: tone),
                    if (expiresAt != null && status != 'rejected') ...<Widget>[
                      const SizedBox(height: NcSpacing.xs + 2),
                      Text(
                        l10n.docValidUntil(longDate(expiresAt, language)),
                        style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isUploading) ...<Widget>[
            const SizedBox(height: NcSpacing.sm),
            const Center(child: CircularProgressIndicator()),
          ] else if (showRenew)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey<String>('insurance-renew'),
                onPressed: onRenew,
                icon: const Icon(Icons.autorenew),
                label: Text(l10n.docRenewInsurance),
              ),
            )
          else if (showUpload) ...<Widget>[
            if (onPickExpiry != null) ...<Widget>[
              const SizedBox(height: NcSpacing.md),
              NcSecondaryButton(
                key: const ValueKey<String>('insurance-expiry'),
                icon: Icons.event_outlined,
                label: insuranceExpiry == null ? l10n.docExpiryChoose : longDate(insuranceExpiry!, language),
                onPressed: onPickExpiry,
              ),
            ],
            const SizedBox(height: NcSpacing.md),
            // Photo ou galerie : deux tuiles côte à côte, plutôt que deux longs boutons.
            NcTileGrid(
              children: <Widget>[
                NcActionTile(
                  key: ValueKey<String>('camera-$type'),
                  icon: Icons.photo_camera_outlined,
                  label: l10n.docTakePhoto,
                  flat: true,
                  onTap: () => onUpload(true),
                ),
                NcActionTile(
                  key: ValueKey<String>('gallery-$type'),
                  icon: Icons.photo_library_outlined,
                  label: l10n.docChoosePhoto,
                  flat: true,
                  onTap: () => onUpload(false),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
