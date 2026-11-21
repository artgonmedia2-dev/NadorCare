import 'package:flutter/material.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Nom de chaque langue écrit dans sa propre langue : lisible quelle que soit la langue affichée.
String languageNativeName(String languageCode) {
  return lookupNcLocalizations(Locale(languageCode)).languageName;
}

/// Liste des langues, une grande ligne par langue.
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({required this.selected, required this.onSelected, super.key});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        for (final code in supportedLanguageCodes)
          Padding(
            padding: const EdgeInsets.only(bottom: NcSpacing.sm),
            child: Semantics(
              selected: code == selected,
              button: true,
              child: Material(
                color: code == selected ? scheme.primaryContainer : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  key: ValueKey<String>('language-$code'),
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(code),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: NcSpacing.touchTarget + 8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: NcSpacing.md),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              languageNativeName(code),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          Icon(
                            code == selected ? Icons.check_circle : Icons.circle_outlined,
                            color: code == selected ? scheme.primary : scheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
