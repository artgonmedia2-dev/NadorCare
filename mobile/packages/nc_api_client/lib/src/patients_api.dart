import 'package:nc_core/nc_core.dart';

import 'api_client.dart';

/// Profils de patients et adresses du compte connecté.
abstract interface class PatientsApi {
  Future<List<PatientProfile>> listProfiles();

  /// Fiche détaillée, avec les notes de soin. Le serveur journalise cette lecture.
  Future<PatientProfile> getProfile(String id);

  Future<PatientProfile> createProfile(PatientProfileDraft draft);

  Future<PatientProfile> updateProfile(String id, PatientProfileDraft draft);

  Future<void> deleteProfile(String id);

  Future<List<PatientAddress>> listAddresses();

  Future<PatientAddress> createAddress(PatientAddressDraft draft);

  Future<PatientAddress> updateAddress(String id, PatientAddressDraft draft);

  Future<void> deleteAddress(String id);
}

class HttpPatientsApi implements PatientsApi {
  const HttpPatientsApi(this._client);

  final ApiClient _client;

  static Map<String, dynamic> _data(Map<String, dynamic> json) => json['data'] as Map<String, dynamic>;

  static List<Map<String, dynamic>> _list(Map<String, dynamic> json) {
    return ((json['data'] as List<dynamic>?) ?? const <dynamic>[]).cast<Map<String, dynamic>>();
  }

  @override
  Future<List<PatientProfile>> listProfiles() async {
    return _list(await _client.get('/patient-profiles')).map(PatientProfile.fromJson).toList();
  }

  @override
  Future<PatientProfile> getProfile(String id) async {
    return PatientProfile.fromJson(_data(await _client.get('/patient-profiles/$id')));
  }

  @override
  Future<PatientProfile> createProfile(PatientProfileDraft draft) async {
    return PatientProfile.fromJson(_data(await _client.post('/patient-profiles', draft.toJson())));
  }

  @override
  Future<PatientProfile> updateProfile(String id, PatientProfileDraft draft) async {
    return PatientProfile.fromJson(_data(await _client.patch('/patient-profiles/$id', draft.toJson())));
  }

  @override
  Future<void> deleteProfile(String id) => _client.delete('/patient-profiles/$id');

  @override
  Future<List<PatientAddress>> listAddresses() async {
    return _list(await _client.get('/addresses')).map(PatientAddress.fromJson).toList();
  }

  @override
  Future<PatientAddress> createAddress(PatientAddressDraft draft) async {
    return PatientAddress.fromJson(_data(await _client.post('/addresses', draft.toJson())));
  }

  @override
  Future<PatientAddress> updateAddress(String id, PatientAddressDraft draft) async {
    return PatientAddress.fromJson(_data(await _client.patch('/addresses/$id', draft.toJson())));
  }

  @override
  Future<void> deleteAddress(String id) => _client.delete('/addresses/$id');
}
