import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

const String routeFile = '/file';
const String routeSchedule = '/schedule';
const String routeProposeWeek = '/schedule/propose';
const String routeUnavailability = '/schedule/unavailability';

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

  Future<void> uploadDocument({required String type, required PickedDocument document, String? expiresAt}) async {
    _set(
      await _api.uploadDocument(type: type, bytes: document.bytes, filename: document.filename, expiresAt: expiresAt),
    );
  }

  Future<void> submit() async => _set(await _api.submit());

  void _set(ProfessionalFile file) => state = AsyncData<ProfessionalFile?>(file);
}

// Pas de nouvelle tentative automatique : en cas d'échec, l'écran propose « Réessayer ».
final professionalFileProvider = AsyncNotifierProvider<ProfessionalFileController, ProfessionalFile?>(
  ProfessionalFileController.new,
  retry: (retryCount, error) => null,
);

/// Demandes du soignant sur son planning (semaine proposée, indisponibilité).
final scheduleRequestsProvider = FutureProvider.autoDispose<List<ScheduleRequest>>(
  (ref) => ref.watch(proApiProvider).scheduleRequests(),
  retry: (retryCount, error) => null,
);

/// Ordre d'affichage de la semaine : elle commence le lundi. 0 = dimanche … 6 = samedi.
const List<int> orderedWeekdays = <int>[1, 2, 3, 4, 5, 6, 0];

/// Nom du jour dans la langue de l'écran. Le 1er janvier 2023 est un dimanche.
String weekdayName(int weekday, String languageCode) {
  final name = DateFormat.EEEE(languageCode).format(DateTime(2023, 1, 1 + weekday));
  return name.isEmpty ? name : name[0].toUpperCase() + name.substring(1);
}

/// Plages d'un jour, dans l'ordre : « 08:00 à 12:00, 14:00 à 18:00 ».
String weekRanges(NcLocalizations l10n, List<AvailabilitySlot> slots, int weekday) {
  final day = slots.where((slot) => slot.weekday == weekday).toList()
    ..sort((a, b) => a.startTime.compareTo(b.startTime));
  return day.map((slot) => l10n.scheduleRange(slot.startTime, slot.endTime)).join(', ');
}

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

/// Icône d'un type de justificatif.
IconData documentTypeIcon(String type) {
  return switch (type) {
    'identity' => Icons.badge_outlined,
    'diploma' => Icons.school_outlined,
    'practice_authorization' => Icons.verified_outlined,
    'order_registration' => Icons.assignment_ind_outlined,
    'rc_insurance' => Icons.shield_outlined,
    _ => Icons.description_outlined,
  };
}

String missionStatusLabel(NcLocalizations l10n, String status) {
  return switch (status) {
    'en_route' => l10n.missionStatusEnRoute,
    'in_progress' => l10n.missionStatusInProgress,
    _ => l10n.missionStatusAssigned,
  };
}

/// Motifs d'indisponibilité acceptés par le serveur, dans l'ordre d'affichage.
const List<String> declineReasons = <String>['busy', 'sick', 'personal', 'other'];

String declineReasonLabel(NcLocalizations l10n, String reason) {
  return switch (reason) {
    'busy' => l10n.declineReasonBusy,
    'sick' => l10n.declineReasonSick,
    'personal' => l10n.declineReasonPersonal,
    _ => l10n.declineReasonOther,
  };
}

/// Heure limite d'une confirmation, à l'heure du téléphone : c'est un délai pour répondre,
/// pas l'heure du soin. Sur 24 heures et en chiffres latins dans les trois langues, comme
/// les heures de soin.
String confirmDeadline(DateTime confirmBy) {
  final local = confirmBy.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// Étiquette d'une mission qui attend la confirmation du soignant.
NcStatusBadge missionToConfirmBadge(NcLocalizations l10n, Mission mission) {
  final confirmBy = mission.confirmBy;

  return NcStatusBadge(
    label: confirmBy == null ? l10n.missionToConfirm : l10n.missionConfirmBefore(confirmDeadline(confirmBy)),
    icon: Icons.timer_outlined,
    tone: NcBadgeTone.progress,
  );
}

/// Étiquette d'état d'une mission : icône et texte, pour ne pas dépendre de la couleur.
NcStatusBadge missionStatusBadge(NcLocalizations l10n, String status) {
  final (IconData icon, NcBadgeTone tone) = switch (status) {
    'en_route' => (Icons.directions_car_outlined, NcBadgeTone.info),
    'in_progress' => (Icons.medical_services_outlined, NcBadgeTone.success),
    _ => (Icons.event_outlined, NcBadgeTone.brand),
  };

  return NcStatusBadge(label: missionStatusLabel(l10n, status), icon: icon, tone: tone);
}
