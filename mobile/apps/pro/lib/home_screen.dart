import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'pro_providers.dart';

/// Accueil de l'application professionnel. Ce qu'il montre dépend de l'état du dossier :
/// création, justificatifs à déposer, vérification en cours, puis propositions et missions.
class ProHomeScreen extends ConsumerStatefulWidget {
  const ProHomeScreen({super.key});

  @override
  ConsumerState<ProHomeScreen> createState() => _ProHomeScreenState();
}

class _ProHomeScreenState extends ConsumerState<ProHomeScreen> {
  /// Les propositions expirent vite et les notifications ne sont pas encore branchées :
  /// l'écran se rafraîchit de lui-même.
  static const Duration _refreshEvery = Duration(seconds: 15);

  Timer? _timer;
  String? _busyOffer;
  bool _togglingOnline = false;
  String? _error;

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
    ref
      ..invalidate(missionOffersProvider)
      ..invalidate(missionsProvider);
  }

  Future<void> _setOnline(bool online) async {
    setState(() {
      _togglingOnline = true;
      _error = null;
    });

    try {
      await ref.read(professionalFileProvider.notifier).setOnline(online: online);
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _togglingOnline = false);
      }
    }
  }

  Future<void> _answer(MissionOffer offer, {required bool accept}) async {
    setState(() {
      _busyOffer = offer.id;
      _error = null;
    });

    try {
      if (accept) {
        final mission = await ref.read(proApiProvider).acceptOffer(offer.id);
        ref
          ..invalidate(missionOffersProvider)
          ..invalidate(missionsProvider);
        if (mounted) {
          await context.push(routeMission(mission.id));
        }
      } else {
        await ref.read(proApiProvider).declineOffer(offer.id);
        ref.invalidate(missionOffersProvider);
      }
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
      ref.invalidate(missionOffersProvider);
    } finally {
      if (mounted) {
        setState(() => _busyOffer = null);
      }
    }
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

    // Pas encore de dossier.
    if (current == null) {
      return NcPage(
        appBar: appBar,
        title: l10n.proCreateFileTitle,
        subtitle: l10n.proCreateFileIntro,
        actions: <Widget>[NcPrimaryButton(label: l10n.proStart, onPressed: () => context.push(routeProfession))],
        children: const <Widget>[],
      );
    }

    return switch (current.status) {
      VerificationStatus.draft || VerificationStatus.rejected => NcPage(
          appBar: appBar,
          title: current.status == VerificationStatus.rejected ? l10n.proStatusRejectedTitle : l10n.proCreateFileTitle,
          subtitle: current.status == VerificationStatus.rejected && (current.statusReason ?? '').isNotEmpty
              ? l10n.proReason(current.statusReason!)
              : l10n.proCreateFileIntro,
          actions: <Widget>[NcPrimaryButton(label: l10n.proFileTitle, onPressed: () => context.push(routeFile))],
          children: const <Widget>[],
        ),
      VerificationStatus.submitted || VerificationStatus.underReview => NcPage(
          appBar: appBar,
          title: l10n.proStatusSubmittedTitle,
          subtitle: l10n.proStatusSubmittedBody,
          children: <Widget>[
            Icon(Icons.hourglass_top, size: 96, color: Theme.of(context).colorScheme.primary),
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
      VerificationStatus.verified => _verified(context, appBar, greeting, current),
    };
  }

  Widget _verified(BuildContext context, PreferredSizeWidget appBar, String greeting, ProfessionalFile file) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final language = Localizations.localeOf(context).languageCode;
    final offers = ref.watch(missionOffersProvider);
    final missions = ref.watch(missionsProvider);
    final workingDays = file.availabilities.map((slot) => slot.weekday).toSet().length;

    return NcPage(
      appBar: appBar,
      title: greeting,
      children: <Widget>[
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.md),
        ],
        SwitchListTile(
          key: const ValueKey<String>('online-switch'),
          contentPadding: EdgeInsets.zero,
          value: file.isOnline,
          onChanged: _togglingOnline ? null : _setOnline,
          title: Text(file.isOnline ? l10n.proOnline : l10n.proOffline, style: textTheme.titleLarge),
          subtitle: Text(l10n.proOnlineHelp),
        ),
        const SizedBox(height: NcSpacing.lg),
        Text(l10n.proOffersTitle, style: textTheme.titleLarge),
        const SizedBox(height: NcSpacing.sm),
        ...switch (offers) {
          AsyncData<List<MissionOffer>>(:final value) when value.isEmpty => <Widget>[
              NcNotice(message: l10n.proOffersEmpty),
            ],
          AsyncData<List<MissionOffer>>(:final value) => <Widget>[
              for (final offer in value)
                _OfferCard(
                  offer: offer,
                  language: language,
                  isBusy: _busyOffer == offer.id,
                  onAccept: () => _answer(offer, accept: true),
                  onDecline: () => _answer(offer, accept: false),
                ),
            ],
          AsyncError<List<MissionOffer>>(:final error) => <Widget>[
              NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
            ],
          _ => const <Widget>[Center(child: CircularProgressIndicator())],
        },
        const SizedBox(height: NcSpacing.lg),
        Text(l10n.proMissionsTitle, style: textTheme.titleLarge),
        const SizedBox(height: NcSpacing.sm),
        ...switch (missions) {
          AsyncData<List<Mission>>(:final value) when value.isEmpty => <Widget>[
              NcNotice(message: l10n.proMissionsEmpty),
            ],
          AsyncData<List<Mission>>(:final value) => <Widget>[
              for (final mission in value)
                NcListCard(
                  key: ValueKey<String>('mission-${mission.id}'),
                  icon: Icons.medical_services_outlined,
                  title: mission.serviceName,
                  subtitle:
                      '${mission.patientName}\n${l10n.dateAtTime(longDate(mission.scheduledDate, language), mission.scheduledTime)}',
                  badge: Text(
                    missionStatusLabel(l10n, mission.status),
                    style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => context.push(routeMission(mission.id)),
                ),
            ],
          AsyncError<List<Mission>>(:final error) => <Widget>[
              NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
            ],
          _ => const <Widget>[Center(child: CircularProgressIndicator())],
        },
        const SizedBox(height: NcSpacing.lg),
        NcListCard(
          key: const ValueKey<String>('home-zones'),
          icon: Icons.map_outlined,
          title: l10n.proZones,
          subtitle: l10n.proZonesCount(file.zones.length),
          onTap: () => context.push(routeZones),
        ),
        NcListCard(
          key: const ValueKey<String>('home-schedule'),
          icon: Icons.calendar_month_outlined,
          title: l10n.proSchedule,
          subtitle: l10n.proScheduleCount(workingDays),
          onTap: () => context.push(routeSchedule),
        ),
        NcListCard(
          key: const ValueKey<String>('home-file'),
          icon: Icons.folder_outlined,
          title: l10n.proFileTitle,
          subtitle: file.categoryName,
          onTap: () => context.push(routeFile),
        ),
      ],
    );
  }
}

