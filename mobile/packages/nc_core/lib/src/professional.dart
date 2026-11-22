/// Profession de santé acceptée sur la plateforme.
class ProfessionCategory {
  const ProfessionCategory({
    required this.id,
    required this.name,
    required this.hasOrder,
    required this.requiredDocuments,
  });

  factory ProfessionCategory.fromJson(Map<String, dynamic> json) {
    return ProfessionCategory(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      hasOrder: (json['has_order'] as bool?) ?? false,
      requiredDocuments: _strings(json['required_documents']),
    );
  }

  final String id;
  final String name;

  /// La profession a un Ordre : le numéro d'inscription est demandé.
  final bool hasOrder;
  final List<String> requiredDocuments;
}

/// Zone desservie.
class ServiceZone {
  const ServiceZone({required this.id, required this.name});

  factory ServiceZone.fromJson(Map<String, dynamic> json) {
    return ServiceZone(id: json['id'] as String, name: (json['name'] as String?) ?? '');
  }

  final String id;
  final String name;
}

/// État de la vérification d'un dossier. Les valeurs sont celles de l'API.
enum VerificationStatus {
  draft('draft'),
  submitted('submitted'),
  underReview('under_review'),
  verified('verified'),
  rejected('rejected'),
  suspended('suspended');

  const VerificationStatus(this.apiValue);

  final String apiValue;

  static VerificationStatus fromApi(String? value) {
    return VerificationStatus.values.firstWhere(
      (status) => status.apiValue == value,
      orElse: () => VerificationStatus.draft,
    );
  }

  /// Le professionnel peut encore modifier son dossier et le soumettre.
  bool get isEditable => this == draft || this == rejected;

  bool get isWaiting => this == submitted || this == underReview;
}

/// Justificatif déposé, avec le résultat de son contrôle.
class ProfessionalDocument {
  const ProfessionalDocument({required this.type, required this.status, this.expiresAt, this.rejectionReason});

  factory ProfessionalDocument.fromJson(Map<String, dynamic> json) {
    final expires = json['expires_at'] as String?;

    return ProfessionalDocument(
      type: json['type'] as String,
      status: (json['status'] as String?) ?? 'pending',
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
      rejectionReason: json['rejection_reason'] as String?,
    );
  }

  /// `identity`, `diploma`, `practice_authorization`, `order_registration` ou `rc_insurance`.
  final String type;

  /// `pending`, `approved`, `rejected` ou `expired`.
  final String status;
  final DateTime? expiresAt;
  final String? rejectionReason;
}

/// Plage de l'agenda hebdomadaire, heures de Nador. [weekday] : 0 = dimanche … 6 = samedi.
class AvailabilitySlot {
  const AvailabilitySlot({required this.weekday, required this.startTime, required this.endTime});

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      weekday: (json['weekday'] as num).toInt(),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
    );
  }

  final int weekday;

  /// `HH:MM`.
  final String startTime;
  final String endTime;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'weekday': weekday,
        'start_time': startTime,
        'end_time': endTime,
      };
}

/// Dossier du professionnel connecté.
class ProfessionalFile {
  const ProfessionalFile({
    required this.status,
    required this.categoryId,
    required this.categoryName,
    required this.isOnline,
    required this.requiredDocuments,
    required this.missingDocuments,
    required this.documents,
    required this.canSubmit,
    required this.zones,
    required this.availabilities,
    this.statusReason,
    this.licenseNumber,
    this.orderNumber,
  });

  factory ProfessionalFile.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return ProfessionalFile(
      status: VerificationStatus.fromApi(json['verification_status'] as String?),
      statusReason: json['status_reason'] as String?,
      categoryId: (category['id'] as String?) ?? '',
      categoryName: (category['name'] as String?) ?? '',
      licenseNumber: json['license_number'] as String?,
      orderNumber: json['order_number'] as String?,
      isOnline: (json['is_online'] as bool?) ?? false,
      requiredDocuments: _strings(json['required_documents']),
      missingDocuments: _strings(json['missing_documents']),
      documents: _maps(json['documents']).map(ProfessionalDocument.fromJson).toList(growable: false),
      canSubmit: (json['can_submit'] as bool?) ?? false,
      zones: _maps(json['zones']).map(ServiceZone.fromJson).toList(growable: false),
      availabilities: _maps(json['availabilities']).map(AvailabilitySlot.fromJson).toList(growable: false),
    );
  }

  final VerificationStatus status;

  /// Motif du refus ou de la suspension.
  final String? statusReason;
  final String categoryId;
  final String categoryName;
  final String? licenseNumber;
  final String? orderNumber;
  final bool isOnline;
  final List<String> requiredDocuments;
  final List<String> missingDocuments;

  /// Dépôt le plus récent de chaque type.
  final List<ProfessionalDocument> documents;
  final bool canSubmit;
  final List<ServiceZone> zones;
  final List<AvailabilitySlot> availabilities;

  ProfessionalDocument? documentOf(String type) {
    for (final document in documents) {
      if (document.type == type) {
        return document;
      }
    }
    return null;
  }
}

