import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nadorcare_patient/home_screen.dart';
import 'package:nadorcare_patient/patients/location_service.dart';
import 'package:nadorcare_patient/patients/patient_routes.dart';
import 'package:nadorcare_patient/patients/patients_providers.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';
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

/// Imite le serveur pour les profils et les adresses.
class FakePatientsApi implements PatientsApi {
  final List<PatientProfile> profiles = <PatientProfile>[];
  final List<PatientAddress> addresses = <PatientAddress>[];
  final List<String> detailReads = <String>[];

  ApiFailure? listFailure;
  ApiFailure? writeFailure;
  bool coverNewAddresses = true;
  int _next = 1;

  PatientProfile _profile(String id, PatientProfileDraft draft) {
    return PatientProfile(
      id: id,
      firstName: draft.firstName,
      lastName: draft.lastName,
      relationship: draft.relationship,
      birthDate: draft.birthDate,
      sex: draft.sex,
      phone: draft.phone,
      careNotes: draft.careNotes,
      hasCareNotes: (draft.careNotes ?? '').isNotEmpty,
    );
  }

  PatientAddress _address(String id, PatientAddressDraft draft) {
    return PatientAddress(
      id: id,
      label: draft.label,
      line: draft.line,
      city: 'Nador',
      latitude: draft.latitude,
      longitude: draft.longitude,
      accessNotes: draft.accessNotes,
      isCovered: coverNewAddresses,
      zoneName: coverNewAddresses ? 'Nador centre' : null,
    );
  }

  void _failIfNeeded() {
    if (writeFailure != null) {
      throw writeFailure!;
    }
  }

  @override
  Future<List<PatientProfile>> listProfiles() async {
    if (listFailure != null) {
      throw listFailure!;
    }
    return List<PatientProfile>.of(profiles);
  }

  @override
  Future<PatientProfile> getProfile(String id) async {
    detailReads.add(id);
    return profiles.firstWhere((profile) => profile.id == id);
  }

  @override
  Future<PatientProfile> createProfile(PatientProfileDraft draft) async {
    _failIfNeeded();
    final profile = _profile('P${_next++}', draft);
    profiles.add(profile);
    return profile;
  }

  @override
  Future<PatientProfile> updateProfile(String id, PatientProfileDraft draft) async {
    _failIfNeeded();
    final profile = _profile(id, draft);
    profiles[profiles.indexWhere((item) => item.id == id)] = profile;
    return profile;
  }

  @override
  Future<void> deleteProfile(String id) async {
    _failIfNeeded();
    profiles.removeWhere((profile) => profile.id == id);
  }

  @override
  Future<List<PatientAddress>> listAddresses() async {
    if (listFailure != null) {
      throw listFailure!;
    }
    return List<PatientAddress>.of(addresses);
  }

  @override
  Future<PatientAddress> createAddress(PatientAddressDraft draft) async {
    _failIfNeeded();
    final address = _address('A${_next++}', draft);
    addresses.add(address);
    return address;
  }

  @override
  Future<PatientAddress> updateAddress(String id, PatientAddressDraft draft) async {
    _failIfNeeded();
    final address = _address(id, draft);
    addresses[addresses.indexWhere((item) => item.id == id)] = address;
    return address;
  }

  @override
  Future<void> deleteAddress(String id) async {
    _failIfNeeded();
    addresses.removeWhere((address) => address.id == id);
  }
}

class FakeLocationService implements LocationService {
  LocationFailureReason? failure;
  int calls = 0;

  @override
  Future<GeoPoint> currentPosition() async {
    calls++;
    if (failure != null) {
      throw LocationFailure(failure!);
    }
    return (latitude: 35.1688, longitude: -2.9335);
  }
}

