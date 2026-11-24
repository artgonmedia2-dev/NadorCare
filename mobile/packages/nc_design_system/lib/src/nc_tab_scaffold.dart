import 'package:flutter/material.dart';

import 'nc_colors.dart';

/// Un onglet de la barre du bas.
class NcTab {
  const NcTab({required this.icon, required this.selectedIcon, required this.label, this.key});

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  /// Clé de la destination, pour les tests.
  final Key? key;
}

/// Écran à onglets : le contenu de l'onglet choisi, et une barre blanche arrondie en bas.
///
/// Seul l'onglet affiché est construit : il ne charge ses données que lorsqu'on l'ouvre.
class NcTabScaffold extends StatelessWidget {
  const NcTabScaffold({
    required this.tabs,
    required this.index,
    required this.onSelected,
    required this.body,
    super.key,
  });

  final List<NcTab> tabs;
  final int index;
  final ValueChanged<int> onSelected;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: body,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: NcColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: <BoxShadow>[BoxShadow(color: NcColors.shadow, blurRadius: 24, offset: Offset(0, -4))],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            height: 72,
            indicatorColor: NcColors.primarySoft,
            iconTheme: WidgetStateProperty.resolveWith(
              (states) => IconThemeData(
                color: states.contains(WidgetState.selected) ? NcColors.primaryStrong : NcColors.textMuted,
              ),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith(
              (states) => textTheme.labelMedium?.copyWith(
                fontSize: 13,
                fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
                color: states.contains(WidgetState.selected) ? NcColors.primaryStrong : NcColors.textMuted,
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: index,
            onDestinationSelected: onSelected,
            destinations: <Widget>[
              for (final tab in tabs)
                NavigationDestination(
                  key: tab.key,
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.selectedIcon),
                  label: tab.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
