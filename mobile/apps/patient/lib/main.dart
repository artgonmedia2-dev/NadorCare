import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import 'home_screen.dart';

Future<void> main() {
  return runNadorCareApp(
    clientApp: ClientApp.patient,
    homeBuilder: (context) => const PatientHomeScreen(),
  );
}