/// Compte déjà connecté ; `me()` renvoie le compte sans réseau.
class _SignedInAuthApi implements AuthApi {
  @override
  Future<AppUser> me() async => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder byName(String name) => find.byKey(ValueKey<String>(name));

Future<void> pumpPatientApp(
  WidgetTester tester, {
  required FakePatientsApi api,
  FakeLocationService? location,
  String language = 'fr',
}) async {
  tester.view.physicalSize = const Size(800, 4200);
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
        patientsApiProvider.overrideWithValue(api),
        locationServiceProvider.overrideWithValue(location ?? FakeLocationService()),
      ],
      child: NadorCareApp(homeBuilder: (context) => const PatientHomeScreen(), extraRoutes: patientRoutes),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  group('patients', () {
    testWidgets('sans patient, l écran explique quoi faire puis la fiche créée apparaît dans la liste', (tester) async {
      final api = FakePatientsApi();
      await pumpPatientApp(tester, api: api);

      await tapAndSettle(tester, byName('home-profiles'));
      expect(find.text(fr.profilesEmpty), findsOneWidget);

      await tapAndSettle(tester, find.text(fr.profileAdd));
      expect(find.text(fr.profileNewTitle), findsOneWidget);
      expect(find.text(fr.careNotesPrivacy), findsOneWidget);

      await tapAndSettle(tester, byName('relationship-PatientRelationship.parent'));
      await tester.enterText(byName('first-name-field'), 'Aïcha');
      await tester.enterText(byName('last-name-field'), 'Benali');
      await tapAndSettle(tester, byName('sex-female'));
      await tester.enterText(byName('care-notes-field'), 'Diabète de type 2');
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text(fr.homeProfiles), findsOneWidget, reason: 'retour à la liste');
      expect(find.text('Aïcha Benali'), findsOneWidget);
      expect(find.text(fr.relationshipParent), findsOneWidget);

      final created = api.profiles.single;
      expect(created.relationship, PatientRelationship.parent);
      expect(created.sex, 'female');
      expect(created.careNotes, 'Diabète de type 2');
    });

    testWidgets('les champs obligatoires sont signalés sans appeler le serveur', (tester) async {
      final api = FakePatientsApi();
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-profiles'));
      await tapAndSettle(tester, find.text(fr.profileAdd));

      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text(fr.fieldRequired), findsNWidgets(3));
      expect(api.profiles, isEmpty);
    });

