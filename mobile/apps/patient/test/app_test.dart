import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nadorcare_patient/home_screen.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_l10n/nc_l10n.dart';

const AppUser _user = AppUser(
  id: '01TEST',
  phone: '+212612345678',
  name: 'Fatima',
  locale: 'ar',
  status: 'active',
  roles: <String>['patient'],
);

void main() {
  testWidgets('une session enregistrée ouvre l accueil patient, en arabe et de droite à gauche', (tester) async {
    final ar = lookupNcLocalizations(const Locale('ar'));

    // Écran assez haut pour afficher tout l'accueil.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(clientApp: ClientApp.patient, apiBaseUrl: 'https://api.test/api/v1'),
          ),
          preferencesStoreProvider.overrideWithValue(
            InMemoryPreferencesStore(const AppSettings(languageCode: 'ar')),
          ),
          // Hors ligne dans ce test : l'application s'ouvre avec le dernier compte connu.
          sessionStorageProvider.overrideWithValue(InMemorySessionStorage(token: 'jeton', user: _user)),
        ],
        child: NadorCareApp(homeBuilder: (context) => const PatientHomeScreen()),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 40));

    expect(find.text(ar.homeGreeting('Fatima')), findsOneWidget);
    expect(find.text(ar.emergencyNotice), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.emergencyNotice))), TextDirection.rtl);
    expect(find.byTooltip(ar.settingsOpen), findsOneWidget);
  });
}
