import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../catalogue/catalogue_providers.dart';
import 'bookings_providers.dart';
import 'price_breakdown.dart';

/// Mes réservations : celles en cours et à venir, ou les passées.
class BookingsScreen extends ConsumerStatefulWidget {
  const BookingsScreen({super.key});

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
      appBar: AppBar(leading: BackButton(onPressed: () => context.go(NcRoutes.home))),
      title: l10n.homeBookings,
      children: <Widget>[
        NcChoiceList<bool>(
          keyPrefix: 'bookings-scope',
          selected: _past,
          onSelected: (past) => setState(() => _past = past),
          choices: <NcChoice<bool>>[
            NcChoice<bool>(value: false, label: l10n.bookingsUpcoming),
            NcChoice<bool>(value: true, label: l10n.bookingsPast),
          ],
        ),
        const SizedBox(height: NcSpacing.md),
        ...switch (bookings) {
          AsyncData<List<Booking>>(:final value) when value.isEmpty => <Widget>[
              NcNotice(message: _past ? l10n.bookingsPastEmpty : l10n.bookingsEmpty),
            ],
          AsyncData<List<Booking>>(:final value) => <Widget>[
              for (final booking in value)
                NcListCard(
                  key: ValueKey<String>('booking-${booking.id}'),
                  icon: Icons.event_note_outlined,
                  title: booking.serviceName,
                  subtitle:
                      '${booking.patientName}\n${l10n.dateAtTime(longDate(booking.scheduledDate, language), booking.scheduledTime)}',
                  badge: Text(
                    bookingStatusLabel(l10n, booking.status),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => context.push(routeBooking(booking.id)),
                ),
            ],
          AsyncError<List<Booking>>(:final error) => <Widget>[
              NcNotice(message: failureMessage(context, error), kind: NcNoticeKind.error),
              const SizedBox(height: NcSpacing.md),
              NcSecondaryButton(label: l10n.retry, onPressed: () => ref.invalidate(bookingsListProvider(_past))),
            ],
          _ => const <Widget>[Center(child: CircularProgressIndicator())],
        },
      ],
    );
  }
}

/// Fiche d'une réservation : statut, détails, prix, et annulation tant qu'elle est possible.
class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({required this.bookingId, super.key});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _cancelling = false;
  String? _error;

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
      AsyncData<Booking>(value: final booking) => NcPage(
          appBar: AppBar(),
          title: booking.serviceName,
          subtitle: l10n.bookingReference(isolateLtr(booking.reference)),
          actions: <Widget>[
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
            NcNotice(
              key: const ValueKey<String>('booking-status'),
              message: bookingStatusLabel(l10n, booking.status),
              kind: booking.status == BookingStatus.cancelled ? NcNoticeKind.warning : NcNoticeKind.info,
            ),
            if ((booking.cancellationFee ?? 0) > 0) ...<Widget>[
              const SizedBox(height: NcSpacing.sm),
              Text(l10n.bookingFeeCharged(formatDirhams(booking.cancellationFee!, language))),
            ],
            const SizedBox(height: NcSpacing.lg),
            SummaryRow(label: l10n.summaryPatient, value: booking.patientName),
            SummaryRow(
              label: l10n.summarySlot,
              value: l10n.dateAtTime(longDate(booking.scheduledDate, language), booking.scheduledTime),
            ),
            SummaryRow(
              label: l10n.summaryAddress,
              value: <String?>[booking.addressLabel, booking.addressLine].whereType<String>().join('\n'),
            ),
            SummaryRow(label: l10n.summaryPayment, value: l10n.paymentCash),
            if ((booking.patientNote ?? '').isNotEmpty)
              SummaryRow(label: l10n.noteLabel, value: booking.patientNote!),
            PriceBreakdown(price: booking.price),
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
