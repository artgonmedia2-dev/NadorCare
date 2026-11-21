import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../failure_message.dart';
import '../providers.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';
import 'language_choice.dart';

/// Réglages du compte : nom, langue, taille du texte, verrouillage biométrique, déconnexion.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _savingName = false;
  String? _nameError;
  String? _error;
  String? _info;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is AuthSignedIn) {
      _nameController.text = auth.user.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _nameError = context.l10n.nameTooShort);
      return;
    }

    setState(() {
      _savingName = true;
      _nameError = null;
      _error = null;
      _info = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(name: name);
      if (mounted) {
        setState(() => _info = context.l10n.profileSaved);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() {
          _nameError = failure.firstErrorFor('name');
          _error = _nameError == null ? failureMessage(context, failure) : null;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<void> _changeLanguage(String code) async {
    await ref.read(settingsControllerProvider.notifier).setLanguage(code);
    try {
      // La langue du compte sert aux SMS et aux notifications envoyés par le serveur.
      await ref.read(authControllerProvider.notifier).updateProfile(locale: code);
    } on ApiFailure {
      // Hors ligne : la langue de l'appareil est déjà changée, celle du compte suivra.
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    final l10n = context.l10n;
    final biometric = ref.read(biometricServiceProvider);
    setState(() {
      _error = null;
      _info = null;
    });

    if (enable) {
      if (!await biometric.isAvailable()) {
        if (mounted) {
          setState(() => _error = l10n.biometricUnavailable);
        }
        return;
      }
      // On vérifie que le capteur reconnaît bien la personne avant de verrouiller l'application.
      if (!await biometric.authenticate(l10n.biometricReason)) {
        return;
      }
    }

    await ref.read(settingsControllerProvider.notifier).setBiometricEnabled(enable);
  }

  Future<void> _confirmLogout() async {
    final l10n = context.l10n;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.logout)),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  String _textSizeLabel(NcLocalizations l10n, NcTextSize size) {
    return switch (size) {
      NcTextSize.normal => l10n.textSizeNormal,
      NcTextSize.large => l10n.textSizeLarge,
      NcTextSize.extraLarge => l10n.textSizeExtraLarge,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings = ref.watch(settingsControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return NcPage(
      appBar: AppBar(),
      title: l10n.settingsTitle,
      children: <Widget>[
        if (_info != null) ...<Widget>[NcNotice(message: _info!), const SizedBox(height: NcSpacing.md)],
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        Text(l10n.nameLabel, style: textTheme.titleMedium),
        const SizedBox(height: NcSpacing.sm),
        TextField(
          key: const ValueKey<String>('name-field'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          autofillHints: const <String>[AutofillHints.name],
          decoration: InputDecoration(hintText: l10n.nameHint, errorText: _nameError),
        ),
        const SizedBox(height: NcSpacing.sm),
        NcPrimaryButton(label: l10n.save, isLoading: _savingName, onPressed: _saveName),
        const SizedBox(height: NcSpacing.xl),
        Text(l10n.languageLabel, style: textTheme.titleMedium),
        const SizedBox(height: NcSpacing.sm),
        LanguageChoice(selected: settings.languageCode, onSelected: _changeLanguage),
        const SizedBox(height: NcSpacing.lg),
        Text(l10n.textSizeLabel, style: textTheme.titleMedium),
        const SizedBox(height: NcSpacing.sm),
        for (final size in NcTextSize.values)
          ListTile(
            key: ValueKey<String>('text-size-${size.name}'),
            contentPadding: EdgeInsets.zero,
            selected: size == settings.textSize,
            title: Text(_textSizeLabel(l10n, size)),
            trailing: Icon(size == settings.textSize ? Icons.check_circle : Icons.circle_outlined),
            onTap: () => ref.read(settingsControllerProvider.notifier).setTextSize(size),
          ),
        const SizedBox(height: NcSpacing.lg),
        SwitchListTile(
          key: const ValueKey<String>('biometric-switch'),
          contentPadding: EdgeInsets.zero,
          value: settings.biometricEnabled,
          onChanged: _toggleBiometric,
          title: Text(l10n.biometricLabel, style: textTheme.titleMedium),
          subtitle: Text(l10n.biometricSubtitle),
        ),
        const SizedBox(height: NcSpacing.xl),
        NcSecondaryButton(label: l10n.logout, onPressed: _confirmLogout),
      ],
    );
  }
}
