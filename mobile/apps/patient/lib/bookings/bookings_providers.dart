import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'prescription_picker.dart';

const String routeBookings = '/bookings';

String routeBookingNew(String serviceSlug) => '/bookings/new/$serviceSlug';

String routeBooking(String id) => '/bookings/detail/$id';

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

/// Jour au format de l'API : `AAAA-MM-JJ`.
String apiDate(DateTime day) {
  return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
}

/// Jour écrit en toutes lettres dans la langue de l'écran : « mardi 8 décembre 2026 ».
String longDate(DateTime day, String languageCode) => DateFormat.yMMMMEEEEd(languageCode).format(day);
