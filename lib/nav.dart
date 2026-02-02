import 'package:go_router/go_router.dart';
import 'package:yazdrive/pages/login_page.dart';
import 'package:yazdrive/pages/driver_application_page.dart';
import 'package:yazdrive/pages/driver/driver_dashboard_page.dart';
import 'package:yazdrive/pages/driver/driver_trip_detail_page.dart';
import 'package:yazdrive/pages/driver/vehicle_confirmation_page.dart';
import 'package:yazdrive/pages/driver/driver_trips_page.dart';
import 'package:yazdrive/pages/driver/driver_profile_page.dart';
import 'package:yazdrive/pages/driver/driver_scaffold.dart';
import 'package:yazdrive/pages/driver/trip_completion_page.dart';
import 'package:yazdrive/pages/admin/create_trip_page.dart';
import 'package:yazdrive/pages/admin/admin_dashboard_page.dart';

/// GoRouter configuration for app navigation
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => NoTransitionPage(child: const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.driverApplication,
        name: 'driver_application',
        pageBuilder: (context, state) => NoTransitionPage(child: const DriverApplicationPage()),
      ),
      GoRoute(
        path: AppRoutes.vehicleConfirmation,
        name: 'vehicle_confirmation',
        pageBuilder: (context, state) => NoTransitionPage(child: const VehicleConfirmationPage()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return DriverScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverDashboard,
                name: 'driver_dashboard',
                pageBuilder: (context, state) => NoTransitionPage(child: const DriverDashboardPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverTrips,
                name: 'driver_trips',
                pageBuilder: (context, state) => NoTransitionPage(child: const DriverTripsPage()),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.driverProfile,
                name: 'driver_profile',
                pageBuilder: (context, state) => NoTransitionPage(child: const DriverProfilePage()),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.driverTripDetail,
        name: 'driver_trip_detail',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return NoTransitionPage(child: DriverTripDetailPage(tripId: tripId));
        },
      ),
      GoRoute(
        path: AppRoutes.tripCompletion,
        name: 'trip_completion',
        pageBuilder: (context, state) {
          final tripId = state.pathParameters['tripId']!;
          return NoTransitionPage(child: TripCompletionPage(tripId: tripId));
        },
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin_dashboard',
        pageBuilder: (context, state) => NoTransitionPage(child: const AdminDashboardPage()),
      ),
      GoRoute(
        path: AppRoutes.adminCreateTrip,
        name: 'admin_create_trip',
        pageBuilder: (context, state) => NoTransitionPage(child: const CreateTripPage()),
      ),
    ],
  );
}

/// Route path constants
class AppRoutes {
  static const String home = '/';
  static const String driverApplication = '/driver/apply';
  static const String driverDashboard = '/driver/dashboard';
  static const String driverTrips = '/driver/trips';
  static const String vehicleConfirmation = '/driver/vehicle-confirmation';
  static const String driverProfile = '/driver/profile';
  static const String driverTripDetail = '/driver/trip/:tripId';
  static const String tripCompletion = '/driver/trip/:tripId/complete';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateTrip = '/admin/trips/create';
}