    testWidgets('la modification charge la fiche détaillée, seule à contenir les notes de soin', (tester) async {
      final api = FakePatientsApi()
        ..profiles.add(
          const PatientProfile(
            id: 'P9',
            firstName: 'Aïcha',
            lastName: 'Benali',
            relationship: PatientRelationship.parent,
            hasCareNotes: true,
            careNotes: 'Allergie à la pénicilline',
          ),
        );
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-profiles'));

      expect(api.detailReads, isEmpty, reason: 'la liste ne lit pas les données de santé');
      expect(find.text('Allergie à la pénicilline'), findsNothing);

      await tapAndSettle(tester, byName('profile-P9'));

      expect(api.detailReads, <String>['P9']);
      expect(find.text('Allergie à la pénicilline'), findsOneWidget);

      await tester.enterText(byName('first-name-field'), 'Aicha');
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text('Aicha Benali'), findsOneWidget);
      expect(api.profiles.single.careNotes, 'Allergie à la pénicilline');
    });

    testWidgets('un refus du serveur est affiché et la fiche reste ouverte', (tester) async {
      final api = FakePatientsApi()
        ..writeFailure = const ApiFailure(
          code: 'self_profile_exists',
          message: 'Ce compte a déjà un profil pour vous-même.',
          status: 422,
        );
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-profiles'));
      await tapAndSettle(tester, find.text(fr.profileAdd));

      await tapAndSettle(tester, byName('relationship-PatientRelationship.self'));
      await tester.enterText(byName('first-name-field'), 'Karim');
      await tester.enterText(byName('last-name-field'), 'Benali');
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text('Ce compte a déjà un profil pour vous-même.'), findsOneWidget);
      expect(find.text(fr.profileNewTitle), findsOneWidget);
    });

    testWidgets('la suppression demande confirmation', (tester) async {
      final api = FakePatientsApi()
        ..profiles.add(
          const PatientProfile(id: 'P9', firstName: 'Aïcha', lastName: 'Benali', relationship: PatientRelationship.parent),
        );
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-profiles'));
      await tapAndSettle(tester, byName('profile-P9'));

      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete));
      expect(find.text(fr.profileDeleteTitle), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.cancel));
      expect(api.profiles, hasLength(1));

      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete));
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete).last);

      expect(api.profiles, isEmpty);
      expect(find.text(fr.profilesEmpty), findsOneWidget);
    });

    testWidgets('sans réseau, la liste propose de réessayer', (tester) async {
      final api = FakePatientsApi()..listFailure = const ApiFailure(code: ApiFailure.network);
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-profiles'));

      expect(find.text(fr.errorNetwork), findsOneWidget);
      expect(find.text(fr.profileAdd), findsNothing);

      api.listFailure = null;
      await tapAndSettle(tester, find.text(fr.retry));

      expect(find.text(fr.profilesEmpty), findsOneWidget);
    });

    testWidgets('en arabe, l écran des patients se lit de droite à gauche', (tester) async {
      await pumpPatientApp(tester, api: FakePatientsApi(), language: 'ar');
      await tapAndSettle(tester, byName('home-profiles'));
      await tapAndSettle(tester, find.text(ar.profileAdd));

      expect(find.text(ar.relationshipParent), findsOneWidget);
      expect(Directionality.of(tester.element(find.text(ar.relationshipParent))), TextDirection.rtl);
      expect(
        Directionality.of(tester.element(find.descendant(of: byName('patient-phone-field'), matching: find.byType(EditableText)))),
        TextDirection.ltr,
      );
    });
  });

  group('adresses', () {
    testWidgets('une adresse s enregistre avec la position du téléphone et affiche sa couverture', (tester) async {
      final api = FakePatientsApi();
      final location = FakeLocationService();
      await pumpPatientApp(tester, api: api, location: location);

      await tapAndSettle(tester, byName('home-addresses'));
      expect(find.text(fr.addressesEmpty), findsOneWidget);
      await tapAndSettle(tester, find.text(fr.addressAdd));

      await tester.enterText(byName('address-label-field'), 'Chez ma mère');
      await tester.enterText(byName('address-line-field'), '12 rue Al Massira');
      await tester.enterText(byName('access-notes-field'), 'Porte verte, 2e étage');
      await tapAndSettle(tester, find.text(fr.locationUse));
      expect(byName('location-set'), findsOneWidget);
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text('Chez ma mère'), findsOneWidget);
      expect(find.text(fr.addressCovered), findsOneWidget);

      final saved = api.addresses.single;
      expect(saved.latitude, 35.1688);
      expect(saved.longitude, -2.9335);
      expect(saved.accessNotes, 'Porte verte, 2e étage');
      expect(location.calls, 1);
    });

    testWidgets('sans position, l adresse n est pas envoyée', (tester) async {
      final api = FakePatientsApi();
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-addresses'));
      await tapAndSettle(tester, find.text(fr.addressAdd));

      await tester.enterText(byName('address-label-field'), 'Maison');
      await tester.enterText(byName('address-line-field'), '12 rue Al Massira');
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text(fr.locationMissing), findsOneWidget);
      expect(api.addresses, isEmpty);
    });

    testWidgets('chaque refus de localisation a son explication', (tester) async {
      final location = FakeLocationService();
      await pumpPatientApp(tester, api: FakePatientsApi(), location: location);
      await tapAndSettle(tester, byName('home-addresses'));
      await tapAndSettle(tester, find.text(fr.addressAdd));

      for (final (reason, message) in <(LocationFailureReason, String)>[
        (LocationFailureReason.denied, fr.locationDenied),
        (LocationFailureReason.disabled, fr.locationDisabled),
        (LocationFailureReason.unavailable, fr.locationUnavailable),
      ]) {
        location.failure = reason;
        await tapAndSettle(tester, find.text(fr.locationUse));
        expect(find.text(message), findsOneWidget);
        expect(byName('location-set'), findsNothing);
      }
    });

    testWidgets('une adresse hors zone est enregistrée et signalée comme non desservie', (tester) async {
      final api = FakePatientsApi()..coverNewAddresses = false;
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-addresses'));
      await tapAndSettle(tester, find.text(fr.addressAdd));

      await tester.enterText(byName('address-label-field'), 'Maison');
      await tester.enterText(byName('address-line-field'), 'Douar Ouled Ali');
      await tapAndSettle(tester, find.text(fr.locationUse));
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text(fr.addressNotCovered), findsOneWidget);
      expect(find.text(fr.addressCovered), findsNothing);
      expect(api.addresses, hasLength(1));
    });

    testWidgets('une adresse existante se modifie sans redemander la position, et se supprime', (tester) async {
      final api = FakePatientsApi()
        ..addresses.add(
          const PatientAddress(
            id: 'A9',
            label: 'Maison',
            line: '12 rue Al Massira',
            city: 'Nador',
            latitude: 35.17,
            longitude: -2.93,
            isCovered: true,
          ),
        );
      final location = FakeLocationService();
      await pumpPatientApp(tester, api: api, location: location);
      await tapAndSettle(tester, byName('home-addresses'));
      await tapAndSettle(tester, byName('address-A9'));

      expect(find.text(fr.addressEditTitle), findsOneWidget);
      expect(byName('location-set'), findsOneWidget);

      await tester.enterText(byName('address-label-field'), 'Appartement');
      await tapAndSettle(tester, find.text(fr.save));

      expect(find.text('Appartement'), findsOneWidget);
      expect(api.addresses.single.latitude, 35.17);
      expect(location.calls, 0);

      await tapAndSettle(tester, byName('address-A9'));
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete));
      expect(find.text(fr.addressDeleteTitle), findsOneWidget);
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete).last);

      expect(api.addresses, isEmpty);
      expect(find.text(fr.addressesEmpty), findsOneWidget);
    });

    testWidgets('une adresse utilisée par un soin ne se supprime pas : le message du serveur est affiché', (tester) async {
      final api = FakePatientsApi()
        ..addresses.add(
          const PatientAddress(
            id: 'A9',
            label: 'Maison',
            line: '12 rue Al Massira',
            city: 'Nador',
            latitude: 35.17,
            longitude: -2.93,
            isCovered: true,
          ),
        )
        ..writeFailure = const ApiFailure(
          code: 'address_in_use',
          message: 'Un soin est prévu ou en cours à cette adresse.',
          status: 409,
        );
      await pumpPatientApp(tester, api: api);
      await tapAndSettle(tester, byName('home-addresses'));
      await tapAndSettle(tester, byName('address-A9'));

      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete));
      await tapAndSettle(tester, find.widgetWithText(TextButton, fr.delete).last);

      expect(find.text('Un soin est prévu ou en cours à cette adresse.'), findsOneWidget);
      expect(api.addresses, hasLength(1));
    });
  });

  test('les brouillons envoient null pour effacer un champ vidé', () {
    final profile = PatientProfileDraft(
      firstName: 'Aïcha',
      lastName: 'Benali',
      relationship: PatientRelationship.parent,
      birthDate: DateTime(1948, 3, 2),
      phone: '',
      careNotes: '',
    ).toJson();

    expect(profile['birth_date'], '1948-03-02');
    expect(profile['relationship'], 'parent');
    expect(profile.containsKey('care_notes'), isTrue);
    expect(profile['care_notes'], isNull);
    expect(profile['phone'], isNull);

    const address = PatientAddressDraft(label: 'Maison', line: 'Rue 1', latitude: 35.1, longitude: -2.9, accessNotes: '');
    expect(address.toJson()['access_notes'], isNull);
  });
}
