import 'package:go_router/go_router.dart';

import 'booking_flow_screen.dart';
import 'bookings_providers.dart';
import 'bookings_screen.dart';

/// Routes des réservations.
final List<RouteBase> bookingRoutes = <RouteBase>[
  GoRoute(path: routeBookings, builder: (context, state) => const BookingsScreen()),
  GoRoute(
    path: '/bookings/new/:slug',
    builder: (context, state) => BookingFlowScreen(serviceSlug: state.pathParameters['slug']!),
  ),
  GoRoute(
    path: '/bookings/detail/:id',
    builder: (context, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
  ),
];
