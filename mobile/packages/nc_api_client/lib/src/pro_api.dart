import 'dart:typed_data';

import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Points d'accès de l'application professionnel : dossier, disponibilités, missions.
abstract interface class ProApi {
  Future<List<ProfessionCategory>> categories();

  Future<List<ServiceZone>> zones();

  /// Dossier du professionnel, ou `null` s'il ne l'a pas encore créé.
  Future<ProfessionalFile?> file();

  Future<ProfessionalFile> saveFile({required String categoryId, String? licenseNumber, String? orderNumber});

  /// Dépose un justificatif. [expiresAt] (`AAAA-MM-JJ`) est obligatoire pour l'assurance.
  Future<ProfessionalFile> uploadDocument({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? expiresAt,
  });

  Future<ProfessionalFile> submit();

  Future<ProfessionalFile> setZones(List<String> zoneIds);

  Future<ProfessionalFile> setAvailabilities(List<AvailabilitySlot> slots);

  Future<ProfessionalFile> setOnline({required bool online});

  Future<List<MissionOffer>> offers();

  /// Accepte une proposition : la mission est alors affectée.
  Future<Mission> acceptOffer(String offerId);

  Future<void> declineOffer(String offerId, {String? reason});

  Future<List<Mission>> missions();

  /// Fiche détaillée, avec les données de santé utiles. Le serveur journalise cette lecture.
  Future<Mission> mission(String id);

  /// Se désister d'une mission, tant que le professionnel n'est pas parti.
  Future<void> withdraw(String missionId, {required String reason});

  /// Départ vers le domicile : la mission passe « en route ».
  Future<Mission> depart(String missionId);

  /// Envoie la position pendant le trajet. Renvoie la durée restante estimée, en secondes.
  Future<int?> sendLocation(String missionId, {required double latitude, required double longitude});

  /// Pointage d'arrivée : la mission passe « en cours » et le compte rendu s'ouvre.
  Future<Intervention> arrive(String missionId, {double? latitude, double? longitude});

  /// Démarre une téléconsultation : la mission passe « en cours », sans trajet.
  Future<Intervention> startTeleconsultation(String missionId);

  /// Accès du professionnel à la salle vidéo d'une téléconsultation.
  Future<VideoAccess> teleconsultation(String missionId);

  /// Compte rendu en cours d'une mission. Le serveur journalise cette lecture.
  Future<Intervention> intervention(String missionId);

  Future<Intervention> saveReport(String missionId, ReportDraft draft);

  Future<Intervention> addReportPhoto(String missionId, {required Uint8List bytes, required String filename});

  /// Signature tracée à l'écran (PNG) et nom de la personne qui signe.
  Future<Intervention> signReport(String missionId, {required Uint8List png, required String signedByName});

  /// Termine l'intervention : le compte rendu est validé et n'est plus modifiable.
  Future<Intervention> complete(String missionId, {required bool cashCollected});
}

class HttpProApi implements ProApi {
  const HttpProApi(this._client);

  static const String profileRequired = 'professional_profile_required';

  final ApiClient _client;

  static Map<String, dynamic> _data(Map<String, dynamic> json) => json['data'] as Map<String, dynamic>;

