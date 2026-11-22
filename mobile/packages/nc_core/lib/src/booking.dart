/// Statut d'une réservation. Les valeurs sont celles de l'API.
enum BookingStatus {
  pending('pending'),
  confirmed('confirmed'),
  assigned('assigned'),
  enRoute('en_route'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled'),
  disputed('disputed');

  const BookingStatus(this.apiValue);

  final String apiValue;

  static BookingStatus fromApi(String? value) {
    return BookingStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => BookingStatus.pending,
    );
  }
}

/// Ligne d'un prix : une majoration et son montant en centimes.
class PriceLine {
  const PriceLine({required this.label, required this.amount});

  factory PriceLine.fromJson(Map<String, dynamic> json) {
    return PriceLine(label: (json['label'] as String?) ?? '', amount: (json['amount'] as num?)?.toInt() ?? 0);
  }

  final String label;
  final int amount;
}

/// Prix d'un soin à un créneau donné, en centimes de dirham.
class PriceQuote {
  const PriceQuote({required this.base, required this.surcharges, required this.total});

  factory PriceQuote.fromJson(Map<String, dynamic> json) {
    return PriceQuote(
      base: (json['base'] as num?)?.toInt() ?? 0,
      surcharges: ((json['surcharges'] as List<dynamic>?) ?? const <dynamic>[])
          .map((line) => PriceLine.fromJson(line as Map<String, dynamic>))
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }

  final int base;
  final List<PriceLine> surcharges;
  final int total;
}

/// Créneau proposé. [startsAt] est la valeur à renvoyer au serveur ; [time] est l'heure
/// à Nador, à afficher telle quelle quel que soit le fuseau du téléphone.
class BookingSlot {
  const BookingSlot({required this.startsAt, required this.time});

  /// Le serveur envoie `2026-12-08T09:30:00+01:00` : l'heure locale de Nador se lit dans le texte.
  factory BookingSlot.fromIso(String iso) => BookingSlot(startsAt: iso, time: iso.substring(11, 16));

  final String startsAt;
  final String time;

  @override
  bool operator ==(Object other) => other is BookingSlot && other.startsAt == startsAt;

  @override
  int get hashCode => startsAt.hashCode;

  @override
  String toString() => time;
}

/// Créneaux d'un jour.
class BookingDay {
  const BookingDay({required this.slots, required this.immediateAvailable});

  factory BookingDay.fromJson(Map<String, dynamic> json) {
    return BookingDay(
      slots: ((json['slots'] as List<dynamic>?) ?? const <dynamic>[])
          .map((slot) => BookingSlot.fromIso(slot as String))
          .toList(growable: false),
      immediateAvailable: (json['immediate_available'] as bool?) ?? false,
    );
  }

  final List<BookingSlot> slots;

  /// Une demande « dès que possible » est acceptée en ce moment.
  final bool immediateAvailable;
}

/// Demande de soin à envoyer.
class BookingDraft {
  const BookingDraft({
    required this.serviceId,
    required this.patientProfileId,
    required this.addressId,
    this.slot,
    this.patientNote,
    this.prescriptionFileId,
  });

  final String serviceId;
  final String patientProfileId;
  final String addressId;

  /// `null` : dès que possible.
  final BookingSlot? slot;
  final String? patientNote;
  final String? prescriptionFileId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'service_id': serviceId,
        'patient_profile_id': patientProfileId,
        'address_id': addressId,
        'type': slot == null ? 'immediate' : 'scheduled',
        'scheduled_at': slot?.startsAt,
        // Seul le paiement en espèces est ouvert pour l'instant.
        'payment_method': 'cash',
        'patient_note': (patientNote == null || patientNote!.isEmpty) ? null : patientNote,
        'prescription_file_id': prescriptionFileId,
      };
}

/// Suivi de l'arrivée du soignant pendant son trajet.
class BookingTracking {
  const BookingTracking({required this.latitude, required this.longitude, this.etaMinutes});

  factory BookingTracking.fromJson(Map<String, dynamic> json) {
    return BookingTracking(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      etaMinutes: (json['eta_minutes'] as num?)?.toInt(),
    );
  }

  final double latitude;
  final double longitude;

  /// Durée estimée avant l'arrivée ; `null` si elle n'a pas pu être calculée.
  final int? etaMinutes;
}

/// Réservation, telle que renvoyée par l'API.
class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.serviceName,
    required this.patientName,
    required this.price,
    required this.canCancel,
    this.addressLabel,
    this.addressLine,
    this.hasPrescription = false,
    this.cancellationFeeIfCancelledNow,
    this.cancellationFee,
    this.patientNote,
    this.professionalName,
    this.professionalProfession,
    this.tracking,
    this.hasReport = false,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final service = (json['service'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final patient = (json['patient'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final address = (json['address'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final professional = json['professional'] as Map<String, dynamic>?;
    final tracking = json['tracking'] as Map<String, dynamic>?;

    return Booking(
      id: json['id'] as String,
      reference: (json['reference'] as String?) ?? '',
      status: BookingStatus.fromApi(json['status'] as String?),
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: (json['scheduled_time'] as String?) ?? '',
      serviceName: (service['name'] as String?) ?? '',
      patientName: '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim(),
      addressLabel: address['label'] as String?,
      addressLine: address['line'] as String?,
      price: PriceQuote.fromJson((json['price'] as Map<String, dynamic>?) ?? const <String, dynamic>{}),
      hasPrescription: (json['has_prescription'] as bool?) ?? false,
      canCancel: (json['can_cancel'] as bool?) ?? false,
      cancellationFeeIfCancelledNow: (json['cancellation_fee_if_cancelled_now'] as num?)?.toInt(),
      cancellationFee: (json['cancellation_fee'] as num?)?.toInt(),
      patientNote: json['patient_note'] as String?,
      professionalName: professional?['name'] as String?,
      professionalProfession: professional?['profession'] as String?,
      tracking: tracking == null ? null : BookingTracking.fromJson(tracking),
      hasReport: (json['has_report'] as bool?) ?? false,
    );
  }

  final String id;

  /// Numéro lisible, à donner à la coordination : `NC-2026-000123`.
  final String reference;
  final BookingStatus status;

  /// Jour du soin à Nador (sans heure).
  final DateTime scheduledDate;

  /// Heure du soin à Nador, `HH:MM`.
  final String scheduledTime;
  final String serviceName;
  final String patientName;
  final String? addressLabel;
  final String? addressLine;
  final PriceQuote price;
  final bool hasPrescription;
  final bool canCancel;

  /// Frais dus si la réservation était annulée maintenant, en centimes.
  final int? cancellationFeeIfCancelledNow;

  /// Frais retenus après annulation, en centimes.
  final int? cancellationFee;
  final String? patientNote;

  /// Soignant affecté, dès qu'il y en a un.
  final String? professionalName;
  final String? professionalProfession;

  /// Position du soignant ; présente uniquement pendant son trajet.
  final BookingTracking? tracking;

  /// Le compte rendu de l'intervention peut être lu.
  final bool hasReport;

  bool get isClosed => status == BookingStatus.completed || status == BookingStatus.cancelled;
}
