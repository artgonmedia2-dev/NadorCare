import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nadorcare_pro/home_screen.dart';
import 'package:nadorcare_pro/main.dart';
import 'package:nadorcare_pro/missions/signature_screen.dart';
import 'package:nadorcare_pro/pro_providers.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

final NcLocalizations fr = lookupNcLocalizations(const Locale('fr'));
final NcLocalizations ar = lookupNcLocalizations(const Locale('ar'));

const AppUser _user = AppUser(
  id: '01PRO',
  phone: '+212600000101',
  name: 'Samira',
  locale: 'fr',
  status: 'active',
  roles: <String>['professionnel'],
);

const ProfessionCategory nurse = ProfessionCategory(
  id: 'C1',
  name: 'Infirmier',
  hasOrder: false,
  requiredDocuments: <String>['identity', 'diploma', 'practice_authorization', 'rc_insurance'],
);

/// Profession telle que l'agence la règle : l'assurance personnelle n'est plus exigée.
const ProfessionCategory careAssistant = ProfessionCategory(
  id: 'C3',
  name: 'Aide-soignant',
  hasOrder: false,
  requiredDocuments: <String>['identity', 'diploma', 'practice_authorization'],
);

const ProfessionCategory doctor = ProfessionCategory(
  id: 'C2',
  name: 'Médecin généraliste',
  hasOrder: true,
  requiredDocuments: <String>['identity', 'diploma', 'practice_authorization', 'order_registration', 'rc_insurance'],
);

const List<ServiceZone> allZones = <ServiceZone>[
  ServiceZone(id: 'Z1', name: 'Nador centre'),
  ServiceZone(id: 'Z2', name: 'Beni Ensar'),
];

Mission buildMission(
  String id, {
  String status = 'assigned',
  bool detailed = false,
  bool remote = false,
  bool toConfirm = false,
}) =>
    Mission(
      id: id,
      reference: 'NC-2026-000042',
      status: status,
      serviceName: 'Pansement',
      durationMinutes: 30,
      scheduledDate: DateTime(2026, 12, 8),
      scheduledTime: '10:00',
      patientName: 'Aïcha Benali',
      addressLine: '12 rue Al Massira',
      city: 'Nador',
      accessNotes: 'Porte verte, 2e étage',
      careNotes: detailed ? 'Allergie à la pénicilline' : null,
      patientNote: detailed ? 'Sonner deux fois' : null,
      amountToCollect: 10000,
      hasPrescription: true,
      isRemote: remote,
      needsConfirmation: toConfirm,
      // Heure du téléphone : c'est un délai pour répondre, pas l'heure du soin.
      confirmBy: toConfirm ? DateTime(2026, 12, 7, 12, 30) : null,
    );

/// Imite le serveur pour le dossier et les missions.
class FakeProApi implements ProApi {
  FakeProApi({this.status, this.statusReason});

  VerificationStatus? status;
  String? statusReason;
  ProfessionCategory category = nurse;
  String? licenseNumber;
  final Map<String, ProfessionalDocument> documents = <String, ProfessionalDocument>{};
  List<ServiceZone> zonesChosen = <ServiceZone>[];
  List<AvailabilitySlot> slots = <AvailabilitySlot>[];

  /// Demandes de planning, de la plus ancienne à la plus récente.
  final List<ScheduleRequest> requests = <ScheduleRequest>[];
  final List<Mission> activeMissions = <Mission>[];

  ApiFailure? fileFailure;
  ApiFailure? confirmFailure;
  int missionsCalls = 0;
  final List<String> confirmed = <String>[];
  final List<String> detailReads = <String>[];
  final List<({String id, String reason, String? note})> declines = [];

  ProfessionalFile _file() {
    final missing = category.requiredDocuments
        .where((type) => !<String>['pending', 'approved'].contains(documents[type]?.status))
        .toList();

    return ProfessionalFile(
      status: status!,
      statusReason: statusReason,
      categoryId: category.id,
      categoryName: category.name,
      licenseNumber: licenseNumber,
      requiredDocuments: category.requiredDocuments,
      missingDocuments: missing,
      // Comme le serveur : l'assurance est facultative quand la profession ne l'exige pas.
      optionalDocuments: category.requiredDocuments.contains('rc_insurance') ? const <String>[] : const <String>['rc_insurance'],
      documents: documents.values.toList(),
      canSubmit: status!.isEditable && missing.isEmpty,
      zones: zonesChosen,
      availabilities: slots,
    );
  }

  @override
  Future<List<ProfessionCategory>> categories() async => const <ProfessionCategory>[nurse, doctor];

  @override
  Future<ProfessionalFile?> file() async {
    if (fileFailure != null) {
      throw fileFailure!;
    }
    return status == null ? null : _file();
  }

  @override
  Future<ProfessionalFile> uploadDocument({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? expiresAt,
  }) async {
    documents[type] = ProfessionalDocument(
      type: type,
      status: 'pending',
      expiresAt: expiresAt == null ? null : DateTime.parse(expiresAt),
    );
    return _file();
  }

