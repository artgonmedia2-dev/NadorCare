import 'package:go_router/go_router.dart';
import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import 'catalogue/catalogue_routes.dart';
import 'home_screen.dart';
import 'patients/patient_routes.dart';

/// Routes propres à l'application patient, accessibles une fois connecté.
final List<RouteBase> patientAppRoutes = <RouteBase>[...catalogueRoutes, ...patientRoutes];

Future<void> main() {
  return runNadorCareApp(
    clientApp: ClientApp.patient,
    homeBuilder: (context) => const PatientHomeScreen(),
    extraRoutes: patientAppRoutes,
  );
}
