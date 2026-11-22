/// Constantes relevées pendant un soin, avec leurs bornes plausibles (les mêmes que
/// celles du serveur) : une faute de frappe est refusée avant l'envoi.
enum Vital {
  /// Tension systolique, mmHg.
  systolic(50, 260),

  /// Tension diastolique, mmHg.
  diastolic(30, 160),

  /// Pouls, battements par minute.
  pulse(20, 250),

  /// Température, °C.
  temperature(30, 44),

  /// Glycémie, g/L.
  glucose(0.1, 9),

  /// Saturation en oxygène, %.
  spo2(50, 100);

  const Vital(this.min, this.max);

  final num min;
  final num max;

  /// La température et la glycémie se saisissent avec des décimales.
  bool get isDecimal => this == Vital.temperature || this == Vital.glucose;

  bool accepts(num value) => value >= min && value <= max;
}

/// Acte réalisé ou consommable utilisé.
class ReportLine {
  const ReportLine({required this.label, this.quantity = 1, this.referenceId});

  factory ReportLine.fromJson(Map<String, dynamic> json, {required String referenceKey}) {
    return ReportLine(
      label: (json['label'] as String?) ?? '',
      quantity: (json['quantity'] as num?) ?? 1,
      referenceId: json[referenceKey] as String?,
    );
  }

  final String label;
  final num quantity;

  /// Identifiant dans le référentiel ; `null` pour une saisie libre.
  final String? referenceId;

  Map<String, dynamic> toJson({required String referenceKey}) => <String, dynamic>{
        referenceKey: referenceId,
        'label': label,
        'quantity': quantity,
      };
}

/// Compte rendu à enregistrer en brouillon.
class ReportDraft {
  const ReportDraft({
    this.vitals = const <Vital, num>{},
    this.observations,
    this.acts = const <ReportLine>[],
    this.consumables = const <ReportLine>[],
  });

  final Map<Vital, num> vitals;
  final String? observations;
  final List<ReportLine> acts;
  final List<ReportLine> consumables;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'vitals': <String, num>{for (final entry in vitals.entries) entry.key.name: entry.value},
        'observations': (observations == null || observations!.isEmpty) ? null : observations,
        'acts': <Map<String, dynamic>>[for (final act in acts) act.toJson(referenceKey: 'act_id')],
        'consumables': <Map<String, dynamic>>[
          for (final item in consumables) item.toJson(referenceKey: 'consumable_id'),
        ],
      };
}

/// Intervention et son compte rendu (version qui fait foi). Données de santé : le serveur
/// journalise chaque lecture.
class Intervention {
  const Intervention({
    required this.id,
    required this.bookingId,
    required this.status,
    this.vitals = const <Vital, num>{},
    this.observations,
    this.signedByName,
    this.isSigned = false,
    this.photosCount = 0,
    this.version = 1,
    this.validatedAt,
    this.amendmentReason,
    this.acts = const <ReportLine>[],
    this.consumables = const <ReportLine>[],
  });

  factory Intervention.fromJson(Map<String, dynamic> json) {
    final report = (json['report'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    // Sans constante, le serveur renvoie un objet vide (ou une liste vide selon l'encodage).
    final rawVitals = report['vitals'];
    final vitals = <Vital, num>{};
    if (rawVitals is Map<String, dynamic>) {
      for (final vital in Vital.values) {
        final value = rawVitals[vital.name];
        if (value is num) {
          vitals[vital] = value;
        }
      }
    }
    final validated = report['validated_at'] as String?;

    return Intervention(
      id: json['id'] as String,
      bookingId: (json['booking_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'in_progress',
      vitals: vitals,
      observations: report['observations'] as String?,
      signedByName: report['signed_by_name'] as String?,
      isSigned: (report['is_signed'] as bool?) ?? false,
      photosCount: (report['photos_count'] as num?)?.toInt() ?? 0,
      version: (report['version'] as num?)?.toInt() ?? 1,
      validatedAt: validated == null ? null : DateTime.tryParse(validated),
      amendmentReason: report['amendment_reason'] as String?,
      acts: _lines(json['acts'], 'act_id'),
      consumables: _lines(json['consumables'], 'consumable_id'),
    );
  }

  static List<ReportLine> _lines(Object? value, String referenceKey) {
    return ((value as List<dynamic>?) ?? const <dynamic>[])
        .map((item) => ReportLine.fromJson(item as Map<String, dynamic>, referenceKey: referenceKey))
        .toList(growable: false);
  }

  final String id;
  final String bookingId;

  /// `in_progress` tant que le compte rendu n'est pas validé, puis `validated`.
  final String status;
  final Map<Vital, num> vitals;
  final String? observations;
  final String? signedByName;
  final bool isSigned;
  final int photosCount;

  /// 1 pour l'original ; au-delà, le compte rendu a été corrigé par un avenant.
  final int version;
  final DateTime? validatedAt;
  final String? amendmentReason;
  final List<ReportLine> acts;
  final List<ReportLine> consumables;

  bool get isValidated => status == 'validated';

  bool get isAmended => version > 1;
}