/// Proposition de mission : avant d'accepter, seuls le soin, le créneau, la zone et la
/// distance sont connus.
class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.offer,
    required this.language,
    required this.isBusy,
    required this.onAccept,
    required this.onDecline,
  });

  final MissionOffer offer;
  final String language;
  final bool isBusy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final expiresAt = offer.expiresAt;
    final distance = offer.distanceMeters;

    final details = <String>[
      l10n.dateAtTime(longDate(offer.scheduledDate, language), offer.scheduledTime),
      l10n.serviceDuration(offer.durationMinutes),
      if ((offer.zone ?? '').isNotEmpty) offer.zone!,
      if (distance != null) l10n.offerDistance(formatDistance(distance, language)),
    ];

    return Container(
      key: ValueKey<String>('offer-${offer.id}'),
      margin: const EdgeInsets.only(bottom: NcSpacing.md),
      padding: const EdgeInsets.all(NcSpacing.md),
      decoration: BoxDecoration(color: scheme.primaryContainer, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(offer.serviceName, style: textTheme.titleLarge),
          const SizedBox(height: NcSpacing.xs),
          Text(details.join('\n'), style: textTheme.bodyLarge),
          if (expiresAt != null) ...<Widget>[
            const SizedBox(height: NcSpacing.sm),
            Text(
              // Heure du téléphone : c'est le délai pour répondre, pas l'heure du soin.
              l10n.offerAnswerBefore(DateFormat.Hms(language == 'ar' ? 'ar_MA' : language).format(expiresAt.toLocal())),
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
          const SizedBox(height: NcSpacing.md),
          if (isBusy)
            const Center(child: CircularProgressIndicator())
          else ...<Widget>[
            NcPrimaryButton(key: ValueKey<String>('accept-${offer.id}'), label: l10n.offerAccept, onPressed: onAccept),
            const SizedBox(height: NcSpacing.sm),
            NcSecondaryButton(
              key: ValueKey<String>('decline-${offer.id}'),
              label: l10n.offerDecline,
              onPressed: onDecline,
            ),
          ],
        ],
      ),
    );
  }
}
