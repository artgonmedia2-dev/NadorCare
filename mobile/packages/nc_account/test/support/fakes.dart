import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

const AppUser testUser = AppUser(
  id: '01TESTUSER',
  phone: '+212612345678',
  name: 'Fatima Zahra',
  locale: 'fr',
  status: 'active',
  roles: <String>['patient'],
);

/// Imite le serveur : un seul code valable, des numéros déjà inscrits ou non.
class FakeAuthApi implements AuthApi {
  FakeAuthApi({this.validCode = '123456', Set<String>? registeredPhones})
      : registeredPhones = registeredPhones ?? <String>{};

  final String validCode;
  final Set<String> registeredPhones;

  int resendIn = 0;
  ApiFailure? requestFailure;
  ApiFailure? meFailure;
  AppUser meUser = testUser;

  final List<String> requestedPhones = <String>[];
  final List<({String phone, String code, bool acceptTerms, ClientApp app, String? locale})> verifications = [];
  final List<({String? name, String? locale})> updates = [];
  int logoutCalls = 0;
  int meCalls = 0;

  @override
  Future<OtpChallenge> requestOtp(String phone) async {
    requestedPhones.add(phone);
    if (requestFailure != null) {
      throw requestFailure!;
    }
    return OtpChallenge(expiresIn: 300, resendIn: resendIn);
  }

  @override
  Future<AuthSession> verifyOtp({
    required String phone,
    required String code,
    required ClientApp app,
    required String deviceName,
    required bool acceptTerms,
    String? locale,
  }) async {
    verifications.add((phone: phone, code: code, acceptTerms: acceptTerms, app: app, locale: locale));

    if (code != validCode) {
      throw const ApiFailure(code: ApiFailure.otpInvalid, message: 'Message du serveur : code refusé', status: 422);
    }

    final isNew = !registeredPhones.contains(phone);
    if (isNew && !acceptTerms) {
      throw const ApiFailure(code: ApiFailure.consentRequired, message: 'Consentement requis', status: 422);
    }

    registeredPhones.add(phone);
    return AuthSession(token: 'jeton-de-test', user: meUser, isNewUser: isNew);
  }

  @override
  Future<void> logout() async => logoutCalls++;

  @override
  Future<AppUser> me() async {
    meCalls++;
    if (meFailure != null) {
      throw meFailure!;
    }
    return meUser;
  }

  @override
  Future<AppUser> updateMe({String? name, String? locale}) async {
    updates.add((name: name, locale: locale));
    meUser = meUser.copyWith(name: name, locale: locale);
    return meUser;
  }
}

class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true, this.accepts = true});

  bool available;
  bool accepts;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return accepts;
  }
}

/// Tout ce qu'un test peut préparer puis inspecter.
class TestEnvironment {
  TestEnvironment({
    this.clientApp = ClientApp.patient,
    AppSettings settings = const AppSettings(languageCode: 'fr'),
    FakeAuthApi? api,
    InMemorySessionStorage? session,
    FakeBiometricService? biometric,
  })  : api = api ?? FakeAuthApi(),
        session = session ?? InMemorySessionStorage(),
        biometric = biometric ?? FakeBiometricService(),
        preferences = InMemoryPreferencesStore(settings);

  final ClientApp clientApp;
  final FakeAuthApi api;
  final InMemorySessionStorage session;
  final FakeBiometricService biometric;
  final InMemoryPreferencesStore preferences;

  ProviderContainer container() {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig(clientApp: clientApp, apiBaseUrl: 'https://api.test/api/v1')),
        preferencesStoreProvider.overrideWithValue(preferences),
        sessionStorageProvider.overrideWithValue(session),
        biometricServiceProvider.overrideWithValue(biometric),
        authApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Lance l'application complète sur un écran assez haut pour tout afficher.
  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container(),
        child: NadorCareApp(
          homeBuilder: (context) => const Scaffold(body: Center(child: Text('ACCUEIL', key: ValueKey<String>('home')))),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}