  @override
  Future<ProfessionalFile> submit() async {
    status = VerificationStatus.submitted;
    statusReason = null;
    return _file();
  }

  @override
  Future<List<ScheduleRequest>> scheduleRequests() async => requests.reversed.toList();

  @override
  Future<ScheduleRequest> proposeWeek(List<AvailabilitySlot> slots, {String? note}) async {
    final request = ScheduleRequest(
      id: 'R${requests.length + 1}',
      kind: ScheduleRequest.kindWeekly,
      status: ScheduleRequest.statusPending,
      slots: slots,
      note: note,
    );
    requests.add(request);
    return request;
  }

  @override
  Future<ScheduleRequest> reportUnavailability({
    required DateTime startsOn,
    required DateTime endsOn,
    String? note,
  }) async {
    final request = ScheduleRequest(
      id: 'R${requests.length + 1}',
      kind: ScheduleRequest.kindUnavailability,
      status: ScheduleRequest.statusPending,
      startsOn: startsOn,
      endsOn: endsOn,
      note: (note == null || note.isEmpty) ? null : note,
    );
    requests.add(request);
    return request;
  }

  @override
  Future<void> cancelScheduleRequest(String id) async {
    final index = requests.indexWhere((request) => request.id == id);
    final current = requests[index];
    requests[index] = ScheduleRequest(
      id: current.id,
      kind: current.kind,
      status: ScheduleRequest.statusCancelled,
      startsOn: current.startsOn,
      endsOn: current.endsOn,
      slots: current.slots,
      note: current.note,
    );
  }

  @override
  Future<List<Mission>> missions() async {
    missionsCalls++;
    return List<Mission>.of(activeMissions);
  }

  @override
  Future<Mission> confirmMission(String missionId) async {
    if (confirmFailure != null) {
      throw confirmFailure!;
    }
    confirmed.add(missionId);
    return _move(missionId, 'assigned');
  }

  @override
  Future<void> declineMission(String missionId, {required String reason, String? note}) async {
    declines.add((id: missionId, reason: reason, note: note));
    activeMissions.removeWhere((item) => item.id == missionId);
  }

  @override
  Future<Mission> mission(String id) async {
    detailReads.add(id);
    final found = activeMissions.firstWhere((item) => item.id == id);
    return _detailed(found);
  }

  Mission _detailed(Mission source) {
    return Mission(
      id: source.id,
      reference: source.reference,
      status: source.status,
      serviceName: source.serviceName,
      durationMinutes: source.durationMinutes,
      scheduledDate: source.scheduledDate,
      scheduledTime: source.scheduledTime,
      patientName: source.patientName,
      addressLine: source.addressLine,
      city: source.city,
      accessNotes: source.accessNotes,
      careNotes: 'Allergie à la pénicilline',
      patientNote: 'Sonner deux fois',
      amountToCollect: source.amountToCollect,
      hasPrescription: source.hasPrescription,
      isRemote: source.isRemote,
      needsConfirmation: source.needsConfirmation,
      confirmBy: source.confirmBy,
    );
  }

  // --- Intervention ---

  final List<GeoPoint> positions = <GeoPoint>[];
  GeoPoint? arrivalPosition;
  bool arrived = false;
  Map<Vital, num> vitals = <Vital, num>{};
  String? observations;
  List<ReportLine> acts = <ReportLine>[];
  List<ReportLine> consumables = <ReportLine>[];
  int photos = 0;
  int saves = 0;
  String? signedBy;
  Uint8List? signaturePng;
  bool? cashCollected;

  Intervention _intervention(String missionId, {bool validated = false}) => Intervention(
        id: 'I-$missionId',
        bookingId: missionId,
        status: validated ? 'validated' : 'in_progress',
        vitals: vitals,
        observations: observations,
        acts: acts,
        consumables: consumables,
        photosCount: photos,
        signedByName: signedBy,
        isSigned: signedBy != null,
      );

  Mission _move(String missionId, String status) {
    final index = activeMissions.indexWhere((item) => item.id == missionId);
    // Une téléconsultation le reste quand elle change de statut.
    return activeMissions[index] = buildMission(missionId, status: status, remote: activeMissions[index].isRemote);
  }

  @override
  Future<Mission> depart(String missionId) async => _move(missionId, 'en_route');

  @override
  Future<int?> sendLocation(String missionId, {required double latitude, required double longitude}) async {
    positions.add((latitude: latitude, longitude: longitude));
    return 420;
  }

  @override
  Future<Intervention> arrive(String missionId, {double? latitude, double? longitude}) async {
    arrived = true;
    arrivalPosition = latitude == null ? null : (latitude: latitude, longitude: longitude!);
    _move(missionId, 'in_progress');
    return _intervention(missionId);
  }

  bool callStarted = false;
  ApiFailure? callFailure;

  @override
  Future<Intervention> startTeleconsultation(String missionId) async {
    if (callFailure != null) {
      throw callFailure!;
    }
    callStarted = true;
    _move(missionId, 'in_progress');
    return _intervention(missionId);
  }

