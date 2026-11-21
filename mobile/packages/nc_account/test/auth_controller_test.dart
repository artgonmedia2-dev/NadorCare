import 'package:flutter_test/flutter_test.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import 'support/fakes.dart';

void main() {
  const phone = '+212612345678';

  test('sans session enregistrée, personne n est connecté', () async {
    final env = TestEnvironment();
    final container = env.container();

    expect(container.read(authControllerProvider), isA<AuthInitializing>());
    await container.read(authControllerProvider.notifier).bootstrap();

    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    expect(env.api.meCalls, 0);
  });

  test('un nouveau numéro exige le consentement, puis la session est enregistrée', () async {
    final env = TestEnvironment();
    final container = env.container();
    final auth = container.read(authControllerProvider.notifier);

    await expectLater(
      auth.verifyOtp(phone: phone, code: '123456', acceptTerms: false),
      throwsA(isA<ApiFailure>().having((failure) => failure.code, 'code', ApiFailure.consentRequired)),
    );
    expect(env.session.token, isNull);

    await auth.verifyOtp(phone: phone, code: '123456', acceptTerms: true);

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(env.session.token, 'jeton-de-test');
    expect(env.session.user?.id, testUser.id);
    expect(env.api.verifications.last.app, ClientApp.patient);
    expect(env.api.verifications.last.locale, 'fr');
  });

  test('l application professionnel s annonce comme telle au serveur', () async {
    final env = TestEnvironment(clientApp: ClientApp.pro);
    final container = env.container();

    await container.read(authControllerProvider.notifier).verifyOtp(phone: phone, code: '123456', acceptTerms: true);

    expect(env.api.verifications.single.app, ClientApp.pro);
  });

  test('un code faux ne crée aucune session', () async {
    final env = TestEnvironment();
    final container = env.container();

    await expectLater(
      container.read(authControllerProvider.notifier).verifyOtp(phone: phone, code: '000000', acceptTerms: true),
      throwsA(isA<ApiFailure>()),
    );

    expect(env.session.token, isNull);
    expect(container.read(authControllerProvider), isNot(isA<AuthSignedIn>()));
  });

  test('une session enregistrée est restaurée au lancement', () async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    final container = env.container();

    await container.read(authControllerProvider.notifier).bootstrap();

    final state = container.read(authControllerProvider);
    expect(state, isA<AuthSignedIn>());
    expect((state as AuthSignedIn).user.phone, testUser.phone);
  });

  test('un jeton expiré efface la session', () async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    env.api.meFailure = const ApiFailure(code: ApiFailure.unauthenticated, status: 401);
    final container = env.container();

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
    expect(env.session.token, isNull);
    expect(env.session.user, isNull);
  });

  test('un compte suspendu est déconnecté', () async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    env.api.meFailure = const ApiFailure(code: ApiFailure.accountSuspended, status: 403);
    final container = env.container();

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
  });

  test('sans réseau, l application s ouvre avec le dernier compte connu', () async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    env.api.meFailure = const ApiFailure(code: ApiFailure.network);
    final container = env.container();

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    expect(env.session.token, 'jeton');
  });

  test('le verrouillage biométrique bloque l accès jusqu à la reconnaissance', () async {
    final env = TestEnvironment(
      settings: const AppSettings(languageCode: 'fr', biometricEnabled: true),
      session: InMemorySessionStorage(token: 'jeton', user: testUser),
      biometric: FakeBiometricService(accepts: false),
    );
    final container = env.container();
    final auth = container.read(authControllerProvider.notifier);

    await auth.bootstrap();
    expect(container.read(authControllerProvider), isA<AuthLocked>());
    expect(env.api.meCalls, 0, reason: 'aucune donnée n est chargée tant que l application est verrouillée');

    expect(await auth.unlock('raison'), isFalse);
    expect(container.read(authControllerProvider), isA<AuthLocked>());

    env.biometric.accepts = true;
    expect(await auth.unlock('raison'), isTrue);
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });

  test('si l appareil n a plus de biométrie, le verrouillage ne bloque pas le compte', () async {
    final env = TestEnvironment(
      settings: const AppSettings(languageCode: 'fr', biometricEnabled: true),
      session: InMemorySessionStorage(token: 'jeton', user: testUser),
      biometric: FakeBiometricService(available: false),
    );
    final container = env.container();

    await container.read(authControllerProvider.notifier).bootstrap();

    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
  });

  test('la déconnexion révoque le jeton et efface la session, même hors ligne', () async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    final container = env.container();
    final auth = container.read(authControllerProvider.notifier);
    await auth.bootstrap();

    await auth.logout();

    expect(env.api.logoutCalls, 1);
    expect(env.session.token, isNull);
    expect(container.read(authControllerProvider), isA<AuthSignedOut>());
  });

  test('les réglages sont enregistrés et une langue inconnue est refusée', () async {
    final env = TestEnvironment(settings: const AppSettings());
    final container = env.container();
    final settings = container.read(settingsControllerProvider.notifier);

    expect(container.read(settingsControllerProvider).languageCode, isNull);

    await settings.setLanguage('de');
    expect(container.read(settingsControllerProvider).languageCode, isNull);

    await settings.setLanguage('ar');
    await settings.setTextSize(NcTextSize.extraLarge);
    await settings.setBiometricEnabled(true);

    expect(env.preferences.settings, const AppSettings(languageCode: 'ar', textSize: NcTextSize.extraLarge, biometricEnabled: true));
  });
}
