import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'patient_texts.dart';
import 'patients_providers.dart';

/// Création ou modification d'un patient. [profileId] est `null` pour une création.
class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({this.profileId, super.key});

  final String? profileId;

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final TextEditingController _firstName = TextEditingController();
  final TextEditingController _lastName = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _careNotes = TextEditingController();

  PatientRelationship? _relationship;
  DateTime? _birthDate;
  String? _sex;

  bool _loading = false;
  bool _busy = false;
  Object? _loadError;
  String? _error;
  Map<String, String?> _fieldErrors = const <String, String?>{};

  bool get _isEdit => widget.profileId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _careNotes.dispose();
    super.dispose();
  }

  /// La fiche détaillée est la seule à contenir les notes de soin.
  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final profile = await ref.read(patientsApiProvider).getProfile(widget.profileId!);
      if (!mounted) {
        return;
      }
      _firstName.text = profile.firstName;
      _lastName.text = profile.lastName;
      _phone.text = profile.phone ?? '';
      _careNotes.text = profile.careNotes ?? '';
      setState(() {
        _relationship = profile.relationship;
        _birthDate = profile.birthDate;
        _sex = profile.sex;
        _loading = false;
      });
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _loadError = failure;
          _loading = false;
        });
      }
    }
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 40),
      firstDate: DateTime(1901),
      lastDate: now,
    );
    if (picked != null && mounted) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final errors = <String, String?>{
      if (_firstName.text.trim().isEmpty) 'first_name': l10n.fieldRequired,
      if (_lastName.text.trim().isEmpty) 'last_name': l10n.fieldRequired,
      if (_relationship == null) 'relationship': l10n.fieldRequired,
    };

    if (errors.isNotEmpty) {
      setState(() {
        _fieldErrors = errors;
        _error = null;
      });
      return;
    }

    final draft = PatientProfileDraft(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      relationship: _relationship!,
      birthDate: _birthDate,
      sex: _sex,
      phone: _phone.text.trim(),
      careNotes: _careNotes.text.trim(),
    );

    setState(() {
      _busy = true;
      _error = null;
      _fieldErrors = const <String, String?>{};
    });

    try {
      final controller = ref.read(profilesControllerProvider.notifier);
      if (_isEdit) {
        await controller.save(widget.profileId!, draft);
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
        title: Text(l10n.profileDeleteTitle),
        content: Text(l10n.profileDeleteBody),
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
      await ref.read(profilesControllerProvider.notifier).remove(widget.profileId!);
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
    final title = _isEdit ? l10n.profileEditTitle : l10n.profileNewTitle;

    if (_loading || _loadError != null) {
      return NcPage(
        appBar: AppBar(),
        title: title,
        actions: <Widget>[
          if (_loadError != null) NcPrimaryButton(label: l10n.retry, onPressed: _load),
        ],
        children: <Widget>[
          if (_loadError != null)
            NcNotice(message: failureMessage(context, _loadError!), kind: NcNoticeKind.error)
          else
            const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    final birthDate = _birthDate;

    return NcPage(
      appBar: AppBar(),
      title: title,
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
        NcSectionTitle(l10n.relationshipLabel),
        NcChoiceList<PatientRelationship>(
          keyPrefix: 'relationship',
          selected: _relationship,
          onSelected: (value) => setState(() => _relationship = value),
          choices: <NcChoice<PatientRelationship>>[
            for (final relationship in PatientRelationship.values)
              NcChoice<PatientRelationship>(value: relationship, label: relationshipLabel(l10n, relationship)),
          ],
        ),
        if (_fieldErrors['relationship'] != null)
          Text(
            _fieldErrors['relationship']!,
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: NcSpacing.md),
        TextField(
          key: const ValueKey<String>('first-name-field'),
          controller: _firstName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.firstNameLabel, errorText: _fieldErrors['first_name']),
        ),
        const SizedBox(height: NcSpacing.md),
        TextField(
          key: const ValueKey<String>('last-name-field'),
          controller: _lastName,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l10n.lastNameLabel, errorText: _fieldErrors['last_name']),
        ),
        const SizedBox(height: NcSpacing.lg),
        NcSectionTitle(l10n.birthDateLabel),
        NcSecondaryButton(
          key: const ValueKey<String>('birth-date-button'),
          icon: Icons.event_outlined,
          label: birthDate == null
              ? l10n.birthDateChoose
              : DateFormat.yMMMMd(Localizations.localeOf(context).toLanguageTag()).format(birthDate),
          onPressed: _pickBirthDate,
        ),
        if (_fieldErrors['birth_date'] != null)
          Text(
            _fieldErrors['birth_date']!,
            style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: NcSpacing.lg),
        NcSectionTitle(l10n.sexLabel),
        NcChoiceList<String>(
          keyPrefix: 'sex',
          selected: _sex,
          onSelected: (value) => setState(() => _sex = value),
          choices: <NcChoice<String>>[
            NcChoice<String>(value: 'female', label: l10n.sexFemale),
            NcChoice<String>(value: 'male', label: l10n.sexMale),
          ],
        ),
        const SizedBox(height: NcSpacing.md),
        // Le libellé avant le champ, comme partout ailleurs.
        NcSectionTitle(l10n.patientPhoneLabel),
        // Un numéro se saisit toujours de gauche à droite.
        Directionality(
          textDirection: TextDirection.ltr,
          child: TextField(
            key: const ValueKey<String>('patient-phone-field'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(errorText: _fieldErrors['phone'], hintText: l10n.phoneHint),
          ),
        ),
        const SizedBox(height: NcSpacing.lg),
        NcSectionTitle(l10n.careNotesLabel),
        TextField(
          key: const ValueKey<String>('care-notes-field'),
          controller: _careNotes,
          minLines: 3,
          maxLines: 6,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: l10n.careNotesHint, errorText: _fieldErrors['care_notes']),
        ),
        const SizedBox(height: NcSpacing.sm),
        NcNotice(message: l10n.careNotesPrivacy),
      ],
    );
  }
}
