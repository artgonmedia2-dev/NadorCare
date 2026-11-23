import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'prescription_picker.dart';

const String routeBookings = '/bookings';

String routeBookingNew(String serviceSlug) => '/bookings/new/$serviceSlug';

String routeBooking(String id) => '/bookings/detail/$id';

String routeBookingReport(String id) => '/bookings/detail/$id/report';

final bookingsApiProvider = Provider<BookingsApi>((ref) => HttpBookingsApi(ref.watch(apiClientProvider)));

final prescriptionPickerProvider = Provider<PrescriptionPicker>((ref) => DevicePrescriptionPicker());

typedef DayQuery = ({String serviceId, String date});

// Pas de nouvelle tentative automatique : en cas d'échec, l'écran propose « Réessayer ».
final bookingDayProvider = FutureProvider.autoDispose.family<BookingDay, DayQuery>(
  (ref, query) => ref.watch(bookingsApiProvider).slots(serviceId: query.serviceId, date: query.date),
  retry: (retryCount, error) => null,
);

typedef QuoteQuery = ({String serviceId, BookingSlot? slot});

final bookingQuoteProvider = FutureProvider.autoDispose.family<PriceQuote, QuoteQuery>(
  (ref, query) => ref.watch(bookingsApiProvider).quote(serviceId: query.serviceId, slot: query.slot),
  retry: (retryCount, error) => null,
);

/// Réservations du compte : `false` pour celles en cours et à venir, `true` pour les passées.
final bookingsListProvider = FutureProvider.autoDispose.family<List<Booking>, bool>(
  (ref, past) {
    // Les libellés (soin, majorations) dépendent de la langue.
    ref.watch(settingsControllerProvider.select((settings) => settings.languageCode));
    return ref.watch(bookingsApiProvider).list(past: past);
  },
  retry: (retryCount, error) => null,
);

final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>(
  (ref, id) {
    ref.watch(settingsControllerProvider.select((settings) => settings.languageCode));
    return ref.watch(bookingsApiProvider).get(id);
  },
  retry: (retryCount, error) => null,
);

/// Compte rendu d'un soin terminé.
final bookingReportProvider = FutureProvider.autoDispose.family<Intervention, String>(
  (ref, id) => ref.watch(bookingsApiProvider).report(id),
  retry: (retryCount, error) => null,
);

/// Étiquette d'état d'une réservation : icône et texte, pour ne pas dépendre de la couleur.
NcStatusBadge bookingStatusBadge(NcLocalizations l10n, BookingStatus status, {Key? key}) {
  final (IconData icon, NcBadgeTone tone) = switch (status) {
    BookingStatus.pending => (Icons.hourglass_empty, NcBadgeTone.progress),
    BookingStatus.confirmed => (Icons.event_available_outlined, NcBadgeTone.success),
    BookingStatus.assigned => (Icons.person_outline, NcBadgeTone.success),
    BookingStatus.enRoute => (Icons.directions_car_outlined, NcBadgeTone.progress),
    BookingStatus.inProgress => (Icons.medical_services_outlined, NcBadgeTone.success),
    BookingStatus.completed => (Icons.check_circle_outline, NcBadgeTone.neutral),
    BookingStatus.cancelled => (Icons.cancel_outlined, NcBadgeTone.danger),
    BookingStatus.disputed => (Icons.report_problem_outlined, NcBadgeTone.danger),
  };

  return NcStatusBadge(key: key, label: bookingStatusLabel(l10n, status), icon: icon, tone: tone);
}

String bookingStatusLabel(NcLocalizations l10n, BookingStatus status) {
  return switch (status) {
    BookingStatus.pending => l10n.statusPending,
    BookingStatus.confirmed => l10n.statusConfirmed,
    BookingStatus.assigned => l10n.statusAssigned,
    BookingStatus.enRoute => l10n.statusEnRoute,
    BookingStatus.inProgress => l10n.statusInProgress,
    BookingStatus.completed => l10n.statusCompleted,
    BookingStatus.cancelled => l10n.statusCancelled,
    BookingStatus.disputed => l10n.statusDisputed,
  };
}
