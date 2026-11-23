import 'package:flutter/material.dart';

/// Action principale d'un écran : un seul par écran (§11, un choix par écran).
class NcPrimaryButton extends StatelessWidget {
  const NcPrimaryButton({required this.label, required this.onPressed, this.isLoading = false, this.icon, super.key});

  final String label;
  final VoidCallback? onPressed;

  /// Icône facultative, placée avant le libellé.
  final IconData? icon;

  /// Pendant un envoi : le bouton est désactivé et montre une progression.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 3))
          : _ButtonLabel(label: label, icon: icon),
    );
  }
}

/// Libellé d'un bouton, précédé de son icône s'il en a une.
class _ButtonLabel extends StatelessWidget {
  const _ButtonLabel({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);

    if (icon == null) {
      return text;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 22),
        const SizedBox(width: 10),
        // Aligné au début : un libellé sur deux lignes reste accolé à son icône.
        Flexible(child: Text(label, textAlign: TextAlign.start)),
      ],
    );
  }
}

/// Action secondaire.
class NcSecondaryButton extends StatelessWidget {
  const NcSecondaryButton({required this.label, required this.onPressed, this.icon, super.key});

  final String label;
  final VoidCallback? onPressed;

  /// Icône facultative, placée avant le libellé.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: _ButtonLabel(label: label, icon: icon),
    );
  }
}
