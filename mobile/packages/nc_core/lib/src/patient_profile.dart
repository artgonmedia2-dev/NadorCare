/// Lien entre le titulaire du compte et le patient. La valeur est celle de l'API.
enum PatientRelationship {
  self('self'),
  parent('parent'),
  child('child'),
  spouse('spouse'),
  other('other');

  const PatientRelationship(this.apiValue);

  final String apiValue;

  static PatientRelationship fromApi(String? value) {
    return PatientRelationship.values.firstWhere(
      (relationship) => relationship.apiValue == value,
      orElse: () => PatientRelationship.other,
    );
  }
}

/// Profil d'un patient géré par le compte (soi-même, un parent, un enfant).
class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.relationship,
    this.birthDate,
    this.sex,
    this.phone,
    this.hasCareNotes = false,
    this.careNotes,
  });

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    final birthDate = json['birth_date'] as String?;

    return PatientProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      relationship: PatientRelationship.fromApi(json['relationship'] as String?),
      birthDate: birthDate == null ? null : DateTime.tryParse(birthDate),
      sex: json['sex'] as String?,
      phone: json['phone'] as String?,
      hasCareNotes: (json['has_care_notes'] as bool?) ?? false,
      careNotes: json['care_notes'] as String?,
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final PatientRelationship relationship;
  final DateTime? birthDate;

  /// `female`, `male` ou `null`.
  final String? sex;
  final String? phone;

  /// Vrai si des notes de soin existent. Les notes elles-mêmes ([careNotes]) ne sont
  /// renvoyées que par la fiche détaillée, dont la lecture est journalisée par le serveur.
  final bool hasCareNotes;
  final String? careNotes;

  String get fullName => '$firstName $lastName'.trim();
}

/// Données saisies pour créer ou modifier un profil.
class PatientProfileDraft {
  const PatientProfileDraft({
    required this.firstName,
    required this.lastName,
    required this.relationship,
    this.birthDate,
    this.sex,
    this.phone,
    this.careNotes,
  });

  final String firstName;
  final String lastName;
  final PatientRelationship relationship;
  final DateTime? birthDate;
  final String? sex;
  final String? phone;
  final String? careNotes;

  /// Les champs vides partent en `null` : c'est ainsi qu'on efface une valeur.
  Map<String, dynamic> toJson() {
    final date = birthDate;

    return <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'relationship': relationship.apiValue,
      'birth_date': date == null
          ? null
          : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
      'sex': sex,
      'phone': (phone == null || phone!.isEmpty) ? null : phone,
      'care_notes': (careNotes == null || careNotes!.isEmpty) ? null : careNotes,
    };
  }
}
