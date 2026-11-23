/// Catégorie du catalogue. Le nom est déjà traduit par le serveur.
class CareCategory {
  const CareCategory({required this.slug, required this.name, required this.servicesCount, this.icon});

  factory CareCategory.fromJson(Map<String, dynamic> json) {
    return CareCategory(
      slug: json['slug'] as String,
      name: (json['name'] as String?) ?? '',
      icon: json['icon'] as String?,
      servicesCount: (json['services_count'] as num?)?.toInt() ?? 0,
    );
  }

  final String slug;
  final String name;
  final String? icon;
  final int servicesCount;
}

/// Soin proposé à domicile. Les textes sont déjà traduits par le serveur.
class CareService {
  const CareService({
    required this.id,
    required this.slug,
    required this.name,
    required this.durationMinutes,
    required this.priceAmount,
    required this.requiresPrescription,
    required this.allowsSeries,
    required this.categorySlug,
    required this.categoryName,
    this.description,
    this.professionalCategory,
    this.currency = 'MAD',
    this.isRemote = false,
  });

  factory CareService.fromJson(Map<String, dynamic> json) {
    final price = (json['price'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final category = (json['category'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    return CareService(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      priceAmount: (price['amount'] as num?)?.toInt() ?? 0,
      currency: (price['currency'] as String?) ?? 'MAD',
      requiresPrescription: (json['requires_prescription'] as bool?) ?? false,
      allowsSeries: (json['allows_series'] as bool?) ?? false,
      categorySlug: (category['slug'] as String?) ?? '',
      categoryName: (category['name'] as String?) ?? '',
      professionalCategory: json['professional_category'] as String?,
      isRemote: json['delivery_mode'] == 'remote',
    );
  }

  final String id;
  final String slug;
  final String name;
  final String? description;
  final int durationMinutes;

  /// Tarif indicatif en centimes, hors majorations.
  final int priceAmount;
  final String currency;

  /// Une ordonnance devra être déposée pour réserver ce soin.
  final bool requiresPrescription;
  final bool allowsSeries;

  /// Téléconsultation : le soin se fait par appel vidéo, sans déplacement.
  final bool isRemote;
  final String categorySlug;
  final String categoryName;

  /// Profession du soignant qui réalise le soin.
  final String? professionalCategory;
}