  @override
  Future<VideoAccess> teleconsultation(String missionId) async {
    if (callFailure != null) {
      throw callFailure!;
    }
    return VideoAccess(provider: 'fake', room: 'nc-$missionId', token: 'jeton', isHost: true, expiresAt: DateTime(2030));
  }

  @override
  Future<Intervention> intervention(String missionId) async => _intervention(missionId);

  @override
  Future<Intervention> saveReport(String missionId, ReportDraft draft) async {
    saves++;
    vitals = draft.vitals;
    observations = draft.observations;
    acts = draft.acts;
    consumables = draft.consumables;
    return _intervention(missionId);
  }

  @override
  Future<Intervention> addReportPhoto(String missionId, {required Uint8List bytes, required String filename}) async {
    photos++;
    return _intervention(missionId);
  }

  @override
  Future<Intervention> signReport(String missionId, {required Uint8List png, required String signedByName}) async {
    signaturePng = png;
    signedBy = signedByName;
    return _intervention(missionId);
  }

  @override
  Future<Intervention> complete(String missionId, {required bool cashCollected}) async {
    this.cashCollected = cashCollected;
    activeMissions.removeWhere((item) => item.id == missionId);
    return _intervention(missionId, validated: true);
  }
}

class FakeLocationService implements LocationService {
  LocationFailureReason? failure;

  @override
  Future<GeoPoint> currentPosition() async {
    if (failure != null) {
      throw LocationFailure(failure!);
    }
    return (latitude: 35.176, longitude: -2.92);
  }
}

/// Évite le rendu d'image, indisponible dans un test d'écran.
class FakeSignatureEncoder implements SignatureEncoder {
  int strokes = 0;

  @override
  Future<Uint8List> encode(List<List<Offset>> strokes, Size size) async {
    this.strokes = strokes.length;
    return Uint8List.fromList(<int>[9, 9]);
  }
}

class FakeDocumentPicker implements DocumentPicker {
  bool cancel = false;
  final List<bool> calls = <bool>[];

  @override
  Future<PickedDocument?> pick({required bool fromCamera}) async {
    calls.add(fromCamera);
    return cancel ? null : (bytes: Uint8List.fromList(<int>[1, 2, 3]), filename: 'justificatif.jpg');
  }
}

