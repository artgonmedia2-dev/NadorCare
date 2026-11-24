import 'dart:typed_data';

import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Points d'accès de l'application professionnel : dossier, disponibilités, missions.
abstract interface class ProApi {
  Future<List<ProfessionCategory>> categories();

  /// Dossier du soignant. Il est créé par l'agence ; `null` si le compte n'est pas rattaché à l'équipe.
  Future<ProfessionalFile?> file();

  /// Dépose un justificatif. [expiresAt] (`AAAA-MM-JJ`) est obligatoire pour l'assurance.
  Future<ProfessionalFile> uploadDocument({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? expiresAt,
  });

  Future<ProfessionalFile> submit();

  /// Mes demandes de planning, de la plus récente à la plus ancienne.
  Future<List<ScheduleRequest>> scheduleRequests();

  /// Propose une nouvelle semaine type : elle ne s'applique que si la coordination l'accepte.
  Future<ScheduleRequest> proposeWeek(List<AvailabilitySlot> slots, {String? note});

  /// Signale une indisponibilité, du premier au dernier jour compris.
  Future<ScheduleRequest> reportUnavailability({required DateTime startsOn, required DateTime endsOn, String? note});

  /// Retire une demande qui n'a pas encore reçu de réponse.
  Future<void> cancelScheduleRequest(String id);

  Future<List<Mission>> missions();

  /// Fiche détaillée, avec les données de santé utiles. Le serveur journalise cette lecture.
  Future<Mission> mission(String id);

  /// Confirme la prise en charge d'une mission que la coordination vient d'affecter.
  Future<Mission> confirmMission(String missionId);

  /// Signale une indisponibilité, tant que le soignant n'est pas parti. [reason] : `busy`,
  /// `sick`, `personal` ou `other` (une précision est alors obligatoire).
  Future<void> declineMission(String missionId, {required String reason, String? note});

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

  static ScheduleRequest _scheduleRequest(Map<String, dynamic> json) => ScheduleRequest.fromJson(_data(json));

  /// Jour au format de l'API : `AAAA-MM-JJ`.
  static String _day(DateTime day) {
    return '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<List<ProfessionCategory>> categories() async {
    return _list(await _client.get('/catalogue/professional-categories')).map(ProfessionCategory.fromJson).toList();
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
  Future<List<ScheduleRequest>> scheduleRequests() async {
    return _list(await _client.get('/pro/schedule-requests')).map(ScheduleRequest.fromJson).toList();
  }

  @override
  Future<ScheduleRequest> proposeWeek(List<AvailabilitySlot> slots, {String? note}) async {
    return _scheduleRequest(
      await _client.post('/pro/schedule-requests', <String, dynamic>{
        'kind': ScheduleRequest.kindWeekly,
        'slots': <Map<String, dynamic>>[for (final slot in slots) slot.toJson()],
        'note': (note == null || note.isEmpty) ? null : note,
      }),
    );
  }

  @override
  Future<ScheduleRequest> reportUnavailability({
    required DateTime startsOn,
    required DateTime endsOn,
    String? note,
  }) async {
    return _scheduleRequest(
      await _client.post('/pro/schedule-requests', <String, dynamic>{
        'kind': ScheduleRequest.kindUnavailability,
        'starts_on': _day(startsOn),
        'ends_on': _day(endsOn),
        'note': (note == null || note.isEmpty) ? null : note,
      }),
    );
  }

  @override
  Future<void> cancelScheduleRequest(String id) => _client.delete('/pro/schedule-requests/$id');

  @override
  Future<List<Mission>> missions() async {
    return _list(await _client.get('/pro/missions')).map(Mission.fromJson).toList();
  }

  @override
  Future<Mission> mission(String id) async => Mission.fromJson(_data(await _client.get('/pro/missions/$id')));

  @override
  Future<Mission> confirmMission(String missionId) async {
    return Mission.fromJson(_data(await _client.post('/pro/missions/$missionId/confirm')));
  }

  @override
  Future<void> declineMission(String missionId, {required String reason, String? note}) async {
    await _client.post('/pro/missions/$missionId/decline', <String, dynamic>{
      'reason': reason,
      'note': (note == null || note.isEmpty) ? null : note,
    });
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
