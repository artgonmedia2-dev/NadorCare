import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'async_list_page.dart';
import 'patient_texts.dart';
import 'patients_providers.dart';

/// Liste des patients gérés par le compte.
class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return AsyncListPage<PatientProfile>(
      title: l10n.homeProfiles,
      items: ref.watch(profilesControllerProvider),
      emptyMessage: l10n.profilesEmpty,
      addLabel: l10n.profileAdd,
      onAdd: () => context.push(routeProfileNew),
      onRetry: () => ref.read(profilesControllerProvider.notifier).reload(),
      itemBuilder: (profile) => NcListCard(
        key: ValueKey<String>('profile-${profile.id}'),
        icon: Icons.person_outline,
        title: profile.fullName,
        subtitle: relationshipLabel(l10n, profile.relationship),
        onTap: () => context.push(routeProfile(profile.id)),
      ),
    );
  }
}
