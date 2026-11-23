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

MissionOffer offer(String id) => MissionOffer(
      id: id,
      serviceName: 'Pansement',
      durationMinutes: 30,
      scheduledDate: DateTime(2026, 12, 8),
      scheduledTime: '10:00',
      expiresAt: DateTime.utc(2026, 12, 7, 9, 2),
      zone: 'Nador centre',
      distanceMeters: 2400,
    );

Mission buildMission(String id, {String status = 'assigned', bool detailed = false, bool remote = false}) => Mission(
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
    );

/// Imite le serveur pour le dossier, les propositions et les missions.
class FakeProApi implements ProApi {
  FakeProApi({this.status, this.statusReason});

  VerificationStatus? status;
  String? statusReason;
  ProfessionCategory category = nurse;
  String? licenseNumber;
  bool online = false;
  final Map<String, ProfessionalDocument> documents = <String, ProfessionalDocument>{};
  List<ServiceZone> zonesChosen = <ServiceZone>[];
  List<AvailabilitySlot> slots = <AvailabilitySlot>[];
  final List<MissionOffer> pendingOffers = <MissionOffer>[];
  final List<Mission> activeMissions = <Mission>[];

  ApiFailure? fileFailure;
  ApiFailure? acceptFailure;
  int offersCalls = 0;
  final List<String> declined = <String>[];
  final List<String> detailReads = <String>[];
  final List<({String id, String reason})> withdrawals = [];

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
      isOnline: online,
      requiredDocuments: category.requiredDocuments,
      missingDocuments: missing,
      documents: documents.values.toList(),
      canSubmit: status!.isEditable && missing.isEmpty,
      zones: zonesChosen,
      availabilities: slots,
    );
  }

  @override
  Future<List<ProfessionCategory>> categories() async => const <ProfessionCategory>[nurse, doctor];

  @override
  Future<List<ServiceZone>> zones() async => allZones;

  @override
  Future<ProfessionalFile?> file() async {
    if (fileFailure != null) {
      throw fileFailure!;
    }
    return status == null ? null : _file();
  }

  @override
  Future<ProfessionalFile> saveFile({required String categoryId, String? licenseNumber, String? orderNumber}) async {
    category = <ProfessionCategory>[nurse, doctor].firstWhere((item) => item.id == categoryId);
    this.licenseNumber = licenseNumber;
    status ??= VerificationStatus.draft;
    return _file();
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
  Future<ProfessionalFile> setZones(List<String> zoneIds) async {
    zonesChosen = allZones.where((zone) => zoneIds.contains(zone.id)).toList();
    return _file();
  }

  @override
  Future<ProfessionalFile> setAvailabilities(List<AvailabilitySlot> slots) async {
    this.slots = slots;
    return _file();
  }

  @override
  Future<ProfessionalFile> setOnline({required bool online}) async {
    this.online = online;
    return _file();
  }

  @override
  Future<List<MissionOffer>> offers() async {
    offersCalls++;
    return List<MissionOffer>.of(pendingOffers);
  }

  @override
  Future<Mission> acceptOffer(String offerId) async {
    if (acceptFailure != null) {
      pendingOffers.removeWhere((item) => item.id == offerId);
      throw acceptFailure!;
    }
    pendingOffers.removeWhere((item) => item.id == offerId);
    final accepted = buildMission('M-$offerId');
    activeMissions.add(accepted);
    return accepted;
  }

  @override
  Future<void> declineOffer(String offerId, {String? reason}) async {
    declined.add(offerId);
    pendingOffers.removeWhere((item) => item.id == offerId);
  }

  @override
  Future<List<Mission>> missions() async => List<Mission>.of(activeMissions);

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
    );
  }

  @override
  Future<void> withdraw(String missionId, {required String reason}) async {
    withdrawals.add((id: missionId, reason: reason));
    activeMissions.removeWhere((item) => item.id == missionId);
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
    testWidgets('un nouveau professionnel choisit sa profession puis voit les justificatifs à déposer', (tester) async {
      final api = FakeProApi();
      await pumpProApp(tester, api: api);

      expect(find.text(fr.proCreateFileTitle), findsOneWidget);
      await tapAndSettle(tester, find.text(fr.proStart));

      // Sans profession choisie, on n'avance pas.
      await tapAndSettle(tester, find.text(fr.continueButton));
      expect(find.text(fr.professionRequired), findsOneWidget);

      // Le numéro d'Ordre n'est demandé qu'aux professions qui ont un Ordre.
      await tapAndSettle(tester, byName('profession-C1'));
      expect(byName('order-field'), findsNothing);
      await tapAndSettle(tester, byName('profession-C2'));
      expect(byName('order-field'), findsOneWidget);
      await tapAndSettle(tester, byName('profession-C1'));

      await tester.enterText(byName('license-field'), 'AE-2020-114');
      await tapAndSettle(tester, find.text(fr.continueButton));

      expect(find.text(fr.proFileTitle), findsOneWidget);
      expect(find.text('Infirmier'), findsOneWidget);
      expect(api.licenseNumber, 'AE-2020-114');
      expect(find.text(fr.docStatusMissing), findsNWidgets(4));
      expect(find.text(fr.docOrderRegistration), findsNothing);
      expect(find.text(fr.proSubmitIncomplete), findsOneWidget);
      expect(tester.widget<NcPrimaryButton>(find.widgetWithText(NcPrimaryButton, fr.proSubmit)).onPressed, isNull);
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
      expect(byName('online-switch'), findsNothing);
    });

    testWidgets('sans réseau, l accueil propose de réessayer', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..fileFailure = const ApiFailure(code: ApiFailure.network);
      await pumpProApp(tester, api: api);

      expect(find.text(fr.errorNetwork), findsOneWidget);

      api.fileFailure = null;
      await tapAndSettle(tester, find.text(fr.retry));
      expect(byName('online-switch'), findsOneWidget);
    });

    testWidgets('la validation du dossier apparaît sans relancer l application', (tester) async {
      final api = FakeProApi(status: VerificationStatus.submitted);
      await pumpProApp(tester, api: api);
      expect(find.text(fr.proStatusSubmittedTitle), findsOneWidget);

      // L'administrateur valide le dossier dans le back-office.
      api.status = VerificationStatus.verified;
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(byName('online-switch'), findsOneWidget);
    });
  });

  group('missions', () {
    testWidgets('un professionnel vérifié se met en ligne', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);

      expect(find.text(fr.proOffline), findsOneWidget);
      expect(find.text(fr.proOffersEmpty), findsOneWidget);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);

      await tapAndSettle(tester, byName('online-switch'));

      expect(api.online, isTrue);
      expect(find.text(fr.proOnline), findsOneWidget);
    });

    testWidgets('une proposition ne montre ni le patient ni l adresse, puis s accepte', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..pendingOffers.add(offer('O1'));
      await pumpProApp(tester, api: api);

      expect(byName('offer-O1'), findsOneWidget);
      expect(find.text('Pansement'), findsOneWidget);
      expect(find.textContaining('Nador centre'), findsOneWidget);
      expect(find.textContaining(fr.offerDistance('2,4 km')), findsOneWidget);
      expect(find.textContaining('Aïcha'), findsNothing);
      expect(find.textContaining('Al Massira'), findsNothing);
      expect(api.detailReads, isEmpty);

      await tapAndSettle(tester, byName('accept-O1'));

      // La fiche de la mission s'ouvre, avec les informations utiles au soin.
      expect(api.detailReads, <String>['M-O1']);
      expect(find.text('Aïcha Benali'), findsOneWidget);
      expect(find.text('12 rue Al Massira\nNador'), findsOneWidget);
      expect(find.text('Porte verte, 2e étage'), findsOneWidget);
      expect(find.text('Allergie à la pénicilline'), findsOneWidget);
      expect(find.text('Sonner deux fois'), findsOneWidget);
      expect(find.text('100 DH'), findsOneWidget);
      expect(find.text(fr.missionPrescription), findsOneWidget);

      await tapAndSettle(tester, find.byType(BackButton));
      expect(byName('offer-O1'), findsNothing);
      expect(byName('mission-M-O1'), findsOneWidget);
    });

    testWidgets('une proposition refusée disparaît', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..pendingOffers.add(offer('O1'));
      await pumpProApp(tester, api: api);

      await tapAndSettle(tester, byName('decline-O1'));

      expect(api.declined, <String>['O1']);
      expect(byName('offer-O1'), findsNothing);
      expect(find.text(fr.proOffersEmpty), findsOneWidget);
      expect(api.activeMissions, isEmpty);
    });

    testWidgets('une proposition qui n est plus valable le dit et disparaît', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..pendingOffers.add(offer('O1'))
        ..acceptFailure = const ApiFailure(
          code: 'offer_unavailable',
          message: 'Cette proposition n\'est plus disponible.',
          status: 409,
        );
      await pumpProApp(tester, api: api);

      await tapAndSettle(tester, byName('accept-O1'));

      expect(find.text('Cette proposition n\'est plus disponible.'), findsOneWidget);
      expect(byName('offer-O1'), findsNothing);
    });

    testWidgets('les propositions arrivent d elles-mêmes, sans notification', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      final callsBefore = api.offersCalls;

      api.pendingOffers.add(offer('O2'));
      await tester.pump(const Duration(seconds: 15));
      await tester.pumpAndSettle();

      expect(api.offersCalls, greaterThan(callsBefore));
      expect(byName('offer-O2'), findsOneWidget);
    });

    testWidgets('le désistement demande un motif', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1'));
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      // Sans motif : la fenêtre reste ouverte et le signale.
      await tapAndSettle(tester, byName('mission-withdraw'));
      expect(find.text(fr.missionWithdrawTitle), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.missionWithdraw));
      expect(find.text(fr.fieldRequired), findsOneWidget);
      expect(find.text(fr.missionWithdrawTitle), findsOneWidget);
      expect(api.withdrawals, isEmpty);

      // Renoncer ne fait rien.
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.cancel));
      expect(api.withdrawals, isEmpty);

      await tapAndSettle(tester, byName('mission-withdraw'));
      await tester.enterText(byName('withdraw-reason'), 'Panne de voiture');
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.missionWithdraw));

      expect(api.withdrawals.single, (id: 'M1', reason: 'Panne de voiture'));
      expect(byName('mission-M1'), findsNothing);
      expect(find.text(fr.proMissionsEmpty), findsOneWidget);
    });

    testWidgets('une fois en route, le désistement n est plus proposé', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)..activeMissions.add(buildMission('M1', status: 'en_route'));
      await pumpProApp(tester, api: api);
      await tapAndSettle(tester, byName('mission-M1'));

      expect(find.text(fr.missionStatusEnRoute), findsOneWidget);
      expect(byName('mission-withdraw'), findsNothing);
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
      expect(byName('mission-withdraw'), findsNothing);
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

  group('disponibilités', () {
    testWidgets('le professionnel choisit ses zones', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified);
      await pumpProApp(tester, api: api);
      expect(find.text(fr.proZonesCount(0)), findsOneWidget);

      await tapAndSettle(tester, byName('home-zones'));
      await tapAndSettle(tester, byName('zone-Z1'));
      await tapAndSettle(tester, byName('zone-Z2'));
      await tapAndSettle(tester, byName('zone-Z2'));
      await tapAndSettle(tester, find.text(fr.save));

      expect(api.zonesChosen.map((zone) => zone.id), <String>['Z1']);
      expect(find.text(fr.proZonesCount(1)), findsOneWidget);
    });

    testWidgets('le professionnel définit ses jours de travail', (tester) async {
      final api = FakeProApi(status: VerificationStatus.verified)
        ..slots = <AvailabilitySlot>[const AvailabilitySlot(weekday: 6, startTime: '09:00', endTime: '13:00')];
      await pumpProApp(tester, api: api);
      expect(find.text(fr.proScheduleCount(1)), findsOneWidget);

      await tapAndSettle(tester, byName('home-schedule'));
      expect(find.text('Lundi'), findsOneWidget);
      expect(find.text(fr.scheduleRange('09:00', '13:00')), findsOneWidget);

      await tapAndSettle(tester, byName('day-1'));
      await tapAndSettle(tester, byName('day-2'));
      await tapAndSettle(tester, byName('day-6'));
      expect(find.text(fr.scheduleRange('08:00', '18:00')), findsNWidgets(2));
      await tapAndSettle(tester, find.text(fr.save));

      expect(api.slots.map((slot) => slot.toJson()), <Map<String, dynamic>>[
        <String, dynamic>{'weekday': 1, 'start_time': '08:00', 'end_time': '18:00'},
        <String, dynamic>{'weekday': 2, 'start_time': '08:00', 'end_time': '18:00'},
      ]);
      expect(find.text(fr.proScheduleCount(2)), findsOneWidget);
    });
  });

  testWidgets('en arabe, l accueil du professionnel se lit de droite à gauche', (tester) async {
    final api = FakeProApi(status: VerificationStatus.verified)..pendingOffers.add(offer('O1'));
    await pumpProApp(tester, api: api, language: 'ar');

    expect(find.text(ar.proOffersTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.proOffersTitle))), TextDirection.rtl);
    expect(find.text(ar.offerAccept), findsOneWidget);
    expect(find.textContaining('10:00'), findsOneWidget);
  });

  test('les distances restent lisibles', () {
    expect(formatDistance(850, 'fr'), '850 m');
    expect(formatDistance(2400, 'fr'), '2,4 km');
    expect(formatDistance(12000, 'en'), '12 km');
    expect(formatDistance(2400, 'ar'), '2.4 km');
  });
}
