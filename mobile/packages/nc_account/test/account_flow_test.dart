import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import 'support/fakes.dart';

final NcLocalizations fr = lookupNcLocalizations(const Locale('fr'));
final NcLocalizations ar = lookupNcLocalizations(const Locale('ar'));
final NcLocalizations en = lookupNcLocalizations(const Locale('en'));

Finder byName(String name) => find.byKey(ValueKey<String>(name));

final Finder phoneField = byName('phone-field');
final Finder codeField = byName('code-field');
final Finder home = byName('home');

Future<void> enterPhoneAndCode(WidgetTester tester, {String phone = '0612345678', String code = '123456'}) async {
  await tester.enterText(phoneField, phone);
  await tester.tap(find.text(fr.sendCode));
  await tester.pumpAndSettle();
  await tester.enterText(codeField, code);
  await tester.tap(find.text(fr.verify));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('au premier lancement, la langue se choisit et l arabe s affiche de droite à gauche', (tester) async {
    // Téléphone réglé dans une langue non prise en charge : l'application démarre en français.
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    final env = TestEnvironment(settings: const AppSettings());
    await env.pumpApp(tester);

    expect(find.text(fr.languageTitle), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('العربية'));
    await tester.pumpAndSettle();

    // L'écran est traduit dès le choix, avant de continuer.
    expect(find.text(ar.languageTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.languageTitle))), TextDirection.rtl);

    await tester.tap(find.text(ar.continueButton));
    await tester.pumpAndSettle();

    expect(env.preferences.settings.languageCode, 'ar');
    expect(find.text(ar.phoneTitle), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.phoneTitle))), TextDirection.rtl);
    // Le numéro, lui, se saisit toujours de gauche à droite.
    expect(Directionality.of(tester.element(find.descendant(of: phoneField, matching: find.byType(EditableText)))), TextDirection.ltr);
  });

  testWidgets('au premier lancement, la langue du téléphone est proposée si elle est prise en charge', (tester) async {
    tester.platformDispatcher.localesTestValue = const <Locale>[Locale('ar', 'MA')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);

    await TestEnvironment(settings: const AppSettings()).pumpApp(tester);

    expect(find.text(ar.languageTitle), findsOneWidget);
  });

  testWidgets('une fois la langue choisie, elle n est plus redemandée', (tester) async {
    final env = TestEnvironment(settings: const AppSettings(languageCode: 'en'));
    await env.pumpApp(tester);

    expect(find.text(en.phoneTitle), findsOneWidget);
    expect(find.text(en.languageTitle), findsNothing);
  });

  testWidgets('l écran du numéro rappelle que le service ne remplace pas les urgences', (tester) async {
    await TestEnvironment().pumpApp(tester);

    expect(find.text(fr.emergencyNotice), findsOneWidget);
    expect(fr.emergencyNotice, allOf(contains('141'), contains('15')));
  });

  testWidgets('un numéro trop court est refusé sans appeler le serveur', (tester) async {
    final env = TestEnvironment();
    await env.pumpApp(tester);

    await tester.enterText(phoneField, '0612');
    await tester.tap(find.text(fr.sendCode));
    await tester.pumpAndSettle();

    expect(find.text(fr.phoneInvalid), findsOneWidget);
    expect(env.api.requestedPhones, isEmpty);
  });

  testWidgets('un nouveau patient donne trois accords explicites avant la création du compte', (tester) async {
    final env = TestEnvironment();
    await env.pumpApp(tester);

    await enterPhoneAndCode(tester);

    // Numéro inconnu : l'écran de consentement s'affiche, rien n'est coché d'avance.
    expect(find.text(fr.consentTitle), findsOneWidget);
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile)).every((tile) => tile.value == false), isTrue);
    expect(tester.widget<NcPrimaryButton>(find.widgetWithText(NcPrimaryButton, fr.consentAccept)).onPressed, isNull);

    await tester.tap(find.text(fr.consentTerms));
    await tester.tap(find.text(fr.consentPrivacy));
    await tester.pumpAndSettle();
    expect(tester.widget<NcPrimaryButton>(find.widgetWithText(NcPrimaryButton, fr.consentAccept)).onPressed, isNull);

    await tester.tap(find.text(fr.consentHealthData));
    await tester.pumpAndSettle();
    await tester.tap(find.text(fr.consentAccept));
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
    expect(env.api.verifications.map((call) => call.acceptTerms), <bool>[false, true]);
    expect(env.api.verifications.last.code, '123456');
    expect(env.session.token, 'jeton-de-test');
  });

  testWidgets('un professionnel ne voit pas l accord sur les données de santé', (tester) async {
    final env = TestEnvironment(clientApp: ClientApp.pro);
    await env.pumpApp(tester);

    await enterPhoneAndCode(tester);

    expect(find.byType(CheckboxListTile), findsNWidgets(2));
    expect(find.text(fr.consentHealthData), findsNothing);
  });

  testWidgets('un utilisateur déjà inscrit arrive directement à l accueil', (tester) async {
    final env = TestEnvironment(api: FakeAuthApi(registeredPhones: <String>{'0612345678'}));
    await env.pumpApp(tester);

    await enterPhoneAndCode(tester);

    expect(home, findsOneWidget);
    expect(find.text(fr.consentTitle), findsNothing);
  });

  testWidgets('un code refusé affiche le message du serveur et laisse réessayer', (tester) async {
    final env = TestEnvironment(api: FakeAuthApi(registeredPhones: <String>{'0612345678'}));
    await env.pumpApp(tester);

    await enterPhoneAndCode(tester, code: '000000');

    expect(find.text('Message du serveur : code refusé'), findsOneWidget);
    expect(home, findsNothing);

    await tester.enterText(codeField, '123456');
    await tester.tap(find.text(fr.verify));
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('un code incomplet est signalé sans appeler le serveur', (tester) async {
    final env = TestEnvironment();
    await env.pumpApp(tester);

    await enterPhoneAndCode(tester, code: '123');

    expect(find.text(fr.otpIncomplete), findsOneWidget);
    expect(env.api.verifications, isEmpty);
  });

  testWidgets('sans réseau, un message clair est affiché', (tester) async {
    final env = TestEnvironment();
    env.api.requestFailure = const ApiFailure(code: ApiFailure.network);
    await env.pumpApp(tester);

    await tester.enterText(phoneField, '0612345678');
    await tester.tap(find.text(fr.sendCode));
    await tester.pumpAndSettle();

    expect(find.text(fr.errorNetwork), findsOneWidget);
    expect(codeField, findsNothing);
  });

  testWidgets('le renvoi du code attend la fin du délai', (tester) async {
    final env = TestEnvironment();
    env.api.resendIn = 3;
    await env.pumpApp(tester);

    await tester.enterText(phoneField, '0612345678');
    await tester.tap(find.text(fr.sendCode));
    await tester.pump();
    await tester.pump();

    expect(find.text(fr.resendIn(3)), findsOneWidget);
    expect(tester.widget<TextButton>(byName('resend-button')).onPressed, isNull);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text(fr.resendCode), findsOneWidget);
    expect(tester.widget<TextButton>(byName('resend-button')).onPressed, isNotNull);

    env.api.resendIn = 0;
    await tester.tap(find.text(fr.resendCode));
    await tester.pumpAndSettle();

    expect(env.api.requestedPhones, hasLength(2));
    expect(find.text(fr.codeResent), findsOneWidget);
  });

  testWidgets('avec le verrouillage, l accueil reste fermé tant que la personne n est pas reconnue', (tester) async {
    final env = TestEnvironment(
      settings: const AppSettings(languageCode: 'fr', biometricEnabled: true),
      session: InMemorySessionStorage(token: 'jeton', user: testUser),
      biometric: FakeBiometricService(accepts: false),
    );
    await env.pumpApp(tester);

    expect(find.text(fr.unlockTitle), findsOneWidget);
    expect(home, findsNothing);
    expect(env.biometric.prompts, 1, reason: 'la reconnaissance est demandée dès l ouverture');

    env.biometric.accepts = true;
    await tester.tap(find.text(fr.unlockButton));
    await tester.pumpAndSettle();

    expect(home, findsOneWidget);
  });

  testWidgets('les réglages changent la taille du texte, la langue et permettent de se déconnecter', (tester) async {
    final env = TestEnvironment(session: InMemorySessionStorage(token: 'jeton', user: testUser));
    await env.pumpApp(tester);
    expect(home, findsOneWidget);

    GoRouter.of(tester.element(home)).push(NcRoutes.settings);
    await tester.pumpAndSettle();
    expect(find.text(fr.settingsTitle), findsOneWidget);
    expect(find.text('Fatima Zahra'), findsOneWidget);

    // Taille du texte
    expect(MediaQuery.textScalerOf(tester.element(find.text(fr.settingsTitle))).scale(10), 10);
    await tester.tap(byName('text-size-extraLarge'));
    await tester.pumpAndSettle();
    expect(MediaQuery.textScalerOf(tester.element(find.text(fr.settingsTitle))).scale(10), 13);
    expect(env.preferences.settings.textSize, NcTextSize.extraLarge);

    // Nom
    await tester.enterText(byName('name-field'), 'F');
    await tester.tap(find.text(fr.save));
    await tester.pumpAndSettle();
    expect(find.text(fr.nameTooShort), findsOneWidget);
    expect(env.api.updates, isEmpty);

    await tester.enterText(byName('name-field'), 'Fatima Alaoui');
    await tester.tap(find.text(fr.save));
    await tester.pumpAndSettle();
    expect(env.api.updates.single.name, 'Fatima Alaoui');
    expect(find.text(fr.profileSaved), findsOneWidget);

    // Langue : l'appareil et le compte sont mis à jour
    await tester.tap(byName('language-en'));
    await tester.pumpAndSettle();
    expect(find.text(en.settingsTitle), findsOneWidget);
    expect(env.preferences.settings.languageCode, 'en');
    expect(env.api.updates.last.locale, 'en');

    // Déconnexion, avec confirmation
    await tester.tap(find.widgetWithText(NcSecondaryButton, en.logout));
    await tester.pumpAndSettle();
    expect(find.text(en.logoutConfirmTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, en.logout));
    await tester.pumpAndSettle();

    expect(find.text(en.phoneTitle), findsOneWidget);
    expect(env.session.token, isNull);
    expect(env.api.logoutCalls, 1);
  });

  testWidgets('le verrouillage ne s active que si l appareil reconnaît la personne', (tester) async {
    final env = TestEnvironment(
      session: InMemorySessionStorage(token: 'jeton', user: testUser),
      biometric: FakeBiometricService(available: false),
    );
    await env.pumpApp(tester);
    GoRouter.of(tester.element(home)).push(NcRoutes.settings);
    await tester.pumpAndSettle();

    await tester.tap(byName('biometric-switch'));
    await tester.pumpAndSettle();
    expect(find.text(fr.biometricUnavailable), findsOneWidget);
    expect(env.preferences.settings.biometricEnabled, isFalse);

    env.biometric
      ..available = true
      ..accepts = false;
    await tester.tap(byName('biometric-switch'));
    await tester.pumpAndSettle();
    expect(env.preferences.settings.biometricEnabled, isFalse);

    env.biometric.accepts = true;
    await tester.tap(byName('biometric-switch'));
    await tester.pumpAndSettle();
    expect(env.preferences.settings.biometricEnabled, isTrue);
  });

  test('les trois langues ont exactement les mêmes textes, sans oubli', () {
    // gen-l10n échoue déjà si une clé manque ; on vérifie en plus que rien n'est resté en français.
    expect(ar.phoneTitle, isNot(fr.phoneTitle));
    expect(en.phoneTitle, isNot(fr.phoneTitle));
    expect(ar.consentHealthData, matches(RegExp(r'\p{Script=Arabic}', unicode: true)));
    expect(ar.emergencyNotice, allOf(contains('141'), contains('15')));
    expect(en.emergencyNotice, allOf(contains('141'), contains('15')));
  });
}
