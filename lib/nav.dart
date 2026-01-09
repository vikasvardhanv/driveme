import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yazdrive/pages/login_page.dart';
import 'package:yazdrive/pages/driver/driver_dashboard_page.dart';
import 'package:yazdrive/pages/driver/driver_trip_detail_page.dart';
import 'package:yazdrive/pages/admin/admin_dashboard_page.dart';
import 'package:yazdrive/pages/admin/create_trip_page.dart';

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
        path: AppRoutes.driverDashboard,
        name: 'driver_dashboard',
        pageBuilder: (context, state) => NoTransitionPage(child: const DriverDashboardPage()),
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
  static const String driverDashboard = '/driver/dashboard';
  static const String driverTripDetail = '/driver/trip/:tripId';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminCreateTrip = '/admin/trips/create';
}
