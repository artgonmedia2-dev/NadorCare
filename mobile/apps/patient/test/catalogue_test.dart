import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nadorcare_patient/catalogue/catalogue_providers.dart';
import 'package:nadorcare_patient/home_screen.dart';
import 'package:nadorcare_patient/main.dart';
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

const CareService injection = CareService(
  id: 'S1',
  slug: 'injection',
  name: 'Injection',
  description: 'Injection intramusculaire ou sous-cutanée à domicile.',
  durationMinutes: 20,
  priceAmount: 8050,
  requiresPrescription: true,
  allowsSeries: true,
  categorySlug: 'soins-infirmiers',
  categoryName: 'Soins infirmiers',
  professionalCategory: 'Infirmier',
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

const CareService rehab = CareService(
  id: 'S3',
  slug: 'reeducation',
  name: 'Séance de rééducation',
  durationMinutes: 45,
  priceAmount: 20000,
  requiresPrescription: false,
  allowsSeries: true,
  categorySlug: 'kinesitherapie',
  categoryName: 'Kinésithérapie',
);

/// Imite le catalogue du serveur, recherche comprise.
class FakeCatalogueApi implements CatalogueApi {
  FakeCatalogueApi([List<CareService>? services]) : all = services ?? <CareService>[injection, dressing, rehab];

  final List<CareService> all;
  final List<String> searches = <String>[];
  ApiFailure? failure;

  void _failIfNeeded() {
    if (failure != null) {
      throw failure!;
    }
  }

  @override
  Future<List<CareCategory>> categories() async {
    _failIfNeeded();
    final counts = <String, CareCategory>{};
    for (final service in all) {
      final current = counts[service.categorySlug];
      counts[service.categorySlug] = CareCategory(
        slug: service.categorySlug,
        name: service.categoryName,
        servicesCount: (current?.servicesCount ?? 0) + 1,
      );
    }
    return counts.values.toList();
  }

  @override
  Future<List<CareService>> services({String? categorySlug, String? query}) async {
    _failIfNeeded();
    if (query != null) {
      searches.add(query);
    }
    return all.where((service) {
      final inCategory = categorySlug == null || service.categorySlug == categorySlug;
      final matches = query == null || service.name.toLowerCase().contains(query.toLowerCase());
      return inCategory && matches;
    }).toList();
  }

  @override
  Future<CareService> service(String slug) async {
    _failIfNeeded();
    return all.firstWhere((service) => service.slug == slug);
  }
}

class _SignedInAuthApi implements AuthApi {
  @override
  Future<AppUser> me() async => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Finder byName(String name) => find.byKey(ValueKey<String>(name));

Future<void> pumpPatientApp(WidgetTester tester, {required FakeCatalogueApi api, String language = 'fr'}) async {
  tester.view.physicalSize = const Size(800, 3200);
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
        catalogueApiProvider.overrideWithValue(api),
      ],
      child: NadorCareApp(homeBuilder: (context) => const PatientHomeScreen(), extraRoutes: patientAppRoutes),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('le catalogue liste les catégories avec leur nombre de soins', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi());

    await tapAndSettle(tester, byName('home-catalogue'));

    expect(find.text('Soins infirmiers'), findsOneWidget);
    expect(find.text(fr.servicesCount(2)), findsOneWidget);
    expect(find.text('Kinésithérapie'), findsOneWidget);
    expect(find.text(fr.servicesCount(1)), findsOneWidget);
  });

  testWidgets('une catégorie montre ses soins avec durée, tarif indicatif et ordonnance', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi());
    await tapAndSettle(tester, byName('home-catalogue'));

    await tapAndSettle(tester, byName('category-soins-infirmiers'));

    expect(find.text('Injection'), findsOneWidget);
    expect(find.text('20 min · 80,5 DH'), findsOneWidget);
    expect(find.text('30 min · 100 DH'), findsOneWidget);
    // Seule l'injection exige une ordonnance.
    expect(find.text(fr.servicePrescriptionRequired), findsOneWidget);
    expect(find.text('Séance de rééducation'), findsNothing);
  });

  testWidgets('la fiche d un soin explique le tarif et l ordonnance, sans bouton de réservation pour l instant', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi());
    await tapAndSettle(tester, byName('home-catalogue'));
    await tapAndSettle(tester, byName('category-soins-infirmiers'));

    await tapAndSettle(tester, byName('service-injection'));

    expect(find.text('Injection intramusculaire ou sous-cutanée à domicile.'), findsOneWidget);
    expect(find.text('80,5 DH'), findsOneWidget);
    expect(find.text(fr.servicePriceLabel), findsOneWidget);
    expect(find.text(fr.servicePriceNote), findsOneWidget);
    expect(find.text(fr.serviceProvidedBy('Infirmier')), findsOneWidget);
    expect(find.text(fr.serviceSeries), findsOneWidget);
    expect(byName('prescription-notice'), findsOneWidget);
    expect(find.text(fr.bookingSoon), findsOneWidget);
  });

  testWidgets('un soin sans ordonnance ni série n affiche pas ces mentions', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi());
    await tapAndSettle(tester, byName('home-catalogue'));
    await tapAndSettle(tester, byName('category-soins-infirmiers'));

    await tapAndSettle(tester, byName('service-pansement'));

    expect(byName('prescription-notice'), findsNothing);
    expect(find.text(fr.serviceSeries), findsNothing);
    expect(find.text('100 DH'), findsOneWidget);
  });

  testWidgets('la recherche attend la fin de la saisie puis remplace les catégories par les résultats', (tester) async {
    final api = FakeCatalogueApi();
    await pumpPatientApp(tester, api: api);
    await tapAndSettle(tester, byName('home-catalogue'));

    await tester.enterText(byName('catalogue-search'), 'pan');
    await tester.pump(const Duration(milliseconds: 100));
    expect(api.searches, isEmpty, reason: 'pas d appel pendant la frappe');

    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(api.searches, <String>['pan']);
    expect(find.text('Pansement'), findsOneWidget);
    expect(find.text('Kinésithérapie'), findsNothing);

    // Une seule lettre : retour aux catégories.
    await tester.enterText(byName('catalogue-search'), 'p');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Kinésithérapie'), findsOneWidget);
    expect(api.searches, hasLength(1));
  });

  testWidgets('une recherche sans résultat le dit clairement', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi());
    await tapAndSettle(tester, byName('home-catalogue'));

    await tester.enterText(byName('catalogue-search'), 'radiologie');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text(fr.catalogueNoResult('radiologie')), findsOneWidget);
  });

  testWidgets('un catalogue vide et une panne réseau ont chacun leur message', (tester) async {
    final api = FakeCatalogueApi(<CareService>[]);
    await pumpPatientApp(tester, api: api);
    await tapAndSettle(tester, byName('home-catalogue'));
    expect(find.text(fr.catalogueEmpty), findsOneWidget);

    await tapAndSettle(tester, find.byType(BackButton));
    api
      ..failure = const ApiFailure(code: ApiFailure.network)
      ..all.add(injection);
    await tapAndSettle(tester, byName('home-catalogue'));
    expect(find.text(fr.errorNetwork), findsOneWidget);

    api.failure = null;
    await tapAndSettle(tester, find.text(fr.retry));
    expect(find.text('Soins infirmiers'), findsOneWidget);
  });

  testWidgets('en arabe, le catalogue se lit de droite à gauche avec des chiffres latins', (tester) async {
    await pumpPatientApp(tester, api: FakeCatalogueApi(), language: 'ar');
    await tapAndSettle(tester, byName('home-catalogue'));
    await tapAndSettle(tester, byName('category-soins-infirmiers'));
    await tapAndSettle(tester, byName('service-injection'));

    expect(find.text(ar.servicePriceLabel), findsOneWidget);
    expect(Directionality.of(tester.element(find.text(ar.servicePriceLabel))), TextDirection.rtl);
    expect(find.text(ar.priceDirhams('80.5')), findsOneWidget);
  });

  test('les montants s affichent sans décimales inutiles', () {
    expect(formatDirhams(15000, 'fr'), '150');
    expect(formatDirhams(8050, 'fr'), '80,5');
    expect(formatDirhams(8055, 'en'), '80.55');
    expect(formatDirhams(0, 'fr'), '0');
    expect(formatDirhams(8050, 'ar'), '80.5');
    expect(formatDirhams(150000, 'en'), '1,500');
  });
}
