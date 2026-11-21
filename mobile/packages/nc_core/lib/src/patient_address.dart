/// Adresse où un soignant se rend.
class PatientAddress {
  const PatientAddress({
    required this.id,
    required this.label,
    required this.line,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.isCovered,
    this.accessNotes,
    this.patientProfileId,
    this.zoneName,
  });

  factory PatientAddress.fromJson(Map<String, dynamic> json) {
    final zone = json['zone'];

    return PatientAddress(
      id: json['id'] as String,
      label: json['label'] as String,
      line: json['line'] as String,
      city: (json['city'] as String?) ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accessNotes: json['access_notes'] as String?,
      patientProfileId: json['patient_profile_id'] as String?,
      zoneName: zone is Map<String, dynamic> ? zone['name'] as String? : null,
      isCovered: (json['is_covered'] as bool?) ?? false,
    );
  }

  final String id;
  final String label;
  final String line;
  final String city;
  final double latitude;
  final double longitude;
  final String? accessNotes;
  final String? patientProfileId;

  /// Nom de la zone, déjà traduit par le serveur. `null` si l'adresse n'est dans aucune zone.
  final String? zoneName;

  /// Vrai si le service est ouvert à cette adresse.
  final bool isCovered;
}

/// Données saisies pour créer ou modifier une adresse.
class PatientAddressDraft {
  const PatientAddressDraft({
    required this.label,
    required this.line,
    required this.latitude,
    required this.longitude,
    this.accessNotes,
  });

  final String label;
  final String line;
  final double latitude;
  final double longitude;
  final String? accessNotes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'label': label,
        'line': line,
        'latitude': latitude,
        'longitude': longitude,
        'access_notes': (accessNotes == null || accessNotes!.isEmpty) ? null : accessNotes,
      };
}
