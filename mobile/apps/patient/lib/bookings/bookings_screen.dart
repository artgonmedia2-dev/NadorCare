import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'bookings_providers.dart';
import 'price_breakdown.dart';

/// Mes réservations : celles en cours et à venir, ou les passées.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({this.embedded = false, super.key});

  /// Affiché dans un onglet de l'accueil : pas de bouton de retour.
  final bool embedded;

  @override
  ConsumerState<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends ConsumerState<BookingsScreen> {
  bool _past = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final bookings = ref.watch(bookingsListProvider(_past));

    return NcPage(
      appBar: widget.embedded ? null : AppBar(leading: BackButton(onPressed: () => context.go(NcRoutes.home))),
      title: l10n.homeBookings,
      onRefresh: () async => ref.invalidate(bookingsListProvider(_past)),
      children: <Widget>[
        NcSegmented<bool>(
          keyPrefix: 'bookings-scope',
          selected: _past,
          onSelected: (past) => setState(() => _past = past),
          segments: <NcChip<bool>>[
            NcChip<bool>(value: false, label: l10n.bookingsUpcoming),
            NcChip<bool>(value: true, label: l10n.bookingsPast),
          ],
        ),
        const SizedBox(height: NcSpacing.md),
        ...switch (bookings) {
          AsyncData<List<Booking>>(:final value) when value.isEmpty => <Widget>[
              NcEmptyState(
                message: _past ? l10n.bookingsPastEmpty : l10n.bookingsEmpty,
                icon: Icons.event_busy_outlined,
              ),
            ],
          AsyncData<List<Booking>>(:final value) => <Widget>[
              for (final booking in value)
                NcListCard(
                  key: ValueKey<String>('booking-${booking.id}'),
                  // La pastille prend la couleur de l'état : on repère d'un coup d'œil ce qui bouge.
                  icon: bookingStatusBadge(l10n, booking.status).icon,
                  iconTone: bookingStatusBadge(l10n, booking.status).tone,
                  title: booking.serviceName,
                  subtitle:
                      '${booking.patientName}\n${l10n.dateAtTime(longDate(booking.scheduledDate, language), booking.scheduledTime)}',
                  badge: bookingStatusBadge(l10n, booking.status),
                  onTap: () => context.push(routeBooking(booking.id)),
                ),
            ],
          AsyncError<List<Booking>>(:final error) => <Widget>[
              NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
              const SizedBox(height: NcSpacing.md),
              NcSecondaryButton(
                label: l10n.retry,
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(bookingsListProvider(_past)),
              ),
            ],
          _ => const <Widget>[Center(child: CircularProgressIndicator())],
        },
      ],
    );
  }
}

/// Fiche d'une réservation : statut, détails, prix, et annulation tant qu'elle est possible.
/// En-tête de la fiche : le soin, la référence et l'état, dans le ton de l'état.
Widget _header(NcLocalizations l10n, Booking booking) {
  final status = bookingStatusBadge(l10n, booking.status, key: const ValueKey<String>('booking-status'));

  return NcDetailHeader(
    icon: booking.isRemote ? Icons.videocam_outlined : status.icon,
    tone: status.tone,
    title: booking.serviceName,
    // La référence reste lisible de gauche à droite dans une phrase en arabe.
    subtitle: l10n.bookingReference(isolateLtr(booking.reference)),
    badge: status,
  );
}

