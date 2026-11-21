import 'package:go_router/go_router.dart';

import 'address_form_screen.dart';
import 'addresses_screen.dart';
import 'patient_texts.dart';
import 'profile_form_screen.dart';
import 'profiles_screen.dart';

/// Routes des patients et des adresses, accessibles une fois connecté.
final List<RouteBase> patientRoutes = <RouteBase>[
  GoRoute(path: routeProfiles, builder: (context, state) => const ProfilesScreen()),
  GoRoute(path: routeProfileNew, builder: (context, state) => const ProfileFormScreen()),
  GoRoute(
    path: '/profiles/edit/:id',
    builder: (context, state) => ProfileFormScreen(profileId: state.pathParameters['id']),
  ),
  GoRoute(path: routeAddresses, builder: (context, state) => const AddressesScreen()),
  GoRoute(path: routeAddressNew, builder: (context, state) => const AddressFormScreen()),
  GoRoute(
    path: '/addresses/edit/:id',
    builder: (context, state) => AddressFormScreen(addressId: state.pathParameters['id']),
  ),
];
