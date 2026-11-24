import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers.dart';
import '../storage/preferences_store.dart';
import 'nador_care_app.dart';

/// Point d'entrée commun : charge les réglages enregistrés puis lance l'application.
Future<void> runNadorCareApp({
  required ClientApp clientApp,
  required WidgetBuilder homeBuilder,
  List<RouteBase> extraRoutes = const <RouteBase>[],
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  registerNcFontLicenses();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.fromEnvironment(clientApp)),
        preferencesStoreProvider.overrideWithValue(SharedPreferencesStore(preferences)),
      ],
      child: NadorCareApp(homeBuilder: homeBuilder, extraRoutes: extraRoutes),
    ),
  );
}
