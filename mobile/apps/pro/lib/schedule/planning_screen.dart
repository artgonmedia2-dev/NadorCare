import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../pro_providers.dart';

/// Planning du soignant, en lecture : c'est l'agence qui fixe ses zones et sa semaine type.
/// Pour le changer, il envoie une demande, que la coordination accepte ou refuse.
class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen> {
  String? _withdrawing;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Le planning change au back-office : on le relit à l'ouverture, sans masquer l'écran.
    Future<void>.microtask(() => ref.read(professionalFileProvider.notifier).refreshQuietly());
  }

  Future<void> _withdraw(ScheduleRequest request) async {
    setState(() {
      _withdrawing = request.id;
      _error = null;
    });

    try {
      await ref.read(proApiProvider).cancelScheduleRequest(request.id);
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      // La liste est relue dans tous les cas : la coordination a pu répondre entre-temps.
      ref.invalidate(scheduleRequestsProvider);
      if (mounted) {
        setState(() => _withdrawing = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final file = ref.watch(professionalFileProvider).value;
    final requests = ref.watch(scheduleRequestsProvider);
    final requestList = requests.value;

    final zones = file?.zones ?? const <ServiceZone>[];
    final slots = file?.availabilities ?? const <AvailabilitySlot>[];

    return NcPage(
      appBar: AppBar(),
      title: l10n.proPlanningTitle,
      subtitle: l10n.proPlanningHelp,
      children: <Widget>[
        // La semaine type d'abord : c'est ce que le soignant consulte le plus.
        NcSection(
          title: l10n.planningWeek,
          icon: Icons.calendar_view_week_outlined,
          children: <Widget>[
            if (slots.isEmpty)
              NcNotice(key: const ValueKey<String>('planning-week-unset'), message: l10n.planningNotSet)
            else
              for (final weekday in orderedWeekdays)
                _WeekRow(
                  key: slots.any((slot) => slot.weekday == weekday)
                      ? ValueKey<String>('planning-day-$weekday')
                      : null,
                  day: weekdayName(weekday, language),
                  ranges: slots.any((slot) => slot.weekday == weekday) ? weekRanges(l10n, slots, weekday) : null,
                  offLabel: l10n.planningDayOff,
                ),
          ],
        ),
        NcSection(
          title: l10n.planningZones,
          icon: Icons.map_outlined,
          children: <Widget>[
            if (zones.isEmpty)
              NcNotice(key: const ValueKey<String>('planning-zones-unset'), message: l10n.planningNotSet)
            else
              Wrap(
                spacing: NcSpacing.sm,
                runSpacing: NcSpacing.sm,
                children: <Widget>[
                  for (final zone in zones) NcStatusBadge(label: zone.name, icon: Icons.place_outlined, tone: NcBadgeTone.brand),
                ],
              ),
            const SizedBox(height: NcSpacing.xs),
          ],
        ),
        const SizedBox(height: NcSpacing.xs),
        NcTileGrid(
          children: <Widget>[
            NcActionTile(
              key: const ValueKey<String>('propose-week'),
              icon: Icons.edit_calendar_outlined,
              label: l10n.planningProposeWeek,
              onTap: () => context.push(routeProposeWeek),
            ),
            NcActionTile(
              key: const ValueKey<String>('report-unavailability'),
              icon: Icons.event_busy_outlined,
              label: l10n.planningReportUnavailability,
              onTap: () => context.push(routeUnavailability),
            ),
          ],
        ),
        const SizedBox(height: NcSpacing.sm),
        NcSectionTitle(l10n.planningRequests),
        if (_error != null) ...<Widget>[
          NcNotice(message: _error!, kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.sm),
        ],
        if (requestList != null && requestList.isEmpty)
          NcEmptyState(message: l10n.planningRequestsEmpty, icon: Icons.inbox_outlined)
        else if (requestList != null)
          for (final request in requestList)
            _RequestCard(
              request: request,
              language: language,
              isBusy: _withdrawing == request.id,
              onWithdraw: () => _withdraw(request),
            )
        else if (requests.hasError) ...<Widget>[
          NcNotice(message: failureMessage(context, requests.error!), kind: NcNoticeKind.error),
          const SizedBox(height: NcSpacing.sm),
          NcSecondaryButton(label: l10n.retry, onPressed: () => ref.invalidate(scheduleRequestsProvider)),
        ] else
          const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

/// Une demande : ce qui est demandé, son état, et la réponse de la coordination s'il y en a une.
class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.language, required this.isBusy, required this.onWithdraw});

  final ScheduleRequest request;
  final String language;
  final bool isBusy;
  final VoidCallback onWithdraw;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;

    final (String label, IconData icon, NcBadgeTone tone) = switch (request.status) {
      ScheduleRequest.statusAccepted => (l10n.planningStatusAccepted, Icons.check_circle_outline, NcBadgeTone.success),
      ScheduleRequest.statusRefused => (l10n.planningStatusRefused, Icons.cancel_outlined, NcBadgeTone.danger),
      ScheduleRequest.statusCancelled => (l10n.planningStatusCancelled, Icons.undo_outlined, NcBadgeTone.neutral),
      _ => (l10n.planningStatusPending, Icons.hourglass_empty, NcBadgeTone.progress),
    };

    final start = request.startsOn;
    final end = request.endsOn;

    return NcSurface(
      key: ValueKey<String>('request-${request.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          NcIconBubble(
            icon: request.isWeekly ? Icons.edit_calendar_outlined : Icons.event_busy_outlined,
            size: 40,
            background: ncToneColors(tone).$1,
            foreground: ncToneColors(tone).$2,
          ),
          const SizedBox(width: NcSpacing.sm + 4),
          Expanded(
            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            request.isWeekly ? l10n.planningKindWeekly : l10n.planningKindUnavailability,
            style: textTheme.titleMedium,
          ),
          const SizedBox(height: NcSpacing.xs),
          if (request.isWeekly)
            for (final weekday in orderedWeekdays)
              if (request.slots.any((slot) => slot.weekday == weekday))
                Text(
                  '${weekdayName(weekday, language)} : ${weekRanges(l10n, request.slots, weekday)}',
                  style: textTheme.bodyLarge,
                )
              else
                const SizedBox.shrink()
          else if (start != null && end != null)
            Text(
              start == end
                  ? longDate(start, language)
                  : l10n.planningFromTo(longDate(start, language), longDate(end, language)),
              style: textTheme.bodyLarge,
            ),
          if (request.note case final note?) ...<Widget>[
            const SizedBox(height: NcSpacing.xs),
            Text(note, style: textTheme.bodyMedium),
          ],
          const SizedBox(height: NcSpacing.sm),
          NcStatusBadge(label: label, icon: icon, tone: tone),
          if (request.decisionNote case final answer?) ...<Widget>[
            const SizedBox(height: NcSpacing.sm),
            Text(l10n.planningDecisionNote(answer), style: textTheme.bodyLarge),
          ],
          if (request.isPending)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                key: ValueKey<String>('withdraw-${request.id}'),
                onPressed: isBusy ? null : onWithdraw,
                child: Text(l10n.planningWithdraw),
              ),
            ),
        ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Un jour de la semaine type : le nom du jour, puis ses plages, ou « Repos ».
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.day, required this.ranges, required this.offLabel, super.key});

  final String day;
  final String? ranges;
  final String offLabel;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final working = ranges != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: NcSpacing.xs + 2),
      child: Row(
        children: <Widget>[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: working ? scheme.primary : scheme.outlineVariant,
            ),
          ),
          const SizedBox(width: NcSpacing.sm + 4),
          SizedBox(
            width: 104,
            child: Text(
              day,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: working ? scheme.onSurface : scheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ranges ?? offLabel,
              style: textTheme.bodyLarge?.copyWith(
                fontSize: 16,
                fontWeight: working ? FontWeight.w600 : FontWeight.w400,
                color: working ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