  static List<Map<String, dynamic>> _list(Map<String, dynamic> json) {
    return ((json['data'] as List<dynamic>?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
  }

  static ProfessionalFile _file(Map<String, dynamic> json) => ProfessionalFile.fromJson(_data(json));

  @override
  Future<List<ProfessionCategory>> categories() async {
    return _list(await _client.get('/catalogue/professional-categories')).map(ProfessionCategory.fromJson).toList();
  }

  @override
  Future<List<ServiceZone>> zones() async {
    return _list(await _client.get('/catalogue/zones')).map(ServiceZone.fromJson).toList();
  }

  @override
  Future<ProfessionalFile?> file() async {
    try {
      return _file(await _client.get('/pro/profile'));
    } on ApiFailure catch (failure) {
      // Pas encore de dossier : ce n'est pas une erreur, c'est le point de départ.
      if (failure.code == profileRequired) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<ProfessionalFile> saveFile({required String categoryId, String? licenseNumber, String? orderNumber}) async {
    return _file(
      await _client.put('/pro/profile', <String, dynamic>{
        'professional_category_id': categoryId,
        'license_number': (licenseNumber == null || licenseNumber.isEmpty) ? null : licenseNumber,
        'order_number': (orderNumber == null || orderNumber.isEmpty) ? null : orderNumber,
      }),
    );
  }

  @override
  Future<ProfessionalFile> uploadDocument({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? expiresAt,
  }) async {
    return _file(
      await _client.upload(
        '/pro/profile/documents',
        field: 'file',
        bytes: bytes,
        filename: filename,
        fields: <String, String>{'type': type, 'expires_at': ?expiresAt},
      ),
    );
  }

  @override
  Future<ProfessionalFile> submit() async => _file(await _client.post('/pro/profile/submit'));

  @override
  Future<ProfessionalFile> setZones(List<String> zoneIds) async {
    return _file(await _client.put('/pro/profile/zones', <String, dynamic>{'zone_ids': zoneIds}));
  }

  @override
  Future<ProfessionalFile> setAvailabilities(List<AvailabilitySlot> slots) async {
    return _file(
      await _client.put('/pro/profile/availabilities', <String, dynamic>{
        'availabilities': <Map<String, dynamic>>[for (final slot in slots) slot.toJson()],
      }),
    );
  }

  @override
  Future<ProfessionalFile> setOnline({required bool online}) async {
    return _file(await _client.put('/pro/profile/online', <String, dynamic>{'is_online': online}));
  }

  @override
  Future<List<MissionOffer>> offers() async {
    return _list(await _client.get('/pro/offers')).map(MissionOffer.fromJson).toList();
  }

  @override
  Future<Mission> acceptOffer(String offerId) async {
    return Mission.fromJson(_data(await _client.post('/pro/offers/$offerId/accept')));
  }

  @override
  Future<void> declineOffer(String offerId, {String? reason}) async {
    await _client.post('/pro/offers/$offerId/decline', <String, dynamic>{'reason': ?reason});
  }

  @override
  Future<List<Mission>> missions() async {
    return _list(await _client.get('/pro/missions')).map(Mission.fromJson).toList();
  }

  @override
  Future<Mission> mission(String id) async => Mission.fromJson(_data(await _client.get('/pro/missions/$id')));

  @override
  Future<void> withdraw(String missionId, {required String reason}) async {
    await _client.post('/pro/missions/$missionId/withdraw', <String, dynamic>{'reason': reason});
  }

  static Intervention _intervention(Map<String, dynamic> json) => Intervention.fromJson(_data(json));

  @override
  Future<Mission> depart(String missionId) async {
    return Mission.fromJson(_data(await _client.post('/pro/missions/$missionId/depart')));
  }

  @override
  Future<int?> sendLocation(String missionId, {required double latitude, required double longitude}) async {
    final json = await _client.post('/pro/missions/$missionId/location', <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
    });
    return (_data(json)['eta_seconds'] as num?)?.toInt();
  }

  @override
  Future<Intervention> arrive(String missionId, {double? latitude, double? longitude}) async {
    return _intervention(
      await _client.post('/pro/missions/$missionId/arrive', <String, dynamic>{
        'latitude': ?latitude,
        'longitude': ?longitude,
      }),
    );
  }

  @override
  Future<Intervention> startTeleconsultation(String missionId) async {
    return _intervention(await _client.post('/pro/missions/$missionId/start'));
  }

  @override
  Future<VideoAccess> teleconsultation(String missionId) async {
    final json = await _client.get('/pro/missions/$missionId/teleconsultation');
    return VideoAccess.fromJson(json['data'] as Map<String, dynamic>);
  }

  @override
  Future<Intervention> intervention(String missionId) async {
    return _intervention(await _client.get('/pro/missions/$missionId/intervention'));
  }

  @override
  Future<Intervention> saveReport(String missionId, ReportDraft draft) async {
    return _intervention(await _client.put('/pro/missions/$missionId/report', draft.toJson()));
  }

  @override
  Future<Intervention> addReportPhoto(String missionId, {required Uint8List bytes, required String filename}) async {
    return _intervention(
      await _client.upload('/pro/missions/$missionId/report/photos', field: 'file', bytes: bytes, filename: filename),
    );
  }

  @override
  Future<Intervention> signReport(String missionId, {required Uint8List png, required String signedByName}) async {
    return _intervention(
      await _client.upload(
        '/pro/missions/$missionId/report/signature',
        field: 'file',
        bytes: png,
        filename: 'signature.png',
        fields: <String, String>{'signed_by_name': signedByName},
      ),
    );
  }

  @override
  Future<Intervention> complete(String missionId, {required bool cashCollected}) async {
    return _intervention(
      await _client.post('/pro/missions/$missionId/complete', <String, dynamic>{'cash_collected': cashCollected}),
    );
  }
}
