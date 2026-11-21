import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../auth/auth_controller.dart';

/// Écran de verrouillage : l'empreinte ou le visage est demandé dès l'ouverture.
class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_busy || !mounted) {
      return;
    }
    setState(() => _busy = true);
    final reason = context.l10n.biometricReason;
    await ref.read(authControllerProvider.notifier).unlock(reason);
    if (mounted) {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NcPage(
      title: l10n.unlockTitle,
      subtitle: l10n.unlockSubtitle,
      actions: <Widget>[
        NcPrimaryButton(label: l10n.unlockButton, isLoading: _busy, onPressed: _unlock),
        TextButton(
          onPressed: _busy ? null : () => ref.read(authControllerProvider.notifier).logout(),
          child: Text(l10n.logout),
        ),
      ],
      children: <Widget>[
        Icon(Icons.lock_outline, size: 96, color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}
