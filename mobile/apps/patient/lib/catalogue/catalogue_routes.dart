import 'package:go_router/go_router.dart';

import 'catalogue_providers.dart';
import 'catalogue_screen.dart';
import 'service_detail_screen.dart';

/// Routes du catalogue.
final List<RouteBase> catalogueRoutes = <RouteBase>[
  GoRoute(path: routeCatalogue, builder: (context, state) => const CatalogueScreen()),
  GoRoute(
    path: '/catalogue/category/:slug',
    builder: (context, state) => CategoryServicesScreen(categorySlug: state.pathParameters['slug']!),
  ),
  GoRoute(
    path: '/catalogue/service/:slug',
    builder: (context, state) => ServiceDetailScreen(slug: state.pathParameters['slug']!),
  ),
];
