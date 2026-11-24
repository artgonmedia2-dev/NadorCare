import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_api_client/nc_api_client.dart';
import 'package:nc_core/nc_core.dart';

const String routeCatalogue = '/catalogue';

String routeCategory(String slug) => '/catalogue/category/$slug';

String routeService(String slug) => '/catalogue/service/$slug';

final catalogueApiProvider = Provider<CatalogueApi>((ref) => HttpCatalogueApi(ref.watch(apiClientProvider)));

/// Le catalogue dépend de la langue : il est rechargé quand elle change.
String _language(Ref ref) => ref.watch(settingsControllerProvider.select((settings) => settings.languageCode)) ?? '';

// Pas de nouvelle tentative automatique : en cas d'échec, l'écran propose « Réessayer ».
final careCategoriesProvider = FutureProvider.autoDispose<List<CareCategory>>(
  (ref) {
    _language(ref);
    return ref.watch(catalogueApiProvider).categories();
  },
  retry: (retryCount, error) => null,
);

/// Catégories de la grille de l'accueil. Lecture à part : l'accueil reste ouvert sous le
/// catalogue, et partager la lecture empêcherait le catalogue de se recharger à son ouverture.
final homeCategoriesProvider = FutureProvider.autoDispose<List<CareCategory>>(
  (ref) {
    _language(ref);
    return ref.watch(catalogueApiProvider).categories();
  },
  retry: (retryCount, error) => null,
);

typedef ServiceFilter = ({String? categorySlug, String? query});

final careServicesProvider = FutureProvider.autoDispose.family<List<CareService>, ServiceFilter>(
  (ref, filter) {
    _language(ref);
    return ref.watch(catalogueApiProvider).services(categorySlug: filter.categorySlug, query: filter.query);
  },
  retry: (retryCount, error) => null,
);

final careServiceProvider = FutureProvider.autoDispose.family<CareService, String>(
  (ref, slug) {
    _language(ref);
    return ref.watch(catalogueApiProvider).service(slug);
  },
  retry: (retryCount, error) => null,
);
