import 'package:flutter/material.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Empêche de quitter un écran en perdant des modifications sans le savoir.
///
/// Tant que [dirty] est vrai, le retour (bouton, geste ou touche du téléphone) ouvre une
/// confirmation. Rester est l'action par défaut : on ne perd rien par un geste involontaire.
class UnsavedChangesGuard extends StatelessWidget {
  const UnsavedChangesGuard({required this.dirty, required this.child, super.key});

  /// Vrai dès que l'écran contient des modifications non enregistrées.
  final bool dirty;
  final Widget child;

  static Future<bool> _confirm(BuildContext context) async {
    final l10n = context.l10n;

    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedTitle),
        content: Text(l10n.unsavedBody),
        actions: <Widget>[
          TextButton(
            key: const ValueKey<String>('unsaved-leave'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.unsavedLeave),
          ),
          FilledButton(
            key: const ValueKey<String>('unsaved-stay'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.unsavedStay),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final navigator = Navigator.of(context);
        if (await _confirm(context) && navigator.mounted) {
          navigator.pop();
        }
      },
      child: child,
    );
  }
}
