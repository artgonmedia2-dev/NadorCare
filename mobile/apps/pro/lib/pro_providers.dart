import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

const String routeProfession = '/file/profession';
const String routeFile = '/file';
const String routeZones = '/zones';
const String routeSchedule = '/schedule';

String routeMission(String id) => '/missions/$id';

String routeReport(String missionId) => '/missions/$missionId/report';

final proApiProvider = Provider<ProApi>((ref) => HttpProApi(ref.watch(apiClientProvider)));

typedef PickedDocument = ({Uint8List bytes, String filename});

/// Photo d'un justificatif. L'interface permet de simuler l'appareil photo dans les tests.
abstract interface class DocumentPicker {
  /// Renvoie `null` si l'utilisateur referme sans choisir.
  Future<PickedDocument?> pick({required bool fromCamera});
}

class DeviceDocumentPicker implements DocumentPicker {
  DeviceDocumentPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<PickedDocument?> pick({required bool fromCamera}) async {
    final file = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
      imageQuality: 85,
    );

    if (file == null) {
      return null;
    }

    return (bytes: await file.readAsBytes(), filename: file.name.isEmpty ? 'justificatif.jpg' : file.name);
  }
}

final documentPickerProvider = Provider<DocumentPicker>((ref) => DeviceDocumentPicker());

/// La langue de l'application : les libellés renvoyés par le serveur en dépendent.
String? _language(Ref ref) => ref.watch(settingsControllerProvider.select((settings) => settings.languageCode));

/// Dossier du professionnel connecté. `null` tant qu'il ne l'a pas créé.
/// Chaque action renvoie le dossier à jour, sans nouvel appel de lecture.
class ProfessionalFileController extends AsyncNotifier<ProfessionalFile?> {
  ProApi get _api => ref.read(proApiProvider);

  @override
  Future<ProfessionalFile?> build() {
    _language(ref);
    return _api.file();
  }

  Future<void> reload() async {
    state = const AsyncLoading<ProfessionalFile?>();
    state = await AsyncValue.guard(_api.file);
  }

  /// Relit le dossier sans afficher d'attente : la vérification se fait au back-office,
  /// l'état peut donc changer pendant que l'application est ouverte.
  Future<void> refreshQuietly() async {
    try {
      state = AsyncData<ProfessionalFile?>(await _api.file());
    } on ApiFailure {
      // Hors ligne : on garde l'état affiché.
    }
  }

  Future<void> save({required String categoryId, String? licenseNumber, String? orderNumber}) async {
    _set(await _api.saveFile(categoryId: categoryId, licenseNumber: licenseNumber, orderNumber: orderNumber));
  }

  Future<void> uploadDocument({required String type, required PickedDocument document, String? expiresAt}) async {
    _set(
      await _api.uploadDocument(type: type, bytes: document.bytes, filename: document.filename, expiresAt: expiresAt),
    );
  }

  Future<void> submit() async => _set(await _api.submit());

  Future<void> setZones(List<String> zoneIds) async => _set(await _api.setZones(zoneIds));

  Future<void> setAvailabilities(List<AvailabilitySlot> slots) async => _set(await _api.setAvailabilities(slots));

  Future<void> setOnline({required bool online}) async => _set(await _api.setOnline(online: online));

  void _set(ProfessionalFile file) => state = AsyncData<ProfessionalFile?>(file);
}

// Pas de nouvelle tentative automatique : en cas d'échec, l'écran propose « Réessayer ».
final professionalFileProvider = AsyncNotifierProvider<ProfessionalFileController, ProfessionalFile?>(
  ProfessionalFileController.new,
  retry: (retryCount, error) => null,
);

final professionCategoriesProvider = FutureProvider.autoDispose<List<ProfessionCategory>>(
  (ref) {
    _language(ref);
    return ref.watch(proApiProvider).categories();
  },
  retry: (retryCount, error) => null,
);

final serviceZonesProvider = FutureProvider.autoDispose<List<ServiceZone>>(
  (ref) {
    _language(ref);
    return ref.watch(proApiProvider).zones();
  },
  retry: (retryCount, error) => null,
);

final missionOffersProvider = FutureProvider.autoDispose<List<MissionOffer>>(
  (ref) {
    _language(ref);
    return ref.watch(proApiProvider).offers();
  },
  retry: (retryCount, error) => null,
);

final missionsProvider = FutureProvider.autoDispose<List<Mission>>(
  (ref) {
    _language(ref);
    return ref.watch(proApiProvider).missions();
  },
  retry: (retryCount, error) => null,
);

final missionDetailProvider = FutureProvider.autoDispose.family<Mission, String>(
  (ref, id) {
    _language(ref);
    return ref.watch(proApiProvider).mission(id);
  },
  retry: (retryCount, error) => null,
);

/// Libellé traduit d'un type de justificatif.
String documentTypeLabel(NcLocalizations l10n, String type) {
  return switch (type) {
    'identity' => l10n.docIdentity,
    'diploma' => l10n.docDiploma,
    'practice_authorization' => l10n.docPracticeAuthorization,
    'order_registration' => l10n.docOrderRegistration,
    'rc_insurance' => l10n.docRcInsurance,
    _ => type,
  };
}

String missionStatusLabel(NcLocalizations l10n, String status) {
  return switch (status) {
    'en_route' => l10n.missionStatusEnRoute,
    'in_progress' => l10n.missionStatusInProgress,
    _ => l10n.missionStatusAssigned,
  };
}

/// Étiquette d'état d'une mission : icône et texte, pour ne pas dépendre de la couleur.
NcStatusBadge missionStatusBadge(NcLocalizations l10n, String status) {
  final (IconData icon, NcBadgeTone tone) = switch (status) {
    'en_route' => (Icons.directions_car_outlined, NcBadgeTone.progress),
    'in_progress' => (Icons.medical_services_outlined, NcBadgeTone.success),
    _ => (Icons.event_outlined, NcBadgeTone.neutral),
  };

  return NcStatusBadge(label: missionStatusLabel(l10n, status), icon: icon, tone: tone);
}
