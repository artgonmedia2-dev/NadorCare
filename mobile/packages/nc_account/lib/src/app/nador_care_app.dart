import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nc_core/nc_core.dart';
import 'package:nc_design_system/nc_design_system.dart';
import 'package:nc_l10n/nc_l10n.dart';

import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../providers.dart';
import '../screens/language_screen.dart';
import '../screens/login_flow.dart';
import '../screens/settings_screen.dart';
import '../screens/unlock_screen.dart';
import '../settings/app_settings.dart';
import '../settings/settings_controller.dart';

/// Chemins communs aux deux applications.
abstract final class NcRoutes {
  static const String splash = '/';
  static const String language = '/language';
  static const String login = '/login';
  static const String unlock = '/unlock';
  static const String home = '/home';
  static const String settings = '/settings';
}

/// Enveloppe commune aux applications patient et professionnel : langue, sens de lecture,
/// taille du texte, thème, et parcours d'entrée (langue, connexion, verrouillage).
///
/// Chaque application fournit seulement son écran d'accueil et, plus tard, ses propres routes.
class NadorCareApp extends ConsumerStatefulWidget {
  const NadorCareApp({required this.homeBuilder, this.extraRoutes = const <RouteBase>[], super.key});

  final WidgetBuilder homeBuilder;

  /// Routes propres à l'application, accessibles une fois connecté.
  final List<RouteBase> extraRoutes;

  @override
  ConsumerState<NadorCareApp> createState() => _NadorCareAppState();
}

class _NadorCareAppState extends ConsumerState<NadorCareApp> {
  final ValueNotifier<int> _refresh = ValueNotifier<int>(0);
  late final GoRouter _router;

  /// Langue touchée sur l'écran de choix, avant validation.
  String? _previewLanguage;

  @override
  void initState() {
    super.initState();

    _router = GoRouter(
      initialLocation: NcRoutes.splash,
      refreshListenable: _refresh,
      redirect: _redirect,
      routes: <RouteBase>[
        GoRoute(path: NcRoutes.splash, builder: (context, state) => const _SplashScreen()),
        GoRoute(
          path: NcRoutes.language,
          builder: (context, state) => LanguageScreen(
            onPreview: (code) => setState(() => _previewLanguage = code),
          ),
        ),
        GoRoute(path: NcRoutes.login, builder: (context, state) => const LoginFlow()),
        GoRoute(path: NcRoutes.unlock, builder: (context, state) => const UnlockScreen()),
        GoRoute(path: NcRoutes.home, builder: (context, state) => widget.homeBuilder(context)),
        GoRoute(path: NcRoutes.settings, builder: (context, state) => const SettingsScreen()),
        ...widget.extraRoutes,
      ],
    );

    ref.listenManual(authControllerProvider, (previous, next) => _refresh.value++);
    ref.listenManual(settingsControllerProvider, (previous, next) => _refresh.value++);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  void dispose() {
    _router.dispose();
    _refresh.dispose();
    super.dispose();
  }

  /// Une seule règle décide de l'écran affiché selon l'état de la session.
  String? _redirect(BuildContext context, GoRouterState state) {
    final settings = ref.read(settingsControllerProvider);
    final auth = ref.read(authControllerProvider);
    final location = state.matchedLocation;

    final target = switch (auth) {
      _ when settings.languageCode == null => NcRoutes.language,
      AuthInitializing() => NcRoutes.splash,
      AuthSignedOut() => NcRoutes.login,
      AuthLocked() => NcRoutes.unlock,
      AuthSignedIn() => null,
    };

    if (target != null) {
      return location == target ? null : target;
    }

    // Connecté : les écrans d'entrée renvoient à l'accueil.
    const entryScreens = <String>[NcRoutes.splash, NcRoutes.language, NcRoutes.login, NcRoutes.unlock];
    return entryScreens.contains(location) ? NcRoutes.home : null;
  }

  @override
  Widget build(BuildContext context) {
    final AppSettings settings = ref.watch(settingsControllerProvider);
    final clientApp = ref.watch(appConfigProvider).clientApp;
    final languageCode = settings.languageCode ?? _previewLanguage;

    return MaterialApp.router(
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) =>
          clientApp == ClientApp.patient ? context.l10n.appNamePatient : context.l10n.appNamePro,
      theme: NcTheme.light(),
      locale: languageCode == null ? null : Locale(languageCode),
      supportedLocales: <Locale>[for (final code in supportedLanguageCodes) Locale(code)],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        NcLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Langue du téléphone si elle est prise en charge, sinon français.
      localeResolutionCallback: (deviceLocale, supported) {
        return supported.firstWhere(
          (locale) => locale.languageCode == deviceLocale?.languageCode,
          orElse: () => const Locale(defaultLanguageCode),
        );
      },
      builder: (context, child) {
        // La taille choisie dans les réglages s'ajoute à celle du système.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(media.textScaler.scale(1) * settings.textSize.factor),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
