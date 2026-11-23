import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'patients_providers.dart';

/// Création ou modification d'une adresse. [addressId] est `null` pour une création.
///
/// La position vient du GPS du téléphone. Le choix d'un point sur une carte, nécessaire
/// pour enregistrer une adresse à distance, viendra avec la cartographie (tâche 4.4).
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({this.addressId, super.key});

  final String? addressId;

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final TextEditingController _label = TextEditingController();
  final TextEditingController _line = TextEditingController();
  final TextEditingController _accessNotes = TextEditingController();

  GeoPoint? _position;
  bool _locating = false;
  bool _busy = false;
  String? _error;
  String? _locationError;
  Map<String, String?> _fieldErrors = const <String, String?>{};

  bool get _isEdit => widget.addressId != null;

  @override
  void initState() {
    super.initState();

    final id = widget.addressId;
    if (id == null) {
      return;
    }

    final addresses = ref.read(addressesControllerProvider).value ?? const <PatientAddress>[];
    for (final address in addresses) {
      if (address.id == id) {
        _label.text = address.label;
        _line.text = address.line;
        _accessNotes.text = address.accessNotes ?? '';
        _position = (latitude: address.latitude, longitude: address.longitude);
      }
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _line.dispose();
    _accessNotes.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    final l10n = context.l10n;
    setState(() {
      _locating = true;
      _locationError = null;
    });

    try {
      final position = await ref.read(locationServiceProvider).currentPosition();
      if (mounted) {
        setState(() => _position = position);
      }
    } on LocationFailure catch (failure) {
      if (mounted) {
        setState(() {
          _locationError = switch (failure.reason) {
            LocationFailureReason.denied => l10n.locationDenied,
            LocationFailureReason.disabled => l10n.locationDisabled,
            LocationFailureReason.unavailable => l10n.locationUnavailable,
          };
        });
      }
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final position = _position;

    final errors = <String, String?>{
      if (_label.text.trim().isEmpty) 'label': l10n.fieldRequired,
      if (_line.text.trim().length < 3) 'line': l10n.fieldRequired,
    };

    if (errors.isNotEmpty || position == null) {
      setState(() {
        _fieldErrors = errors;
        _locationError = position == null ? l10n.locationMissing : null;
        _error = null;
      });
      return;
    }

    final draft = PatientAddressDraft(
      label: _label.text.trim(),
      line: _line.text.trim(),
      latitude: position.latitude,
      longitude: position.longitude,
      accessNotes: _accessNotes.text.trim(),
    );

    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const <String, String?>{};
    });

    try {
      final controller = ref.read(addressesControllerProvider.notifier);
      if (_isEdit) {
        await controller.save(widget.addressId!, draft);
      } else {
        await controller.create(draft);
      }
      if (mounted) {
        context.pop();
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _fieldErrors = <String, String?>{
            for (final field in failure.fieldErrors.keys) field: failure.firstErrorFor(field),
          };
          _error = failure.fieldErrors.isEmpty ? failureMessage(context, failure) : null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _delete() async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.addressDeleteTitle),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.delete)),
        ],
      ),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await ref.read(addressesControllerProvider.notifier).remove(widget.addressId!);
      if (mounted) {
        context.pop();
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    return NcPage(
      appBar: AppBar(),
      title: _isEdit ? l10n.addressEditTitle : l10n.addressNewTitle,
      actions: <Widget>[
        NcPrimaryButton(label: l10n.save, isLoading: _busy, onPressed: _save),
        if (_isEdit)
          TextButton.icon(
            onPressed: _busy ? null : _delete,
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: Text(l10n.delete),
          ),
      ],
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        TextField(
          key: const ValueKey<String>('address-label-field'),
          controller: _label,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: l10n.addressLabelLabel,
            hintText: l10n.addressLabelHint,
            errorText: _fieldErrors['label'],
          ),
        ),
        const SizedBox(height: NcSpacing.md),
        TextField(
          key: const ValueKey<String>('address-line-field'),
          controller: _line,
          minLines: 1,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.addressLineLabel,
            hintText: l10n.addressLineHint,
            errorText: _fieldErrors['line'],
          ),
        ),
        const SizedBox(height: NcSpacing.md),
        TextField(
          key: const ValueKey<String>('access-notes-field'),
          controller: _accessNotes,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: l10n.accessNotesLabel,
            hintText: l10n.accessNotesHint,
            errorText: _fieldErrors['access_notes'],
          ),
        ),
        const SizedBox(height: NcSpacing.md),
        const SizedBox(height: NcSpacing.sm),
        NcSectionTitle(l10n.locationLabel),
        Text(l10n.locationHelp, style: textTheme.bodyMedium),
        const SizedBox(height: NcSpacing.sm),
        if (_position != null) ...<Widget>[
          NcNotice(key: const ValueKey<String>('location-set'), message: l10n.locationSet),
          const SizedBox(height: NcSpacing.sm),
        ],
        if (_locationError != null) ...<Widget>[
          NcNotice(message: _locationError!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.sm),
        ],
        if (_locating)
          const Center(child: CircularProgressIndicator())
        else
          NcSecondaryButton(label: l10n.locationUse, icon: Icons.my_location, onPressed: _locate),
      ],
    );
  }
}
