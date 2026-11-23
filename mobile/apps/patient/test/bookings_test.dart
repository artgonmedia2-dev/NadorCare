import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nadorcare_patient/bookings/bookings_providers.dart';
import 'package:nadorcare_patient/bookings/prescription_picker.dart';
import 'package:nadorcare_patient/catalogue/catalogue_providers.dart';
import 'package:nadorcare_patient/home_screen.dart';
import 'package:nadorcare_patient/main.dart';
import 'package:nadorcare_patient/patients/patients_providers.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

final NcLocalizations fr = lookupNcLocalizations(const Locale('fr'));
final NcLocalizations ar = lookupNcLocalizations(const Locale('ar'));

const AppUser _user = AppUser(
  id: '01USER',
  phone: '+212612345678',
  name: 'Karim',
  locale: 'fr',
  status: 'active',
  roles: <String>['patient'],
);

const CareService dressing = CareService(
  id: 'S2',
  slug: 'pansement',
  name: 'Pansement',
  durationMinutes: 30,
  priceAmount: 10000,
  requiresPrescription: false,
  allowsSeries: false,
  categorySlug: 'soins-infirmiers',
  categoryName: 'Soins infirmiers',
);

const CareService injection = CareService(
  id: 'S1',
  slug: 'injection',
  name: 'Injection',
  durationMinutes: 20,
  priceAmount: 8000,
  requiresPrescription: true,
  allowsSeries: true,
  categorySlug: 'soins-infirmiers',
  categoryName: 'Soins infirmiers',
);

const PatientProfile mother = PatientProfile(
  id: 'P1',
  firstName: 'Aïcha',
  lastName: 'Benali',
  relationship: PatientRelationship.parent,
);

const PatientAddress home = PatientAddress(
  id: 'A1',
  label: 'Maison',
  line: '12 rue Al Massira',
  city: 'Nador',
  latitude: 35.17,
  longitude: -2.93,
  isCovered: true,
);

const PatientAddress farAway = PatientAddress(
  id: 'A2',
  label: 'Ferme',
  line: 'Douar Ouled Ali',
  city: 'Nador',
  latitude: 34.9,
  longitude: -2.5,
  isCovered: false,
);

