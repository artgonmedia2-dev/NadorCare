import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'bookings/bookings_providers.dart';
import 'bookings/bookings_screen.dart';
import 'catalogue/catalogue_providers.dart';
import 'catalogue/catalogue_screen.dart';
import 'catalogue/service_card.dart';
import 'patients/patient_texts.dart';

/// Accueil de l'application patient, à onglets (refonte du 2026-11-24) : l'accueil, les soins,
/// les rendez-vous et le compte. Seul l'onglet affiché est construit.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _tab = 0;

  void _open(int tab) => setState(() => _tab = tab);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return NcTabScaffold(
      index: _tab,
      onSelected: _open,
      tabs: <NcTab>[
        NcTab(
          key: const ValueKey<String>('tab-home'),
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: l10n.navHome,
        ),
        NcTab(
          key: const ValueKey<String>('tab-care'),
          icon: Icons.medical_services_outlined,
          selectedIcon: Icons.medical_services,
          label: l10n.navCare,
        ),
        NcTab(
          key: const ValueKey<String>('tab-bookings'),
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note,
          label: l10n.navBookings,
        ),
        NcTab(
          key: const ValueKey<String>('tab-account'),
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.navAccount,
        ),
      ],
      body: switch (_tab) {
        1 => const CatalogueScreen(),
        2 => const BookingsScreen(embedded: true),
        3 => const _AccountTab(),
        _ => _HomeTab(onOpenTab: _open),
      },
    );
  }
}

const int _tabCare = 1;
const int _tabBookings = 2;

/// Onglet d'accueil : salutation, réserver un soin, les prochains soins, l'accès rapide,
/// les catégories de soins et le rappel des urgences.
class _HomeTab extends ConsumerWidget {
  const _HomeTab({required this.onOpenTab});

  final ValueChanged<int> onOpenTab;

  /// Nombre de soins à venir montrés sur l'accueil ; les autres sont dans l'onglet Rendez-vous.
  static const int _upcomingShown = 3;

  /// Nombre de catégories montrées ; « Tout voir » ouvre l'onglet Soins.
  static const int _categoriesShown = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.name : null;
    final greeting = (name == null || name.isEmpty) ? l10n.homeGreetingAnonymous : l10n.homeGreeting(name);