class _SignedInAuthApi implements AuthApi {
  @override
  Future<AppUser> me() async => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder byName(String name) => find.byKey(ValueKey<String>(name));

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> pumpProApp(
  WidgetTester tester, {
  required FakeProApi api,
  FakeDocumentPicker? picker,
  FakeLocationService? location,
  FakeSignatureEncoder? encoder,
  String language = 'fr',
}) async {
  tester.view.physicalSize = const Size(800, 4200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(
          const AppConfig(clientApp: ClientApp.pro, apiBaseUrl: 'https://api.test/api/v1'),
        ),
        preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore(AppSettings(languageCode: language))),
        sessionStorageProvider.overrideWithValue(InMemorySessionStorage(token: 'jeton', user: _user)),
        authApiProvider.overrideWithValue(_SignedInAuthApi()),
        proApiProvider.overrideWithValue(api),
        documentPickerProvider.overrideWithValue(picker ?? FakeDocumentPicker()),
        locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
        signatureEncoderProvider.overrideWithValue(encoder ?? FakeSignatureEncoder()),
      ],
      child: NadorCareApp(homeBuilder: (context) => const ProHomeScreen(), extraRoutes: proAppRoutes),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('dossier', () {
    testWidgets('un compte qui n est pas dans l équipe ne peut pas s inscrire seul', (tester) async {
      final api = FakeProApi();
      await pumpProApp(tester, api: api);

      // Plus de création de dossier dans l'application : c'est l'agence qui fait entrer un soignant.
      expect(byName('no-team'), findsOneWidget);
      expect(find.text(fr.proStart), findsNothing);
      expect(byName('home-planning'), findsNothing);
    });

    testWidgets('un soignant ajouté par l agence voit les justificatifs à déposer', (tester) async {
      final api = FakeProApi(status: VerificationStatus.draft)..licenseNumber = 'AE-2020-114';
      await pumpProApp(tester, api: api);

      expect(find.text(fr.proCreateFileTitle), findsOneWidget);
      await tapAndSettle(tester, find.text(fr.proFileTitle));

      expect(find.text('Infirmier'), findsOneWidget);
      expect(find.text(fr.docStatusMissing), findsNWidgets(4));
      expect(find.text(fr.docOrderRegistration), findsNothing);
      expect(find.text(fr.proSubmitIncomplete), findsOneWidget);
      expect(tester.widget<NcPrimaryButton>(find.widgetWithText(NcPrimaryButton, fr.proSubmit)).onPressed, isNull);
      // La profession se règle au back-office : l'application ne propose plus de la changer.
      expect(find.text(fr.proChangeProfession), findsNothing);
    });

    testWidgets('l assurance personnelle est facultative : le dossier est complet sans elle', (tester) async {
      final api = FakeProApi(status: VerificationStatus.draft)..category = careAssistant;
      for (final type in careAssistant.requiredDocuments) {
        api.documents[type] = ProfessionalDocument(type: type, status: 'approved');
      }
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, find.text(fr.proFileTitle));

      // L'assurance reste proposée, sans bloquer l'envoi du dossier.
      expect(byName('document-rc_insurance'), findsOneWidget);
      expect(find.text(fr.docOptional), findsOneWidget);
      expect(find.text(fr.docStatusMissing), findsNothing);
      expect(find.text(fr.proSubmitIncomplete), findsNothing);
      expect(tester.widget<NcPrimaryButton>(find.widgetWithText(NcPrimaryButton, fr.proSubmit)).onPressed, isNotNull);
      expect(byName('camera-rc_insurance'), findsOneWidget);
    });

    testWidgets('les justificatifs se déposent un par un, puis le dossier est envoyé', (tester) async {
      final api = FakeProApi(status: VerificationStatus.draft);
      final picker = FakeDocumentPicker();
      await pumpProApp(tester, api: api, picker: picker);
      await tapAndSettle(tester, find.text(fr.proFileTitle));

      // Fermer l'appareil photo sans rien prendre n'envoie rien.
      picker.cancel = true;
      await tapAndSettle(tester, byName('camera-identity'));
      expect(api.documents, isEmpty);
      picker.cancel = false;

      await tapAndSettle(tester, byName('camera-identity'));
      await tapAndSettle(tester, byName('gallery-diploma'));
      await tapAndSettle(tester, byName('camera-practice_authorization'));
      expect(find.text(fr.docStatusPending), findsNWidgets(3));
      expect(picker.calls, <bool>[true, true, false, true]);

      // L'assurance exige sa date de fin de validité.
      await tapAndSettle(tester, byName('camera-rc_insurance'));
      expect(find.text(fr.docExpiryRequired), findsOneWidget);
      expect(api.documents.containsKey('rc_insurance'), isFalse);

      await tapAndSettle(tester, byName('insurance-expiry'));
      await tapAndSettle(tester, find.text('OK'));
      await tapAndSettle(tester, byName('camera-rc_insurance'));

      expect(api.documents['rc_insurance']!.expiresAt, isNotNull);
      expect(api.documents['rc_insurance']!.expiresAt!.isAfter(DateTime.now()), isTrue);
      expect(find.text(fr.proSubmitIncomplete), findsNothing);

      await tapAndSettle(tester, find.text(fr.proSubmit));

      expect(api.status, VerificationStatus.submitted);
      expect(find.text(fr.proStatusSubmittedTitle), findsOneWidget);
      expect(find.text(fr.proStatusSubmittedBody), findsOneWidget);
    });

    testWidgets('un dossier refusé affiche le motif et le justificatif à refaire', (tester) async {
      final api = FakeProApi(status: VerificationStatus.rejected, statusReason: 'Diplôme illisible')
        ..documents['identity'] = const ProfessionalDocument(type: 'identity', status: 'approved')
        ..documents['diploma'] = const ProfessionalDocument(type: 'diploma', status: 'rejected', rejectionReason: 'Photo floue');
      await pumpProApp(tester, api: api);

      expect(find.text(fr.proStatusRejectedTitle), findsOneWidget);
      expect(find.text(fr.proReason('Diplôme illisible')), findsOneWidget);

      await tapAndSettle(tester, find.text(fr.proFileTitle));

      expect(find.text(fr.docStatusApproved), findsOneWidget);
      expect(find.text(fr.docStatusRejected('Photo floue')), findsOneWidget);
      // Un justificatif approuvé ne se redépose pas ; le refusé, si.
      expect(byName('camera-identity'), findsNothing);
      expect(byName('camera-diploma'), findsOneWidget);
    });

    testWidgets('un compte suspendu est prévenu avec le motif', (tester) async {
      final api = FakeProApi(status: VerificationStatus.suspended, statusReason: 'Assurance contestée');
      await pumpProApp(tester, api: api);

      expect(find.text(fr.proStatusSuspendedTitle), findsOneWidget);
      expect(find.text(fr.proReason('Assurance contestée')), findsOneWidget);
      expect(byName('home-planning'), findsNothing);
    });

    testWidgets('sans réseau, l accueil propose de réessayer', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..fileFailure = const ApiFailure(code: ApiFailure.network);
      await pumpProApp(tester, api: api);

      expect(find.text(fr.errorNetwork), findsOneWidget);

      api.fileFailure = null;
      await tapAndSettle(tester, find.text(fr.retry));
      expect(byName('home-planning'), findsOneWidget);
    });

