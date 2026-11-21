import 'package:nc_account/nc_account.dart';
import 'package:nc_core/nc_core.dart';

import 'home_screen.dart';

Future<void> main() {
  return runNadorCareApp(
    clientApp: ClientApp.pro,
    homeBuilder: (context) => const ProHomeScreen(),
  );
}