/// Proposition de mission. Avant d'accepter, le professionnel ne voit que le soin,
/// le créneau, la zone et la distance.
class MissionOffer {
  const MissionOffer({
    required this.id,
    required this.serviceName,
    required this.durationMinutes,
    required this.scheduledDate,
    required this.scheduledTime,
    this.expiresAt,
    this.zone,
    this.distanceMeters,
  });

  factory MissionOffer.fromJson(Map<String, dynamic> json) {
    final service = (json['service'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final expires = json['expires_at'] as String?;

    return MissionOffer(
      id: json['id'] as String,
      serviceName: (service['name'] as String?) ?? '',
      durationMinutes: (service['duration_minutes'] as num?)?.toInt() ?? 0,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: (json['scheduled_time'] as String?) ?? '',
      expiresAt: expires == null ? null : DateTime.tryParse(expires),
      zone: json['zone'] as String?,
      distanceMeters: (json['distance_meters'] as num?)?.toInt(),
    );
  }

  final String id;
  final String serviceName;
  final int durationMinutes;

  /// Jour et heure du soin à Nador.
  final DateTime scheduledDate;
  final String scheduledTime;

  /// Moment après lequel la proposition n'est plus valable.
  final DateTime? expiresAt;
  final String? zone;
  final int? distanceMeters;
}

/// Mission affectée au professionnel. Les données de santé ([careNotes], [patientNote])
/// ne sont présentes que dans la fiche détaillée, dont la lecture est journalisée.
class Mission {
  const Mission({
    required this.id,
    required this.reference,
    required this.status,
    required this.serviceName,
    required this.durationMinutes,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.patientName,
    required this.amountToCollect,
    required this.hasPrescription,
    this.addressLine,
    this.city,
    this.accessNotes,
    this.careNotes,
    this.patientNote,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    final service = (json['service'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final patient = (json['patient'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final address = (json['address'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return Mission(
      id: json['id'] as String,
      reference: (json['reference'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'assigned',
      serviceName: (service['name'] as String?) ?? '',
      durationMinutes: (service['duration_minutes'] as num?)?.toInt() ?? 0,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      scheduledTime: (json['scheduled_time'] as String?) ?? '',
      patientName: '${patient['first_name'] ?? ''} ${patient['last_name'] ?? ''}'.trim(),
      careNotes: patient['care_notes'] as String?,
      addressLine: address['line'] as String?,
      city: address['city'] as String?,
      accessNotes: address['access_notes'] as String?,
      amountToCollect: (json['amount_to_collect'] as num?)?.toInt() ?? 0,
      hasPrescription: (json['has_prescription'] as bool?) ?? false,
      patientNote: json['patient_note'] as String?,
    );
  }

  final String id;
  final String reference;

  /// `assigned`, `en_route` ou `in_progress`.
  final String status;
  final String serviceName;
  final int durationMinutes;
  final DateTime scheduledDate;
  final String scheduledTime;
  final String patientName;
  final String? addressLine;
  final String? city;
  final String? accessNotes;

  /// Informations utiles au soin (allergies, mobilité…).
  final String? careNotes;
  final String? patientNote;

  /// Montant à encaisser en espèces, en centimes.
  final int amountToCollect;
  final bool hasPrescription;

  /// Le professionnel peut encore se désister : il n'est pas parti.
  bool get canWithdraw => status == 'assigned';
}

List<String> _strings(Object? value) {
  return ((value as List<dynamic>?) ?? const <dynamic>[]).map((item) => item.toString()).toList(growable: false);
}

List<Map<String, dynamic>> _maps(Object? value) {
  return ((value as List<dynamic>?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
}
