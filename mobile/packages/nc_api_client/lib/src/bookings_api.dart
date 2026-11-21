import 'dart:typed_data';

import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Réservations du compte connecté.
abstract interface class BookingsApi {
  /// Créneaux d'un jour (`AAAA-MM-JJ`, jour de Nador) pour un service.
  Future<BookingDay> slots({required String serviceId, required String date});

  /// Prix du soin au créneau donné ; sans créneau, pour maintenant.
  Future<PriceQuote> quote({required String serviceId, BookingSlot? slot});

  /// Envoie l'ordonnance (photo ou PDF) et renvoie son identifiant.
  Future<String> uploadPrescription({required Uint8List bytes, required String filename});

  Future<Booking> create(BookingDraft draft);

  Future<List<Booking>> list({bool past = false});

  /// Fiche détaillée, avec la note du patient. Le serveur journalise cette lecture.
  Future<Booking> get(String id);

  Future<Booking> cancel(String id, {String? reason});
}

class HttpBookingsApi implements BookingsApi {
  const HttpBookingsApi(this._client);

  final ApiClient _client;

  static Map<String, dynamic> _data(Map<String, dynamic> json) => json['data'] as Map<String, dynamic>;

  @override
  Future<BookingDay> slots({required String serviceId, required String date}) async {
    final json = await _client.get('/bookings/slots', query: <String, dynamic>{'service_id': serviceId, 'date': date});
    return BookingDay.fromJson(_data(json));
  }

  @override
  Future<PriceQuote> quote({required String serviceId, BookingSlot? slot}) async {
    final json = await _client.post('/bookings/quote', <String, dynamic>{
      'service_id': serviceId,
      'scheduled_at': ?slot?.startsAt,
    });
    return PriceQuote.fromJson(_data(json));
  }

  @override
  Future<String> uploadPrescription({required Uint8List bytes, required String filename}) async {
    final json = await _client.upload('/files/prescriptions', field: 'file', bytes: bytes, filename: filename);
    return _data(json)['id'] as String;
  }

  @override
  Future<Booking> create(BookingDraft draft) async {
    return Booking.fromJson(_data(await _client.post('/bookings', draft.toJson())));
  }

  @override
  Future<List<Booking>> list({bool past = false}) async {
    final json = await _client.get('/bookings', query: <String, dynamic>{'scope': past ? 'past' : 'upcoming'});
    return ((json['data'] as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => Booking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Booking> get(String id) async => Booking.fromJson(_data(await _client.get('/bookings/$id')));

  @override
  Future<Booking> cancel(String id, {String? reason}) async {
    final json = await _client.post('/bookings/$id/cancel', <String, dynamic>{'reason': ?reason});
    return Booking.fromJson(_data(json));
  }
}
