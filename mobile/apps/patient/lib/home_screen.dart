import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'bookings/bookings_providers.dart';
import 'catalogue/catalogue_providers.dart';
import 'patients/patient_texts.dart';

/// Accueil de l'application patient. Le catalogue et la réservation (tâches 4.3 et 4.4)
/// viendront ici ; pour l'instant l'écran confirme la connexion et rappelle les urgences.
class PatientHomeScreen extends ConsumerWidget {
  const PatientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.name : null;

    return NcPage(
      appBar: AppBar(
        title: Text(l10n.appNamePatient),
        actions: <Widget>[
          IconButton(
            tooltip: l10n.settingsOpen,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(NcRoutes.settings),
          ),
        ],
      ),
      title: (name == null || name.isEmpty) ? l10n.homeGreetingAnonymous : l10n.homeGreeting(name),
      subtitle: l10n.homePatientIntro,
      children: <Widget>[
        NcListCard(
          key: const ValueKey<String>('home-catalogue'),
          icon: Icons.medical_services_outlined,
          // Réserver un soin est la raison d'être de l'application : cette carte se détache des autres.
          highlighted: true,
          title: l10n.homeCatalogue,
          subtitle: l10n.homeCatalogueSubtitle,
          onTap: () => context.push(routeCatalogue),
        ),
        NcListCard(
          key: const ValueKey<String>('home-bookings'),
          icon: Icons.event_note_outlined,
          title: l10n.homeBookings,
          subtitle: l10n.homeBookingsSubtitle,
          onTap: () => context.push(routeBookings),
        ),
        NcListCard(
          key: const ValueKey<String>('home-profiles'),
          icon: Icons.people_outline,
          title: l10n.homeProfiles,
          subtitle: l10n.homeProfilesSubtitle,
          onTap: () => context.push(routeProfiles),
        ),
        NcListCard(
          key: const ValueKey<String>('home-addresses'),
          icon: Icons.home_outlined,
          title: l10n.homeAddresses,
          subtitle: l10n.homeAddressesSubtitle,
          onTap: () => context.push(routeAddresses),
        ),
        const SizedBox(height: NcSpacing.md),
        NcNotice(message: l10n.emergencyNotice, kind: NcNoticeKind.warning),
      ],
    );
  }
}
