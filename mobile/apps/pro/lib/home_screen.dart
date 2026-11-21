import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

/// Accueil de l'application professionnel. L'inscription, les disponibilités et les
/// missions (lot 5) viendront ici.
class ProHomeScreen extends ConsumerWidget {
  const ProHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.name : null;

    return NcPage(
      appBar: AppBar(
        title: Text(l10n.appNamePro),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.settingsOpen,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(NcRoutes.settings),
          ),
        ],
      ),
      title: (name == null || name.isEmpty) ? l10n.homeGreetingAnonymous : l10n.homeGreeting(name),
      subtitle: l10n.homeProSoon,
      children: const <Widget>[],
    );
  }
}
