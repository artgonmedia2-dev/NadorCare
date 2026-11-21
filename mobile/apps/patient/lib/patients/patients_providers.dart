import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

import 'location_service.dart';

final patientsApiProvider = Provider<PatientsApi>((ref) => HttpPatientsApi(ref.watch(apiClientProvider)));

final locationServiceProvider = Provider<LocationService>((ref) => const DeviceLocationService());

/// Profils de patients du compte. Chaque écriture met la liste à jour sans nouvel appel.
class ProfilesController extends AsyncNotifier<List<PatientProfile>> {
  PatientsApi get _api => ref.read(patientsApiProvider);

  @override
  Future<List<PatientProfile>> build() => _api.listProfiles();

  Future<void> reload() async {
    state = const AsyncLoading<List<PatientProfile>>();
    state = await AsyncValue.guard(_api.listProfiles);
  }

  Future<void> create(PatientProfileDraft draft) async {
    final created = await _api.createProfile(draft);
    state = AsyncData<List<PatientProfile>>(<PatientProfile>[...?state.value, created]);
  }

  Future<void> save(String id, PatientProfileDraft draft) async {
    final updated = await _api.updateProfile(id, draft);
    state = AsyncData<List<PatientProfile>>(<PatientProfile>[
      for (final profile in state.value ?? const <PatientProfile>[]) profile.id == id ? updated : profile,
    ]);
  }

  Future<void> remove(String id) async {
    await _api.deleteProfile(id);
    state = AsyncData<List<PatientProfile>>(<PatientProfile>[
      for (final profile in state.value ?? const <PatientProfile>[])
        if (profile.id != id) profile,
    ]);
  }
}

// Pas de nouvelle tentative automatique : en cas d'échec, l'écran propose « Réessayer ».
final profilesControllerProvider = AsyncNotifierProvider<ProfilesController, List<PatientProfile>>(
  ProfilesController.new,
  retry: (retryCount, error) => null,
);

/// Adresses du compte.
class AddressesController extends AsyncNotifier<List<PatientAddress>> {
  PatientsApi get _api => ref.read(patientsApiProvider);

  @override
  Future<List<PatientAddress>> build() => _api.listAddresses();

  Future<void> reload() async {
    state = const AsyncLoading<List<PatientAddress>>();
    state = await AsyncValue.guard(_api.listAddresses);
  }

  Future<PatientAddress> create(PatientAddressDraft draft) async {
    final created = await _api.createAddress(draft);
    state = AsyncData<List<PatientAddress>>(<PatientAddress>[...?state.value, created]);
    return created;
  }

  Future<PatientAddress> save(String id, PatientAddressDraft draft) async {
    final updated = await _api.updateAddress(id, draft);
    state = AsyncData<List<PatientAddress>>(<PatientAddress>[
      for (final address in state.value ?? const <PatientAddress>[]) address.id == id ? updated : address,
    ]);
    return updated;
  }

  Future<void> remove(String id) async {
    await _api.deleteAddress(id);
    state = AsyncData<List<PatientAddress>>(<PatientAddress>[
      for (final address in state.value ?? const <PatientAddress>[])
        if (address.id != id) address,
    ]);
  }
}

final addressesControllerProvider = AsyncNotifierProvider<AddressesController, List<PatientAddress>>(
  AddressesController.new,
  retry: (retryCount, error) => null,
);
