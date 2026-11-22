import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import 'file/file_screen.dart';
import 'file/profession_screen.dart';
import 'home_screen.dart';
import 'missions/mission_detail_screen.dart';
import 'missions/report_screen.dart';
import 'pro_providers.dart';
import 'schedule/schedule_screen.dart';
import 'schedule/zones_screen.dart';

/// Routes propres à l'application professionnel, accessibles une fois connecté.
final List<RouteBase> proAppRoutes = <RouteBase>[
  GoRoute(path: routeProfession, builder: (context, state) => const ProfessionScreen()),
  GoRoute(path: routeFile, builder: (context, state) => const FileScreen()),
  GoRoute(path: routeZones, builder: (context, state) => const ZonesScreen()),
  GoRoute(path: routeSchedule, builder: (context, state) => const ScheduleScreen()),
  GoRoute(
    path: '/missions/:id',
    builder: (context, state) => MissionDetailScreen(missionId: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/missions/:id/report',
    builder: (context, state) => ReportScreen(missionId: state.pathParameters['id']!),
  ),
];

Future<void> main() {
  return runNadorCareApp(
    clientApp: ClientApp.pro,
    homeBuilder: (context) => const ProHomeScreen(),
    extraRoutes: proAppRoutes,
  );
}
