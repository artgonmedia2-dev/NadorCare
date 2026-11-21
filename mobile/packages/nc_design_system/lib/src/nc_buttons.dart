import 'package:flutter/material.dart';

/// Action principale d'un écran : un seul par écran (§11, un choix par écran).
class NcPrimaryButton extends StatelessWidget {
  const NcPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  /// Pendant un envoi : le bouton est désactivé et montre une progression.
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            )
          : Text(label, textAlign: TextAlign.center),
    );
  }
}

/// Action secondaire.
class NcSecondaryButton extends StatelessWidget {
  const NcSecondaryButton({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: Text(label, textAlign: TextAlign.center),
    );
  }
}