    return NcPage(
      title: greeting,
      header: NcHomeHeader(
        greeting: greeting,
        caption: l10n.homePatientIntro,
        trailing: <Widget>[
          NcRoundIconButton(
            icon: Icons.settings_outlined,
            tooltip: l10n.settingsOpen,
            onPressed: () => context.push(NcRoutes.settings),
          ),
        ],
      ),
      onRefresh: () async {
        ref
          ..invalidate(bookingsListProvider(false))
          ..invalidate(homeCategoriesProvider);
      },
      children: <Widget>[
        // Réserver un soin est la raison d'être de l'application : le bandeau, en tête.
        NcHeroCard(
          eyebrow: l10n.homeHeroEyebrow,
          title: l10n.homeHeroTitle,
          body: l10n.homeHeroBody,
          points: <String>[l10n.homeProofTeam, l10n.homeProofPrice, l10n.homeProofCash],
          action: NcPrimaryButton(
            key: const ValueKey<String>('home-catalogue'),
            label: l10n.homeHeroAction,
            icon: Icons.add_circle_outline,
            onPressed: () => context.push(routeCatalogue),
          ),
        ),
        ..._upcoming(context, ref),
        NcSectionTitle(l10n.homeQuickActions),
        NcTileGrid(
          columns: 3,
          children: <Widget>[
            NcActionTile(
              key: const ValueKey<String>('home-bookings'),
              icon: Icons.event_note_outlined,
              label: l10n.navBookings,
              onTap: () => context.push(routeBookings),
            ),
            NcActionTile(
              key: const ValueKey<String>('home-profiles'),
              icon: Icons.people_outline,
              label: l10n.homeProfiles,
              onTap: () => context.push(routeProfiles),
            ),
            NcActionTile(
              key: const ValueKey<String>('home-addresses'),
              icon: Icons.home_outlined,
              label: l10n.homeAddresses,
              onTap: () => context.push(routeAddresses),
            ),
          ],
        ),
        ..._categories(context, ref),
        NcNotice(message: l10n.emergencyNotice, kind: NcNoticeKind.warning),
      ],
    );
  }

  /// Les prochains soins. Rien tant que la liste n'est pas chargée, ni si elle échoue :
  /// l'onglet Rendez-vous dit ce qu'il en est.
  List<Widget> _upcoming(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final bookings = ref.watch(bookingsListProvider(false)).value;

    if (bookings == null) {
      return const <Widget>[];
    }

    return <Widget>[
      NcSectionTitle(
        l10n.homeUpcomingTitle,
        actionLabel: bookings.isEmpty ? null : l10n.seeAll,
        actionKey: const ValueKey<String>('home-upcoming-all'),
        onAction: bookings.isEmpty ? null : () => onOpenTab(_tabBookings),
      ),
      if (bookings.isEmpty)
        NcEmptyState(message: l10n.homeUpcomingEmpty, icon: Icons.event_available_outlined)
      else
        for (final booking in bookings.take(_upcomingShown))
          _UpcomingRow(booking: booking, language: language),
      const SizedBox(height: NcSpacing.md),
    ];
  }

  /// Les catégories de soins, en grille.
  List<Widget> _categories(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(homeCategoriesProvider).value;

    if (categories == null || categories.isEmpty) {
      return const <Widget>[];
    }

    return <Widget>[
      const SizedBox(height: NcSpacing.sm),
      NcSectionTitle(
        l10n.homeCatalogue,
        actionLabel: l10n.seeAll,
        actionKey: const ValueKey<String>('home-care-all'),
        onAction: () => onOpenTab(_tabCare),
      ),
      NcTileGrid(
        children: <Widget>[
          for (final category in categories.take(_categoriesShown))
            NcActionTile(
              key: ValueKey<String>('home-category-${category.slug}'),
              icon: categoryIcon(category.slug),
              label: category.name,
              caption: l10n.servicesCount(category.servicesCount),
              onTap: () => context.push(routeCategory(category.slug)),
            ),
        ],
      ),
      const SizedBox(height: NcSpacing.sm),
    ];
  }
}

/// Un soin à venir : son nom, son état et sa date, en une ligne compacte.
class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({required this.booking, required this.language});

  final Booking booking;
  final String language;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = bookingStatusBadge(l10n, booking.status);
    final day = DateFormat.MMMEd(language).format(booking.scheduledDate);

    return NcFeedRow(
      key: ValueKey<String>('home-upcoming-${booking.id}'),
      icon: status.icon,
      tone: status.tone,
      title: booking.serviceName,
      subtitle: '${bookingStatusLabel(l10n, booking.status)} · ${l10n.dateAtTime(day, booking.scheduledTime)}',
      onTap: () => context.push(routeBooking(booking.id)),
    );
  }
}

/// Onglet du compte : les patients, les adresses, les réglages.
class _AccountTab extends ConsumerWidget {
  const _AccountTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.name : null;

    return NcPage(
      title: l10n.accountTitle,
      header: NcHomeHeader(
        greeting: l10n.accountTitle,
        caption: name,
        trailing: <Widget>[NcAvatar(name: name)],
      ),
      children: <Widget>[
        NcListCard(
          key: const ValueKey<String>('account-profiles'),
          icon: Icons.people_outline,
          title: l10n.homeProfiles,
          subtitle: l10n.homeProfilesSubtitle,
          onTap: () => context.push(routeProfiles),
        ),
        NcListCard(
          key: const ValueKey<String>('account-addresses'),
          icon: Icons.home_outlined,
          title: l10n.homeAddresses,
          subtitle: l10n.homeAddressesSubtitle,
          onTap: () => context.push(routeAddresses),
        ),
        NcListCard(
          key: const ValueKey<String>('account-settings'),
          icon: Icons.settings_outlined,
          title: l10n.settingsTitle,
          onTap: () => context.push(NcRoutes.settings),
        ),
        const SizedBox(height: NcSpacing.md),
        NcNotice(message: l10n.emergencyNotice, kind: NcNoticeKind.warning),
      ],
    );
  }
}
