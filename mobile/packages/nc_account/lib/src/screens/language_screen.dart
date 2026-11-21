import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../settings/settings_controller.dart';
import 'language_choice.dart';

/// Premier écran au premier lancement : choix de la langue.
/// L'écran se traduit dès qu'une langue est touchée, avant même de continuer.
class LanguageScreen extends ConsumerStatefulWidget {
  const LanguageScreen({required this.onPreview, super.key});

  /// Appelé quand l'utilisateur touche une langue, pour traduire l'écran tout de suite.
  final ValueChanged<String> onPreview;

  @override
  ConsumerState<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends ConsumerState<LanguageScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selected = _selected ??
        (supportedLanguageCodes.contains(Localizations.localeOf(context).languageCode)
            ? Localizations.localeOf(context).languageCode
            : defaultLanguageCode);

    return NcPage(
      title: l10n.languageTitle,
      subtitle: l10n.languageSubtitle,
      actions: <Widget>[
        NcPrimaryButton(
          label: l10n.continueButton,
          onPressed: () => ref.read(settingsControllerProvider.notifier).setLanguage(selected),
        ),
      ],
      children: <Widget>[
        LanguageChoice(
          selected: selected,
          onSelected: (code) {
            setState(() => _selected = code);
            widget.onPreview(code);
          },
        ),
      ],
    );
  }
}