class FakeCatalogueApi implements CatalogueApi {
  @override
  Future<CareService> service(String slug) async =>
      <CareService>[dressing, injection].firstWhere((service) => service.slug == slug);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakePatientsApi implements PatientsApi {
  FakePatientsApi({List<PatientProfile>? profiles, List<PatientAddress>? addresses})
      : profiles = profiles ?? <PatientProfile>[mother],
        addresses = addresses ?? <PatientAddress>[home, farAway];

  final List<PatientProfile> profiles;
  final List<PatientAddress> addresses;

  @override
  Future<List<PatientProfile>> listProfiles() async => profiles;

  @override
  Future<List<PatientAddress>> listAddresses() async => addresses;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Imite le serveur de réservation.
class FakeBookingsApi implements BookingsApi {
  bool immediateAvailable = false;
  List<PriceLine> surcharges = const <PriceLine>[];
  ApiFailure? createFailure;
  int feeIfCancelledNow = 0;

  final List<BookingDraft> created = <BookingDraft>[];
  final List<String> uploads = <String>[];
  final List<Booking> bookings = <Booking>[];
  final List<String> cancelled = <String>[];
  final List<String> reportReads = <String>[];
  Intervention? validatedReport;

  PriceQuote _price(int base) {
    final extra = surcharges.fold<int>(0, (sum, line) => sum + line.amount);
    return PriceQuote(base: base, surcharges: surcharges, total: base + extra);
  }

  Booking _booking(
    String id,
    BookingStatus status, {
    int? fee,
    bool withProfessional = false,
    int? etaMinutes,
    bool remote = false,
  }) {
    return Booking(
      id: id,
      reference: 'NC-2026-000042',
      status: status,
      scheduledDate: DateTime(2026, 12, 8),
      scheduledTime: '09:30',
      serviceName: 'Pansement',
      patientName: 'Aïcha Benali',
      addressLabel: 'Maison',
      addressLine: '12 rue Al Massira',
      price: _price(10000),
      canCancel: status != BookingStatus.cancelled && status != BookingStatus.completed,
      cancellationFeeIfCancelledNow: feeIfCancelledNow,
      cancellationFee: fee,
      patientNote: 'Sonner deux fois',
      professionalName: withProfessional ? 'Samira' : null,
      professionalProfession: withProfessional ? 'Infirmier' : null,
      tracking: etaMinutes == null
          ? null
          : BookingTracking(latitude: 35.176, longitude: -2.92, etaMinutes: etaMinutes),
      hasReport: status == BookingStatus.completed,
      isRemote: remote,
    );
  }

  /// Erreur renvoyée par la salle vidéo, quand elle n'est pas ouverte.
  ApiFailure? callFailure;
  final List<String> callJoins = <String>[];

  @override
  Future<VideoAccess> teleconsultation(String bookingId) async {
    if (callFailure != null) {
      throw callFailure!;
    }
    callJoins.add(bookingId);
    return VideoAccess(provider: 'fake', room: 'nc-$bookingId', token: 'jeton', isHost: false, expiresAt: DateTime(2030));
  }

  @override
  Future<BookingDay> slots({required String serviceId, required String date}) async {
    return BookingDay(
      slots: <BookingSlot>[
        BookingSlot.fromIso('${date}T09:30:00+01:00'),
        BookingSlot.fromIso('${date}T10:00:00+01:00'),
      ],
      immediateAvailable: immediateAvailable,
    );
  }

  @override
  Future<PriceQuote> quote({required String serviceId, BookingSlot? slot}) async {
    return _price(serviceId == 'S1' ? 8000 : 10000);
  }

  @override
  Future<String> uploadPrescription({required Uint8List bytes, required String filename}) async {
    uploads.add(filename);
    return 'F${uploads.length}';
  }

  @override
  Future<Booking> create(BookingDraft draft) async {
    if (createFailure != null) {
      throw createFailure!;
    }
    created.add(draft);
    final booking = _booking('B${created.length}', BookingStatus.pending);
    bookings.add(booking);
    return booking;
  }

  @override
  Future<List<Booking>> list({bool past = false}) async {
    return bookings.where((booking) => booking.isClosed == past).toList();
  }

  @override
  Future<Booking> get(String id) async => bookings.firstWhere((booking) => booking.id == id);

  @override
  Future<Booking> cancel(String id, {String? reason}) async {
    cancelled.add(id);
    final updated = _booking(id, BookingStatus.cancelled, fee: feeIfCancelledNow);
    bookings[bookings.indexWhere((booking) => booking.id == id)] = updated;
    return updated;
  }

  @override
  Future<Intervention> report(String bookingId) async {
    reportReads.add(bookingId);
    return validatedReport!;
  }
}

class FakePrescriptionPicker implements PrescriptionPicker {
  bool cancel = false;
  final List<bool> calls = <bool>[];

  @override
  Future<PickedPrescription?> pick({required bool fromCamera}) async {
    calls.add(fromCamera);
    return cancel ? null : (bytes: Uint8List.fromList(<int>[1, 2, 3]), filename: 'ordonnance.jpg');
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

class Env {
  Env({FakePatientsApi? patients}) : patients = patients ?? FakePatientsApi();

  final FakeBookingsApi bookings = FakeBookingsApi();
  final FakePatientsApi patients;
  final FakePrescriptionPicker picker = FakePrescriptionPicker();

  Future<void> pump(WidgetTester tester, {String language = 'fr'}) async {
    tester.view.physicalSize = const Size(800, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(clientApp: ClientApp.patient, apiBaseUrl: 'https://api.test/api/v1'),
          ),
          preferencesStoreProvider.overrideWithValue(InMemoryPreferencesStore(AppSettings(languageCode: language))),
          sessionStorageProvider.overrideWithValue(InMemorySessionStorage(token: 'jeton', user: _user)),
          authApiProvider.overrideWithValue(_SignedInAuthApi()),
          catalogueApiProvider.overrideWithValue(FakeCatalogueApi()),
          patientsApiProvider.overrideWithValue(patients),
          bookingsApiProvider.overrideWithValue(bookings),
          prescriptionPickerProvider.overrideWithValue(picker),
        ],
        child: NadorCareApp(homeBuilder: (context) => const PatientHomeScreen(), extraRoutes: patientAppRoutes),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Patient, adresse et créneau de 9 h 30 : mène à l'écran de vérification.
  Future<void> reachSummary(WidgetTester tester, {bool asap = false}) async {
    await tapAndSettle(tester, byName('booking-profile-P1'));
    await tapAndSettle(tester, find.text(fr.continueButton));
    await tapAndSettle(tester, byName('booking-address-A1'));
    await tapAndSettle(tester, find.text(fr.continueButton));
    await tapAndSettle(tester, asap ? find.text(fr.slotAsap) : find.text('09:30'));
    await tapAndSettle(tester, find.text(fr.continueButton));
  }
}

void main() {
  testWidgets('une réservation se fait en quatre écrans puis apparaît dans mes réservations', (tester) async {
    final env = Env();
    await env.pump(tester);

    // Depuis la fiche du soin.
    await tapAndSettle(tester, byName('home-bookings'));
    expect(find.text(fr.bookingsEmpty), findsOneWidget);
    await tapAndSettle(tester, find.byType(BackButton));
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));

    // 1. Patient
    expect(find.text(fr.bookingStepPatientTitle), findsOneWidget);
    await tapAndSettle(tester, find.text(fr.continueButton));
    expect(find.text(fr.bookingChoosePatient), findsOneWidget);
    await tapAndSettle(tester, byName('booking-profile-P1'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    // 2. Adresse
    expect(find.text(fr.bookingStepAddressTitle), findsOneWidget);
    await tapAndSettle(tester, find.text(fr.continueButton));
    expect(find.text(fr.bookingChooseAddress), findsOneWidget);
    await tapAndSettle(tester, byName('booking-address-A1'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    // 3. Créneau
    expect(find.text(fr.bookingStepSlotTitle), findsOneWidget);
    expect(find.text(fr.slotNadorTime), findsOneWidget);
    expect(find.text(fr.slotAsap), findsNothing, reason: 'le service n accepte pas de demande immédiate');
    await tapAndSettle(tester, find.text(fr.continueButton));
    expect(find.text(fr.slotChoose), findsOneWidget);
    await tapAndSettle(tester, find.text('09:30'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    // 4. Vérification
    expect(find.text(fr.bookingStepSummaryTitle), findsOneWidget);
    expect(find.text('Pansement'), findsOneWidget);
    expect(find.text('Aïcha Benali'), findsOneWidget);
    expect(find.text(fr.paymentCash), findsOneWidget);
    expect(find.descendant(of: byName('price-total'), matching: find.text('100 DH')), findsOneWidget);

    await tester.enterText(byName('booking-note'), 'Sonner deux fois');
    await tapAndSettle(tester, find.text(fr.bookingConfirm));

    // Confirmation
    expect(find.text(fr.bookingSentTitle), findsOneWidget);
    expect(find.textContaining('NC-2026-000042'), findsOneWidget);
    expect(find.text(fr.statusPending), findsOneWidget);

    final draft = env.bookings.created.single.toJson();
    expect(draft['service_id'], 'S2');
    expect(draft['patient_profile_id'], 'P1');
    expect(draft['address_id'], 'A1');
    expect(draft['type'], 'scheduled');
    expect(draft['scheduled_at'], endsWith('T09:30:00+01:00'));
    expect(draft['payment_method'], 'cash');
    expect(draft['patient_note'], 'Sonner deux fois');

    await tapAndSettle(tester, find.text(fr.bookingSeeMine));
    expect(byName('booking-B1'), findsOneWidget);
    expect(find.text(fr.statusPending), findsOneWidget);
  });

  testWidgets('une adresse hors zone ne permet pas de continuer', (tester) async {
    final env = Env();
    await env.pump(tester);
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));
    await tapAndSettle(tester, byName('booking-profile-P1'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    await tapAndSettle(tester, byName('booking-address-A2'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    expect(find.text(fr.bookingAddressNotCovered), findsOneWidget);
    expect(find.text(fr.bookingStepSlotTitle), findsNothing);
  });

  testWidgets('sans patient enregistré, l écran invite à en ajouter un', (tester) async {
    final env = Env(patients: FakePatientsApi(profiles: <PatientProfile>[]));
    await env.pump(tester);
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));

    expect(find.text(fr.bookingNoProfile), findsOneWidget);
    expect(find.text(fr.continueButton), findsNothing);

    await tapAndSettle(tester, find.text(fr.profileAdd));
    expect(find.text(fr.profileNewTitle), findsOneWidget);
  });

  testWidgets('« dès que possible » est proposé quand le service est ouvert', (tester) async {
    final env = Env()..bookings.immediateAvailable = true;
    await env.pump(tester);
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));

    await env.reachSummary(tester, asap: true);
    expect(find.text(fr.slotAsap), findsOneWidget);
    await tapAndSettle(tester, find.text(fr.bookingConfirm));

    final draft = env.bookings.created.single.toJson();
    expect(draft['type'], 'immediate');
    expect(draft['scheduled_at'], isNull);
  });

  testWidgets('une majoration apparaît dans le prix avant l envoi', (tester) async {
    final env = Env()..bookings.surcharges = const <PriceLine>[PriceLine(label: 'Jour férié', amount: 5000)];
    await env.pump(tester);
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));
    await env.reachSummary(tester);

    expect(find.text('Jour férié'), findsOneWidget);
    expect(find.text('+ 50 DH'), findsOneWidget);
    expect(find.descendant(of: byName('price-total'), matching: find.text('150 DH')), findsOneWidget);
  });

  testWidgets('un soin sur ordonnance ne part pas sans la photo de l ordonnance', (tester) async {
    final env = Env();
    await env.pump(tester);
    await openService(tester, 'injection');
    await tapAndSettle(tester, find.text(fr.bookService));
    await env.reachSummary(tester);

    await tapAndSettle(tester, find.text(fr.bookingConfirm));
    expect(find.text(fr.prescriptionMissing), findsOneWidget);
    expect(env.bookings.created, isEmpty);

    // L'utilisateur referme l'appareil photo sans rien prendre : rien n'est envoyé.
    env.picker.cancel = true;
    await tapAndSettle(tester, byName('prescription-camera'));
    expect(env.bookings.uploads, isEmpty);
    expect(byName('prescription-added'), findsNothing);

    env.picker.cancel = false;
    await tapAndSettle(tester, byName('prescription-gallery'));
    expect(env.picker.calls, <bool>[true, false]);
    expect(env.bookings.uploads, <String>['ordonnance.jpg']);
    expect(byName('prescription-added'), findsOneWidget);

    await tapAndSettle(tester, find.text(fr.bookingConfirm));
    expect(env.bookings.created.single.toJson()['prescription_file_id'], 'F1');
    expect(find.text(fr.bookingSentTitle), findsOneWidget);
  });

  testWidgets('un refus du serveur est affiché et la demande peut être corrigée', (tester) async {
    final env = Env()
      ..bookings.createFailure = const ApiFailure(
        code: 'slot_unavailable',
        message: 'Ce créneau n\'est plus disponible. Choisissez-en un autre.',
        status: 422,
      );
    await env.pump(tester);
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(fr.bookService));
    await env.reachSummary(tester);

    await tapAndSettle(tester, find.text(fr.bookingConfirm));
    expect(find.text('Ce créneau n\'est plus disponible. Choisissez-en un autre.'), findsOneWidget);
    expect(find.text(fr.bookingStepSummaryTitle), findsOneWidget);

    // Retour à l'étape du créneau, les choix précédents sont conservés.
    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.text(fr.bookingStepSlotTitle), findsOneWidget);
    await tapAndSettle(tester, find.text('10:00'));
    await tapAndSettle(tester, find.text(fr.continueButton));

    env.bookings.createFailure = null;
    await tapAndSettle(tester, find.text(fr.bookingConfirm));
    expect(env.bookings.created.single.toJson()['scheduled_at'], endsWith('T10:00:00+01:00'));
  });

  testWidgets('l annulation annonce les frais avant de confirmer', (tester) async {
    final env = Env();
    env.bookings
      ..feeIfCancelledNow = 3000
      ..bookings.add(env.bookings._booking('B7', BookingStatus.confirmed));
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B7'));

    expect(find.text(fr.statusConfirmed), findsOneWidget);
    expect(find.text('Sonner deux fois'), findsOneWidget);
    expect(find.textContaining('NC-2026-000042'), findsOneWidget);

    await tapAndSettle(tester, byName('booking-cancel'));
    expect(find.text(fr.bookingCancelFee('30')), findsOneWidget);

    await tapAndSettle(tester, find.text(fr.bookingKeep));
    expect(env.bookings.cancelled, isEmpty);

    await tapAndSettle(tester, byName('booking-cancel'));
    await tapAndSettle(tester, find.text(fr.bookingCancelConfirm));

    expect(env.bookings.cancelled, <String>['B7']);
    expect(find.text(fr.statusCancelled), findsOneWidget);
    expect(find.text(fr.bookingFeeCharged('30')), findsOneWidget);
    expect(byName('booking-cancel'), findsNothing);
  });

  testWidgets('une annulation gratuite le dit, et la réservation passe dans les passées', (tester) async {
    final env = Env();
    env.bookings.bookings.add(env.bookings._booking('B7', BookingStatus.pending));
    await env.pump(tester);
    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B7'));

    await tapAndSettle(tester, byName('booking-cancel'));
    expect(find.text(fr.bookingCancelFree), findsOneWidget);
    await tapAndSettle(tester, find.text(fr.bookingCancelConfirm));

    await tapAndSettle(tester, find.byType(BackButton));
    expect(find.text(fr.bookingsEmpty), findsOneWidget);

    await tapAndSettle(tester, find.text(fr.bookingsPast));
    expect(byName('booking-B7'), findsOneWidget);
    expect(find.text(fr.statusCancelled), findsOneWidget);
  });

  testWidgets('pendant le trajet, le patient voit son soignant et l arrivée estimée', (tester) async {
    final env = Env();
    env.bookings.bookings
        .add(env.bookings._booking('B7', BookingStatus.enRoute, withProfessional: true, etaMinutes: 7));
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B7'));

    expect(find.text(fr.statusEnRoute), findsOneWidget);
    expect(find.text('Samira\nInfirmier'), findsOneWidget);
    expect(find.text(fr.trackingEta(7)), findsOneWidget);
    expect(byName('booking-report'), findsNothing);

    // Le soignant arrive : la fiche se met à jour d'elle-même.
    env.bookings.bookings[0] = env.bookings._booking('B7', BookingStatus.inProgress, withProfessional: true);
    await tester.pump(const Duration(seconds: 21));
    await tester.pumpAndSettle();

    expect(find.text(fr.statusInProgress), findsOneWidget);
    expect(byName('booking-tracking'), findsNothing);
  });

  testWidgets('sans position récente, le patient sait seulement que le soignant est en route', (tester) async {
    final env = Env();
    env.bookings.bookings.add(env.bookings._booking('B7', BookingStatus.enRoute, withProfessional: true));
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B7'));

    expect(find.text(fr.trackingOnTheWay), findsOneWidget);
  });

  testWidgets('une fois le soin terminé, le patient lit le compte rendu', (tester) async {
    final env = Env();
    env.bookings
      ..bookings.add(env.bookings._booking('B7', BookingStatus.completed, withProfessional: true))
      ..validatedReport = const Intervention(
        id: 'I1',
        bookingId: 'B7',
        status: 'validated',
        version: 2,
        amendmentReason: 'Erreur de saisie sur la tension',
        vitals: <Vital, num>{Vital.systolic: 125, Vital.temperature: 37.2},
        observations: 'Pansement refait, plaie propre.',
        acts: <ReportLine>[ReportLine(label: 'Réfection de pansement')],
        consumables: <ReportLine>[ReportLine(label: 'Compresses stériles', quantity: 4)],
        signedByName: 'Aïcha Benali',
        isSigned: true,
      );
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('bookings-scope-true'));
    await tapAndSettle(tester, byName('booking-B7'));
    expect(env.bookings.reportReads, isEmpty, reason: 'le compte rendu n est lu que sur demande');

    await tapAndSettle(tester, byName('booking-report'));

    expect(env.bookings.reportReads, <String>['B7']);
    expect(find.text('Pansement refait, plaie propre.'), findsOneWidget);
    expect(find.text(fr.vitalSystolic), findsOneWidget);
    expect(find.text('125'), findsOneWidget);
    expect(find.text('37.2'), findsOneWidget);
    expect(find.text(fr.vitalPulse), findsNothing);
    expect(find.text('Réfection de pansement'), findsOneWidget);
    expect(find.text(fr.reportLineWithQuantity('Compresses stériles', '4')), findsOneWidget);
    expect(find.text(fr.reportSignedBy('Aïcha Benali')), findsOneWidget);
    expect(find.text(fr.reportAmended('Erreur de saisie sur la tension')), findsOneWidget);
  });

  testWidgets('une téléconsultation se rejoint depuis la réservation, par un appel simulé', (tester) async {
    final env = Env();
    env.bookings.bookings.add(env.bookings._booking('B8', BookingStatus.assigned, withProfessional: true, remote: true));
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B8'));
    expect(byName('booking-remote'), findsOneWidget);
    expect(find.text(fr.paymentCard), findsOneWidget);

    await tapAndSettle(tester, byName('booking-join'));
    expect(env.bookings.callJoins, <String>['B8']);
    // Le prestataire vidéo n'est pas branché : l'écran le dit clairement.
    expect(byName('call-simulated'), findsOneWidget);

    await tapAndSettle(tester, byName('call-hang-up'));
    expect(byName('booking-join'), findsOneWidget);
  });

  testWidgets('avant l ouverture de la salle, le patient est prévenu et peut réessayer', (tester) async {
    final env = Env();
    env.bookings
      ..bookings.add(env.bookings._booking('B8', BookingStatus.assigned, withProfessional: true, remote: true))
      ..callFailure = const ApiFailure(
        code: 'teleconsultation_not_open',
        message: 'La salle de téléconsultation n est pas ouverte pour le moment.',
        status: 409,
      );
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B8'));
    await tapAndSettle(tester, byName('booking-join'));

    expect(byName('call-error'), findsOneWidget);
    expect(find.text(fr.teleconsultationRoomHelp), findsOneWidget);
    expect(byName('call-simulated'), findsNothing);
  });

  testWidgets('un soin à domicile ne propose pas d appel vidéo', (tester) async {
    final env = Env();
    env.bookings.bookings.add(env.bookings._booking('B7', BookingStatus.assigned, withProfessional: true));
    await env.pump(tester);

    await tapAndSettle(tester, byName('home-bookings'));
    await tapAndSettle(tester, byName('booking-B7'));

    expect(byName('booking-join'), findsNothing);
    expect(byName('booking-remote'), findsNothing);
  });

  testWidgets('en arabe, le parcours se lit de droite à gauche et l heure reste lisible', (tester) async {
    final env = Env();
    await env.pump(tester, language: 'ar');
    await openService(tester, 'pansement');
    await tapAndSettle(tester, find.text(ar.bookService));

    expect(find.text(ar.bookingStepPatientTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.bookingStepPatientTitle))), TextDirection.rtl);

    await tapAndSettle(tester, byName('booking-profile-P1'));
    await tapAndSettle(tester, find.text(ar.continueButton));
    await tapAndSettle(tester, byName('booking-address-A1'));
    await tapAndSettle(tester, find.text(ar.continueButton));

    expect(find.text('09:30'), findsOneWidget);
    expect(find.text(ar.slotNadorTime), findsOneWidget);
  });

  test('un créneau garde l heure de Nador, quel que soit le fuseau du téléphone', () {
    final slot = BookingSlot.fromIso('2026-12-08T09:30:00+01:00');

    expect(slot.time, '09:30');
    expect(slot.startsAt, '2026-12-08T09:30:00+01:00');
    expect(apiDate(DateTime(2026, 3, 5)), '2026-03-05');
    expect(NcSpacing.touchTarget, greaterThanOrEqualTo(48));
  });
}

/// Ouvre directement la fiche d'un soin, comme le ferait un appui dans le catalogue.
Future<void> openService(WidgetTester tester, String slug) async {
  GoRouter.of(tester.element(find.byType(PatientHomeScreen))).push(routeService(slug));
  await tester.pumpAndSettle();
}