/// Suivi de la demande, étape par étape. Rien pour une demande annulée ou contestée :
/// l'étiquette d'état suffit.
Widget? _progress(NcLocalizations l10n, Booking booking) {
  final steps = <NcTimelineStep>[
    NcTimelineStep(label: l10n.timelineSent),
    NcTimelineStep(label: l10n.timelineConfirmed),
    NcTimelineStep(label: l10n.timelineAssigned),
    // Une téléconsultation n'a pas de trajet.
    if (!booking.isRemote) NcTimelineStep(label: l10n.timelineOnTheWay),
    NcTimelineStep(label: l10n.timelineCare),
    NcTimelineStep(label: l10n.timelineDone),
  ];
  final care = booking.isRemote ? 3 : 4;

  final current = switch (booking.status) {
    BookingStatus.pending => 0,
    BookingStatus.confirmed => 1,
    BookingStatus.assigned => 2,
    BookingStatus.enRoute => 3,
    BookingStatus.inProgress => care,
    // Terminé : toutes les étapes sont cochées.
    BookingStatus.completed => steps.length,
    BookingStatus.cancelled || BookingStatus.disputed => -1,
  };

  if (current < 0) {
    return null;
  }

  return NcSection(
    key: const ValueKey<String>('booking-progress'),
    title: l10n.bookingProgressTitle,
    icon: Icons.timeline,
    children: <Widget>[NcTimeline(steps: steps, current: current)],
  );
}

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  /// Tant que les notifications ne sont pas branchées, la fiche se relit d'elle-même
  /// quand un soignant est attendu : départ, arrivée estimée, début du soin.
  static const Duration _refreshEvery = Duration(seconds: 20);

  Timer? _timer;
  bool _cancelling = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_refreshEvery, (_) {
      final status = ref.read(bookingDetailProvider(widget.bookingId)).value?.status;
      if (mounted && (status == BookingStatus.assigned || status == BookingStatus.enRoute)) {
        ref.invalidate(bookingDetailProvider(widget.bookingId));
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancel(Booking booking) async {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final fee = booking.cancellationFeeIfCancelledNow ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.bookingCancelTitle),
        // Les frais sont annoncés avant de confirmer, jamais après.
        content: Text(fee > 0 ? l10n.bookingCancelFee(formatDirhams(fee, language)) : l10n.bookingCancelFree),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(l10n.bookingKeep)),
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(l10n.bookingCancelConfirm)),
        ],
      ),
    );

    if (!(confirmed ?? false) || !mounted) {
      return;
    }

    setState(() {
      _cancelling = true;
      _error = null;
    });

    try {
      await ref.read(bookingsApiProvider).cancel(booking.id);
      ref
        ..invalidate(bookingDetailProvider(booking.id))
        ..invalidate(bookingsListProvider);
    } on ApiFailure catch (failure) {
      if (mounted) {
        setState(() => _error = failureMessage(context, failure));
      }
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final language = Localizations.localeOf(context).languageCode;
    final detail = ref.watch(bookingDetailProvider(widget.bookingId));

    return switch (detail) {
      AsyncValue<Booking>(value: final booking?) => NcPage(
          appBar: AppBar(),
          title: booking.serviceName,
          header: _header(l10n, booking),
          actions: <Widget>[
            if (booking.canJoinTeleconsultation)
              NcPrimaryButton(
                key: const ValueKey<String>('booking-join'),
                label: l10n.teleconsultationJoin,
                icon: Icons.videocam_outlined,
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (context) => TeleconsultationScreen(
                      title: booking.serviceName,
                      loadAccess: () => ref.read(bookingsApiProvider).teleconsultation(booking.id),
                    ),
                  ),
                ),
              ),
            if (booking.hasReport)
              NcPrimaryButton(
                key: const ValueKey<String>('booking-report'),
                label: l10n.bookingReportOpen,
                icon: Icons.description_outlined,
                onPressed: () => context.push(routeBookingReport(booking.id)),
              ),
            if (booking.canCancel)
              NcSecondaryButton(
                key: const ValueKey<String>('booking-cancel'),
                label: l10n.bookingCancel,
                onPressed: _cancelling ? null : () => _cancel(booking),
              ),
          ],
          children: <Widget>[
            if (_error != null) ...<Widget>[
              NcNotice(message: _error!, kind: NcNoticeKind.error),
              const SizedBox(height: NcSpacing.md),
            ],
            if (booking.isRemote) ...<Widget>[
              NcNotice(
                key: const ValueKey<String>('booking-remote'),
                message: booking.canJoinTeleconsultation
                    ? '${l10n.teleconsultationServiceNote} ${l10n.teleconsultationRoomHelp}'
                    : l10n.teleconsultationServiceNote,
              ),
            ],
            if ((booking.cancellationFee ?? 0) > 0) ...<Widget>[
              const SizedBox(height: NcSpacing.sm),
              Text(l10n.bookingFeeCharged(formatDirhams(booking.cancellationFee!, language))),
            ],
            if (booking.status == BookingStatus.enRoute) ...<Widget>[
              const SizedBox(height: NcSpacing.sm),
              NcNotice(
                key: const ValueKey<String>('booking-tracking'),
                message: booking.tracking?.etaMinutes == null
                    ? l10n.trackingOnTheWay
                    : l10n.trackingEta(booking.tracking!.etaMinutes!),
              ),
            ],
            const SizedBox(height: NcSpacing.md),
            ?_progress(l10n, booking),
            NcSection(
              title: l10n.bookingDetailsTitle,
              icon: Icons.info_outline,
              children: <Widget>[
                  if ((booking.professionalName ?? '').isNotEmpty)
                    SummaryRow(
                      icon: Icons.medical_services_outlined,
                      label: l10n.bookingProfessional,
                      value: <String?>[booking.professionalName, booking.professionalProfession]
                          .whereType<String>()
                          .join('\n'),
                    ),
                  SummaryRow(icon: Icons.person_outline, label: l10n.summaryPatient, value: booking.patientName),
                  SummaryRow(
                    icon: Icons.event_outlined,
                    label: l10n.summarySlot,
                    value: l10n.dateAtTime(longDate(booking.scheduledDate, language), booking.scheduledTime),
                  ),
                  SummaryRow(
                    icon: Icons.place_outlined,
                    label: l10n.summaryAddress,
                    value: <String?>[booking.addressLabel, booking.addressLine].whereType<String>().join('\n'),
                  ),
                  SummaryRow(
                    icon: Icons.payments_outlined,
                    label: l10n.summaryPayment,
                    value: booking.isRemote ? l10n.paymentCard : l10n.paymentCash,
                  ),
                  if ((booking.patientNote ?? '').isNotEmpty)
                    SummaryRow(icon: Icons.chat_bubble_outline, label: l10n.noteLabel, value: booking.patientNote!),
              ],
            ),
            NcSection(
              title: l10n.servicePriceLabel,
              icon: Icons.payments_outlined,
              children: <Widget>[PriceBreakdown(price: booking.price)],
            ),
          ],
        ),
      AsyncError<Booking>(:final error) => NcPage(
          appBar: AppBar(),
          title: l10n.homeBookings,
          actions: <Widget>[
            NcPrimaryButton(
              label: l10n.retry,
              onPressed: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
            ),
          ],
          children: <Widget>[NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error)],
        ),
      _ => NcPage(
          appBar: AppBar(),
          title: l10n.homeBookings,
          children: const <Widget>[Center(child: CircularProgressIndicator())],
        ),
    };
  }
}