    testWidgets('la validation du dossier apparaît sans relancer l application', (tester) async {
      final api = FakeProApi(status: VerificationStatus.submitted);
      await pumpProApp(tester, api: api);
      expect(find.text(fr.proStatusSubmittedTitle), findsOneWidget);

      // L'administrateur valide le dossier dans le back-office.
      api.status = VerificationStatus.verified;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(byName('home-planning'), findsOneWidget);
    });
  });

  group('missions', () {
    testWidgets('l accueil n a plus d interrupteur en ligne ni de propositions', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);

      expect(byName('online-switch'), findsNothing);
      expect(find.text(fr.proOffersTitle), findsNothing);
      expect(find.text(fr.proToConfirmTitle), findsNothing);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);
    });

    testWidgets('une mission affectée se confirme avant le départ', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', toConfirm: true));
      await pumpProApp(tester, api: api);

      // Elle passe devant les autres, avec l'heure limite de la réponse.
      expect(find.text(fr.proToConfirmTitle), findsOneWidget);
      expect(find.text(fr.missionConfirmBefore('12:30')), findsOneWidget);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);

      await tapAndSettle(tester, byName('mission-M1'));

      // La fiche donne ce qu'il faut pour décider ; le départ attend la confirmation.
      expect(api.detailReads, <String>['M1']);
      expect(byName('mission-to-confirm'), findsOneWidget);
      expect(find.text('Aïcha Benali'), findsOneWidget);
      expect(find.text('12 rue Al Massira\nNador'), findsOneWidget);
      expect(find.text('Porte verte, 2e étage'), findsOneWidget);
      expect(find.text('Allergie à la pénicilline'), findsOneWidget);
      expect(find.text('Sonner deux fois'), findsOneWidget);
      expect(find.text('100 DH'), findsOneWidget);
      expect(find.text(fr.missionPrescription), findsOneWidget);
      expect(byName('mission-depart'), findsNothing);

      await tapAndSettle(tester, byName('mission-confirm'));

      expect(api.confirmed, <String>['M1']);
      expect(find.text(fr.missionConfirmed), findsOneWidget);
      expect(byName('mission-confirm'), findsNothing);
      expect(byName('mission-depart'), findsOneWidget);

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.text(fr.proToConfirmTitle), findsNothing);
      expect(byName('mission-M1'), findsOneWidget);
    });

    testWidgets('un refus du serveur à la confirmation est affiché', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', toConfirm: true))
        ..confirmFailure = const ApiFailure(
          code: 'assignment_not_pending',
          message: 'Cette mission n\'attend plus de confirmation.',
          status: 409,
        );
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      await tapAndSettle(tester, byName('mission-confirm'));

      expect(find.text('Cette mission n\'attend plus de confirmation.'), findsOneWidget);
      expect(api.confirmed, isEmpty);
    });

    testWidgets('une mission affectée arrive d elle-même, sans notification', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      final callsBefore = api.missionsCalls;

      api.activeMissions.add(buildMission('M2', toConfirm: true));
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(api.missionsCalls, greaterThan(callsBefore));
      expect(byName('mission-M2'), findsOneWidget);
      expect(find.text(fr.proToConfirmTitle), findsOneWidget);
    });

    testWidgets('signaler son indisponibilité demande un motif', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', toConfirm: true));
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      // Sans motif : la fenêtre reste ouverte et le signale.
      await tapAndSettle(tester, byName('mission-decline'));
      expect(find.text(fr.missionDeclineTitle), findsOneWidget);
      await tapAndSettle(tester, byName('decline-send'));
      expect(find.text(fr.declineReasonRequired), findsOneWidget);
      expect(api.declines, isEmpty);

      // « Autre » demande une précision.
      await tapAndSettle(tester, byName('decline-reason-other'));
      await tapAndSettle(tester, byName('decline-send'));
      expect(find.text(fr.declineNoteRequired), findsOneWidget);
      expect(api.declines, isEmpty);

      // Renoncer ne fait rien.
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.cancel));
      expect(api.declines, isEmpty);
      expect(byName('mission-confirm'), findsOneWidget);

      await tapAndSettle(tester, byName('mission-decline'));
      await tapAndSettle(tester, byName('decline-reason-sick'));
      await tester.enterText(byName('decline-note'), 'Forte fièvre');
      await tapAndSettle(tester, byName('decline-send'));

      expect(api.declines.single, (id: 'M1', reason: 'sick', note: 'Forte fièvre'));
      expect(byName('mission-M1'), findsNothing);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);
    });

    testWidgets('une mission déjà confirmée peut encore être rendue avant le départ', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1'));
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      expect(byName('mission-confirm'), findsNothing);
      await tapAndSettle(tester, byName('mission-decline'));
      await tapAndSettle(tester, byName('decline-reason-busy'));
      await tapAndSettle(tester, byName('decline-send'));

      expect(api.declines.single, (id: 'M1', reason: 'busy', note: ''));
    });

    testWidgets('une fois en route, l indisponibilité n est plus proposée', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1', status: 'en_route'));
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      expect(find.text(fr.missionStatusEnRoute), findsOneWidget);
      expect(byName('mission-decline'), findsNothing);
    });
  });

  group('intervention', () {
    testWidgets('au départ, la mission passe en route et la position est partagée', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1'));
      await pumpProApp(tester, api: api);
      expect(api.positions, isEmpty, reason: 'aucune position hors trajet');

      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-depart'));

      expect(find.text(fr.missionStatusEnRoute), findsOneWidget);
      expect(byName('mission-decline'), findsNothing);
      expect(byName('mission-arrive'), findsOneWidget);
      expect(api.positions.single, (latitude: 35.176, longitude: -2.92));
      expect(find.textContaining(fr.journeySharing), findsOneWidget);
      expect(find.textContaining(fr.journeyEta(7)), findsOneWidget);

      // La position est renvoyée régulièrement pendant le trajet.
      await tester.pump(const Duration(seconds: 21));
      await tester.pumpAndSettle();
      expect(api.positions, hasLength(2));
    });

    testWidgets('sans localisation, le trajet continue et le professionnel est prévenu', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1'));
      final location = FakeLocationService()..failure = LocationFailureReason.denied;
      await pumpProApp(tester, api: api, location: location);

      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-depart'));

      expect(byName('journey-location-off'), findsOneWidget);
      expect(api.positions, isEmpty);

      // Le pointage d'arrivée reste possible, sans position.
      await tapAndSettle(tester, byName('mission-arrive'));
      expect(api.arrived, isTrue);
      expect(api.arrivalPosition, isNull);
      expect(find.text(fr.reportTitle), findsOneWidget);
    });

    testWidgets('une téléconsultation démarre par un appel, sans trajet, et se clôt sans signature', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', remote: true));
      await pumpProApp(tester, api: api);

      await tapAndSettle(tester, byName('mission-M1'));
      expect(byName('mission-remote'), findsOneWidget);
      expect(byName('mission-depart'), findsNothing, reason: 'pas de trajet pour un appel vidéo');

      await tapAndSettle(tester, byName('mission-start-call'));
      expect(api.callStarted, isTrue);
      expect(byName('call-simulated'), findsOneWidget);
      expect(api.positions, isEmpty, reason: 'aucune position n est partagée pendant un appel');

      await tapAndSettle(tester, byName('call-hang-up'));
      expect(byName('mission-join-call'), findsOneWidget);

      await tapAndSettle(tester, byName('mission-report'));
      expect(byName('report-sign'), findsNothing, reason: 'le patient ne peut pas signer à distance');
      await tester.enterText(byName('report-observations'), 'Renouvellement de traitement.');
      await tapAndSettle(tester, byName('report-complete'));
      expect(find.text(fr.reportSignatureRequired), findsNothing);
    });

    testWidgets('si la salle n est pas ouverte, la téléconsultation ne démarre pas', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', remote: true))
        ..callFailure = const ApiFailure(
          code: 'teleconsultation_not_open',
          message: 'La salle de téléconsultation n est pas ouverte pour le moment.',
          status: 409,
        );
      await pumpProApp(tester, api: api);

      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-start-call'));

      expect(api.callStarted, isFalse);
      expect(find.text('La salle de téléconsultation n est pas ouverte pour le moment.'), findsOneWidget);
      expect(byName('mission-start-call'), findsOneWidget);
    });

    testWidgets('à l arrivée, le compte rendu s ouvre et la position n est plus envoyée', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', status: 'en_route'));
      await pumpProApp(tester, api: api);
      expect(api.positions, hasLength(1), reason: 'le suivi reprend à l ouverture de l application');

      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-arrive'));

      expect(api.arrivalPosition, (latitude: 35.176, longitude: -2.92));
      expect(find.text(fr.reportTitle), findsOneWidget);
      expect(find.text(fr.reportNotSigned), findsOneWidget);

      await tester.pump(const Duration(seconds: 45));
      await tester.pumpAndSettle();
      expect(api.positions, hasLength(1));
    });

    testWidgets('le compte rendu s enregistre en brouillon, les constantes invraisemblables sont refusées', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', status: 'in_progress'))
        ..observations = 'Patient calme.'
        ..vitals = <Vital, num>{Vital.pulse: 72};
      final picker = FakeDocumentPicker();
      await pumpProApp(tester, api: api, picker: picker);
      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-report'));

      // Le brouillon déjà enregistré est repris.
      expect(find.text('Patient calme.'), findsOneWidget);
      expect(find.text('72'), findsOneWidget);

      await tester.enterText(byName('vital-systolic'), '1350');
      await tester.enterText(byName('vital-temperature'), '37,2');
      await tapAndSettle(tester, byName('report-save'));
      expect(find.text(fr.vitalOutOfRange('50', '260')), findsOneWidget);
      expect(api.saves, 0);

      await tester.enterText(byName('vital-systolic'), '135');
      await tester.enterText(byName('report-observations'), 'Pansement refait, plaie propre.');

      await tapAndSettle(tester, byName('report-add-act'));
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.add));
      expect(find.text(fr.fieldRequired), findsOneWidget);
      await tester.enterText(byName('line-label'), 'Réfection de pansement');
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.add));

      await tapAndSettle(tester, byName('report-add-consumable'));
      await tester.enterText(byName('line-label'), 'Compresses stériles');
      await tester.enterText(byName('line-quantity'), '4');
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.add));
      expect(find.text(fr.reportLineWithQuantity('Compresses stériles', '4')), findsOneWidget);

      await tapAndSettle(tester, byName('report-add-photo'));
      expect(picker.calls, <bool>[true]);
      expect(find.text(fr.reportPhotosCount(1)), findsOneWidget);

      await tapAndSettle(tester, byName('report-save'));
      expect(find.text(fr.reportSaved), findsOneWidget);
      expect(api.vitals, <Vital, num>{Vital.systolic: 135, Vital.pulse: 72, Vital.temperature: 37.2});
      expect(api.observations, 'Pansement refait, plaie propre.');
      expect(api.acts.single.label, 'Réfection de pansement');
      expect(api.acts.single.quantity, 1);
      expect(api.consumables.single.quantity, 4);
    });

    testWidgets('la clôture exige des observations et la signature, puis valide et encaisse', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', status: 'in_progress'));
      final encoder = FakeSignatureEncoder();
      await pumpProApp(tester, api: api, encoder: encoder);
      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-report'));

      await tapAndSettle(tester, byName('report-complete'));
      expect(find.text(fr.reportObservationsRequired), findsOneWidget);

      await tester.enterText(byName('report-observations'), 'Soin réalisé sans difficulté.');
      await tapAndSettle(tester, byName('report-complete'));
      expect(find.text(fr.reportSignatureRequired), findsOneWidget);
      expect(api.cashCollected, isNull);

      // Signature : le nom du patient est proposé, un tracé vide est refusé.
      await tapAndSettle(tester, byName('report-sign'));
      expect(find.text('Aïcha Benali'), findsOneWidget);
      await tapAndSettle(tester, byName('signature-confirm'));
      expect(find.text(fr.signatureEmpty), findsOneWidget);

      await tester.drag(byName('signature-pad'), const Offset(160, 60));
      await tester.pumpAndSettle();
      await tapAndSettle(tester, byName('signature-confirm'));

      expect(encoder.strokes, 1);
      expect(api.signedBy, 'Aïcha Benali');
      expect(api.signaturePng, <int>[9, 9]);
      expect(find.text(fr.reportSignedBy('Aïcha Benali')), findsOneWidget);

      await tapAndSettle(tester, byName('report-cash'));
      await tapAndSettle(tester, byName('report-complete'));
      expect(find.text(fr.reportCompleteBody), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.reportComplete));

      expect(api.cashCollected, isTrue);
      expect(api.observations, 'Soin réalisé sans difficulté.');
      // Retour à l'accueil : la mission est terminée.
      expect(find.text(fr.reportCompleted), findsOneWidget);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);
    });

    testWidgets('en arabe, le compte rendu se lit de droite à gauche et les mesures de gauche à droite', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..activeMissions.add(buildMission('M1', status: 'in_progress'));
      await pumpProApp(tester, api: api, language: 'ar');
      await tapAndSettle(tester, byName('mission-M1'));
      await tapAndSettle(tester, byName('mission-report'));

      expect(Directionality.of(tester.element(find.text(ar.reportTitle))), TextDirection.rtl);
      expect(tester.widget<TextField>(byName('vital-systolic')).textDirection, TextDirection.ltr);
      expect(find.text(ar.reportComplete), findsOneWidget);
    });
  });

  group('planning', () {
    testWidgets('le soignant lit le planning fixé par l agence, sans pouvoir le changer seul', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..zonesChosen = <ServiceZone>[allZones.first]
        ..slots = <AvailabilitySlot>[
          const AvailabilitySlot(weekday: 1, startTime: '14:00', endTime: '18:00'),
          const AvailabilitySlot(weekday: 1, startTime: '08:00', endTime: '12:00'),
          const AvailabilitySlot(weekday: 6, startTime: '09:00', endTime: '13:00'),
        ];
      await pumpProApp(tester, api: api);
      expect(byName('home-planning-missing'), findsNothing);

      await tapAndSettle(tester, byName('home-planning'));

      expect(find.text('Nador centre'), findsOneWidget);
      // Les plages d'un jour se lisent dans l'ordre des heures.
      expect(find.text('${fr.scheduleRange('08:00', '12:00')}, ${fr.scheduleRange('14:00', '18:00')}'), findsOneWidget);
      expect(byName('planning-day-6'), findsOneWidget);
      expect(byName('planning-day-2'), findsNothing);
      expect(find.text(fr.planningRequestsEmpty), findsOneWidget);
      expect(find.text(fr.save), findsNothing);
    });

    testWidgets('un planning pas encore fixé est annoncé comme tel', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      expect(byName('home-planning-missing'), findsOneWidget);

      await tapAndSettle(tester, byName('home-planning'));
      expect(byName('planning-zones-unset'), findsOneWidget);
      expect(byName('planning-week-unset'), findsOneWidget);
    });

    testWidgets('une semaine proposée part en demande et ne change pas le planning', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..slots = <AvailabilitySlot>[const AvailabilitySlot(weekday: 6, startTime: '09:00', endTime: '13:00')];
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('home-planning'));
      await tapAndSettle(tester, byName('propose-week'));

      // La proposition part du planning actuel ; sans changement, il n'y a rien à envoyer.
      expect(find.text(fr.scheduleRange('09:00', '13:00')), findsOneWidget);
      expect(tester.widget<NcPrimaryButton>(byName('send-week')).onPressed, isNull);

      await tapAndSettle(tester, byName('day-1'));
      await tapAndSettle(tester, byName('day-2'));
      await tapAndSettle(tester, byName('day-6'));
      await tapAndSettle(tester, byName('send-week'));

      expect(api.requests.single.slots.map((slot) => slot.toJson()), <Map<String, dynamic>>[
        <String, dynamic>{'weekday': 1, 'start_time': '08:00', 'end_time': '18:00'},
        <String, dynamic>{'weekday': 2, 'start_time': '08:00', 'end_time': '18:00'},
      ]);
      expect(api.slots.single.weekday, 6, reason: 'le planning ne change qu avec l accord de la coordination');

      // De retour sur le planning : la demande est en attente, le planning est celui d'avant.
      expect(find.text(fr.planningSent), findsOneWidget);
      expect(byName('request-R1'), findsOneWidget);
      expect(find.text(fr.planningStatusPending), findsOneWidget);
      expect(byName('planning-day-6'), findsOneWidget);
      expect(byName('planning-day-1'), findsNothing);
    });

    testWidgets('quitter une proposition modifiée sans l envoyer demande une confirmation', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('home-planning'));
      await tapAndSettle(tester, byName('propose-week'));

      // Rien de modifié : le retour est immédiat.
      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.text(fr.unsavedTitle), findsNothing);

      await tapAndSettle(tester, byName('propose-week'));
      await tapAndSettle(tester, byName('day-1'));
      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.text(fr.unsavedTitle), findsOneWidget);

      // « Rester » garde l'écran et la modification.
      await tapAndSettle(tester, byName('unsaved-stay'));
      expect(byName('day-1'), findsOneWidget);

      await tapAndSettle(tester, find.byType(BackButton));
      await tapAndSettle(tester, byName('unsaved-leave'));
      expect(byName('propose-week'), findsOneWidget);
      expect(api.requests, isEmpty, reason: 'rien n a été envoyé');
    });

    testWidgets('une indisponibilité se signale avec ses dates, puis peut être retirée', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('home-planning'));
      await tapAndSettle(tester, byName('report-unavailability'));

      // Sans date, rien à envoyer ; le dernier jour attend le premier.
      expect(tester.widget<NcPrimaryButton>(byName('send-unavailability')).onPressed, isNull);
      expect(
        tester.widget<InkWell>(find.descendant(of: byName('last-day'), matching: find.byType(InkWell))).onTap,
        isNull,
      );

      // Le calendrier s'ouvre sur aujourd'hui : on valide ce jour.
      await tapAndSettle(tester, byName('first-day'));
      await tapAndSettle(tester, find.text('OK'));
      await tester.enterText(byName('unavailability-note'), 'Rendez-vous');
      await tester.pumpAndSettle();
      await tapAndSettle(tester, byName('send-unavailability'));

      final sent = api.requests.single;
      final now = DateTime.now();
      expect(sent.kind, ScheduleRequest.kindUnavailability);
      expect(sent.startsOn, DateTime(now.year, now.month, now.day));
      expect(sent.endsOn, sent.startsOn, reason: 'une seule journée par défaut');
      expect(sent.note, 'Rendez-vous');

      expect(byName('request-R1'), findsOneWidget);
      expect(find.text(fr.planningKindUnavailability), findsOneWidget);

      await tapAndSettle(tester, byName('withdraw-R1'));
      expect(find.text(fr.planningStatusCancelled), findsOneWidget);
      expect(byName('withdraw-R1'), findsNothing);
    });

    testWidgets('un refus de la coordination s affiche avec son motif', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..requests.add(
          ScheduleRequest(
            id: 'R1',
            kind: ScheduleRequest.kindUnavailability,
            status: ScheduleRequest.statusRefused,
            startsOn: DateTime(2026, 12, 8),
            endsOn: DateTime(2026, 12, 9),
            decisionNote: 'Équipe déjà réduite.',
          ),
        );
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('home-planning'));

      expect(find.text(fr.planningStatusRefused), findsOneWidget);
      expect(find.text(fr.planningDecisionNote('Équipe déjà réduite.')), findsOneWidget);
      expect(
        find.text(fr.planningFromTo(longDate(DateTime(2026, 12, 8), 'fr'), longDate(DateTime(2026, 12, 9), 'fr'))),
        findsOneWidget,
      );
      expect(byName('withdraw-R1'), findsNothing);
    });
  });

  testWidgets('en arabe, l accueil du professionnel se lit de droite à gauche', (tester) async {
    final api = FakeProApi(status: VerificationStatus.verified)
      ..activeMissions.add(buildMission('M1', toConfirm: true));
    await pumpProApp(tester, api: api, language: 'ar');

    expect(find.text(ar.proToConfirmTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.proToConfirmTitle))), TextDirection.rtl);
    // Les heures restent en chiffres latins : celle du soin, et l'heure limite de la réponse.
    expect(find.textContaining('10:00'), findsOneWidget);
    expect(find.text(ar.missionConfirmBefore('12:30')), findsOneWidget);
  });

  test('les distances restent lisibles', () {
    expect(formatDistance(850, 'fr'), '850 m');
    expect(formatDistance(2400, 'fr'), '2,4 km');
    expect(formatDistance(12000, 'en'), '12 km');
    expect(formatDistance(2400, 'ar'), '2.4 km');
  });
}
