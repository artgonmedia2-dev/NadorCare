import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'file/file_screen.dart';
import 'missions/journey_tracker.dart';
import 'pro_providers.dart';
import 'schedule/planning_screen.dart';

/// Accueil de l'application professionnel. Ce qu'il montre dépend de l'état du dossier :
/// justificatifs à déposer, vérification en cours, puis (soignant vérifié) un écran à onglets :
/// missions, planning, dossier et compte (refonte du 2026-11-24).
class ProHomeScreen extends ConsumerStatefulWidget {
  const ProHomeScreen({super.key});

  @override
  ConsumerState<ProHomeScreen> createState() => _ProHomeScreenState();
}

class _ProHomeScreenState extends ConsumerState<ProHomeScreen> {
  /// Les notifications ne sont pas encore branchées : l'écran se rafraîchit de lui-même,
  /// pour qu'une mission affectée par la coordination apparaisse sans attendre.
  static const Duration _refreshEvery = Duration(seconds: 15);

  Timer? _timer;

  /// Onglet affiché, une fois le soignant vérifié.
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh() {
    if (!mounted) {
      return;
    }
    ref.read(professionalFileProvider.notifier).refreshQuietly();
    ref.invalidate(missionsProvider);
  }

  /// Rechargement demandé par un geste : on attend la réponse avant de retirer l'indicateur.
  Future<void> _pullToRefresh() async {
    await ref.read(professionalFileProvider.notifier).refreshQuietly();
    if (!mounted) {
      return;
    }
    ref.invalidate(missionsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final auth = ref.watch(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.name : null;
    final file = ref.watch(professionalFileProvider);

    final appBar = AppBar(
      title: Text(l10n.appNamePro),
      actions: <Widget>[
        IconButton(tooltip: l10n.refresh, icon: const Icon(Icons.refresh), onPressed: _refresh),
        IconButton(
          tooltip: l10n.settingsOpen,
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push(NcRoutes.settings),
        ),
      ],
    );
    final greeting = (name == null || name.isEmpty) ? l10n.homeGreetingAnonymous : l10n.homeGreeting(name);

    if (file.hasError && !file.hasValue) {
      return NcPage(
        appBar: appBar,
        title: greeting,
        actions: <Widget>[
          NcPrimaryButton(
            label: l10n.retry,
            onPressed: () => ref.read(professionalFileProvider.notifier).reload(),
          ),
        ],
        children: <Widget>[NcNotice(message: failureMessage(context, file.error!), kind: NcNoticeKind.error)],
      );
    }

    if (file.isLoading && !file.hasValue) {
      return NcPage(
        appBar: appBar,
        title: greeting,
        children: const <Widget>[Center(child: CircularProgressIndicator())],
      );
    }

    final current = file.value;

    // Modèle « agence » : la fiche est créée par l'agence. Sans fiche, le compte n'est pas dans
    // l'équipe (le serveur refuse d'ailleurs la connexion) : il n'y a rien à faire ici.
    if (current == null) {
      return NcPage(
        appBar: appBar,
        title: l10n.proNoTeamTitle,
        children: <Widget>[
          NcNotice(key: const ValueKey<String>('no-team'), message: l10n.proNoTeamBody, kind: NcNoticeKind.warning),
        ],
      );
    }

    return switch (current.status) {
      VerificationStatus.draft || VerificationStatus.rejected => NcPage(
          appBar: appBar,
          title: current.status == VerificationStatus.rejected ? l10n.proStatusRejectedTitle : l10n.proCreateFileTitle,
          subtitle: current.status == VerificationStatus.rejected && (current.statusReason ?? '').isNotEmpty
              ? l10n.proReason(current.statusReason!)
              : l10n.proCreateFileIntro,
          actions: <Widget>[
            NcPrimaryButton(
              label: l10n.proFileTitle,
              icon: Icons.folder_outlined,
              onPressed: () => context.push(routeFile),
            ),
          ],
          children: const <Widget>[],
        ),
      VerificationStatus.submitted || VerificationStatus.underReview => NcPage(
          appBar: appBar,
          title: l10n.proStatusSubmittedTitle,
          subtitle: l10n.proStatusSubmittedBody,
          onRefresh: _pullToRefresh,
          children: <Widget>[
            const SizedBox(height: NcSpacing.lg),
            Center(
              child: Container(
                width: 144,
                height: 144,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_top,
                  size: 72,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      VerificationStatus.suspended => NcPage(
          appBar: appBar,
          title: l10n.proStatusSuspendedTitle,
          subtitle: l10n.proStatusSuspendedBody,
          children: <Widget>[
            if ((current.statusReason ?? '').isNotEmpty)
              NcNotice(message: l10n.proReason(current.statusReason!), kind: NcNoticeKind.warning),
          ],
        ),
      VerificationStatus.verified => _verifiedShell(context, greeting, name, current),
    };
  }

  /// Soignant vérifié : l'écran à onglets. Les missions sont suivies quel que soit l'onglet
  /// ouvert, car le suivi du trajet se règle sur elles.
  Widget _verifiedShell(BuildContext context, String greeting, String? name, ProfessionalFile file) {
    final l10n = context.l10n;

    // La position n'est partagée que pendant un trajet : le suivi s'aligne sur les missions.
    ref.listen(missionsProvider, (previous, next) {
      if (next case AsyncData<List<Mission>>(:final value)) {
        ref.read(journeyTrackerProvider.notifier).sync(value);
      }
    });

    return NcTabScaffold(
      index: _tab,
      onSelected: (tab) => setState(() => _tab = tab),
      tabs: <NcTab>[
        NcTab(
          key: const ValueKey<String>('tab-missions'),
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: l10n.navMissions,
        ),
        NcTab(
          key: const ValueKey<String>('tab-planning'),
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: l10n.navPlanning,
        ),
        NcTab(
          key: const ValueKey<String>('tab-file'),
          icon: Icons.folder_outlined,
          selectedIcon: Icons.folder,
          label: l10n.navFile,
        ),
        NcTab(
          key: const ValueKey<String>('tab-account'),
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
          label: l10n.navAccount,
        ),
      ],
      body: switch (_tab) {
        1 => const PlanningScreen(),
        2 => const FileScreen(embedded: true),
        3 => const SettingsScreen(),
        _ => _missionsTab(context, greeting, name, file),
      },
    );
  }

  /// Onglet des missions : salutation, chiffres du jour, missions à confirmer, missions,
  /// puis l'accès rapide au planning.
  Widget _missionsTab(BuildContext context, String greeting, String? name, ProfessionalFile file) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final missions = ref.watch(missionsProvider);
    final workingDays = file.availabilities.map((slot) => slot.weekday).toSet().length;

    final missionList = missions.value;
    // Les missions que la coordination vient d'affecter passent devant : elles attendent une réponse.
    final toConfirm = <Mission>[...?missionList?.where((mission) => mission.needsConfirmation)];
    final confirmed = <Mission>[...?missionList?.where((mission) => !mission.needsConfirmation)];
    final today = DateTime.now();
    final todayCount = confirmed.where((mission) => DateUtils.isSameDay(mission.scheduledDate, today)).length;

    // Flèche directionnelle : elle s'inverse en arabe.
    final chevron = Icon(
      Icons.chevron_right,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      textDirection: Directionality.of(context),
    );

    String when(Mission mission) =>
        '${mission.patientName}\n${l10n.dateAtTime(longDate(mission.scheduledDate, language), mission.scheduledTime)}';

    return NcPage(
      title: greeting,
      header: NcHomeHeader(
        greeting: greeting,
        caption: file.categoryName,
        trailing: <Widget>[
          NcRoundIconButton(icon: Icons.refresh, tooltip: l10n.refresh, onPressed: _refresh),
          NcAvatar(name: name),
        ],
      ),
      onRefresh: _pullToRefresh,
      children: <Widget>[
        // Le planning est fixé par l'agence : tant qu'il manque des zones ou des jours, on le dit.
        if (file.zones.isEmpty || workingDays == 0) ...<Widget>[
          NcNotice(key: const ValueKey<String>('home-planning-missing'), message: l10n.planningMissing),
          const SizedBox(height: NcSpacing.md),
        ],
        if (missionList != null)
          NcTileGrid(
            columns: 3,
            children: <Widget>[
              NcStatTile(
                key: const ValueKey<String>('stat-today'),
                value: '$todayCount',
                label: l10n.proStatToday,
                icon: Icons.today_outlined,
              ),
              NcStatTile(
                key: const ValueKey<String>('stat-to-confirm'),
                value: '${toConfirm.length}',
                label: l10n.proStatToConfirm,
                icon: Icons.timer_outlined,
                tone: toConfirm.isEmpty ? NcBadgeTone.neutral : NcBadgeTone.progress,
              ),
              NcStatTile(
                key: const ValueKey<String>('stat-upcoming'),
                value: '${confirmed.length}',
                label: l10n.proStatUpcoming,
                icon: Icons.event_available_outlined,
                tone: NcBadgeTone.info,
              ),
            ],
          ),
        if (toConfirm.isNotEmpty) ...<Widget>[
          const SizedBox(height: NcSpacing.sm),
          NcSectionTitle(l10n.proToConfirmTitle),
          for (final mission in toConfirm)
            NcListCard(
              key: ValueKey<String>('mission-${mission.id}'),
              icon: Icons.assignment_late_outlined,
              title: mission.serviceName,
              subtitle: when(mission),
              badge: missionToConfirmBadge(l10n, mission),
              highlighted: true,
              onTap: () => context.push(routeMission(mission.id)),
            ),
        ],
        const SizedBox(height: NcSpacing.sm),
        NcSectionTitle(l10n.proMissionsTitle),
        // Pendant un rechargement, la liste déjà affichée reste en place : pas de clignotement.
        if (missionList != null && confirmed.isEmpty)
          NcEmptyState(message: l10n.proMissionsEmpty, icon: Icons.event_available_outlined)
        else if (missionList != null)
          for (final mission in confirmed)
            NcListCard(
              key: ValueKey<String>('mission-${mission.id}'),
              icon: missionStatusBadge(l10n, mission.status).icon,
              iconTone: missionStatusBadge(l10n, mission.status).tone,
              title: mission.serviceName,
              subtitle: when(mission),
              badge: missionStatusBadge(l10n, mission.status),
              onTap: () => context.push(routeMission(mission.id)),
            )
        else if (missions.hasError)
          NcNotice(message: failureMessage(context, missions.error!), kind: NcNoticeKind.error)
        else
          const Center(child: CircularProgressIndicator()),
        const SizedBox(height: NcSpacing.md),
        NcSectionTitle(l10n.homeQuickActions),
        // Des lignes plutôt que des tuiles : les libellés sont longs.
        NcFeedRow(
          key: const ValueKey<String>('home-planning'),
          icon: Icons.calendar_month_outlined,
          title: l10n.proPlanningTitle,
          subtitle: '${l10n.proScheduleCount(workingDays)} · ${l10n.proZonesCount(file.zones.length)}',
          trailing: chevron,
          onTap: () => context.push(routeSchedule),
        ),
        NcFeedRow(
          key: const ValueKey<String>('home-unavailability'),
          icon: Icons.event_busy_outlined,
          tone: NcBadgeTone.progress,
          title: l10n.planningReportUnavailability,
          trailing: chevron,
          onTap: () => context.push(routeUnavailability),
        ),
        NcFeedRow(
          key: const ValueKey<String>('home-propose-week'),
          icon: Icons.edit_calendar_outlined,
          tone: NcBadgeTone.info,
          title: l10n.planningProposeWeek,
          trailing: chevron,
          onTap: () => context.push(routeProposeWeek),
        ),
      ],
    );
  }
}
