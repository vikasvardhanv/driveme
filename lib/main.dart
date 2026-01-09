import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yazdrive/theme.dart';
import 'package:yazdrive/nav.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';
import 'package:yazdrive/providers/app_init_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserService()),
        ChangeNotifierProvider(create: (_) => TripService()),
        ChangeNotifierProvider(create: (_) => VehicleService()),
        ChangeNotifierProxyProvider3<UserService, TripService, VehicleService, AppInitProvider>(
          create: (context) => AppInitProvider(
            userService: context.read<UserService>(),
            tripService: context.read<TripService>(),
            vehicleService: context.read<VehicleService>(),
          ),
          update: (context, userService, tripService, vehicleService, previous) =>
              previous ?? AppInitProvider(
                userService: userService,
                tripService: tripService,
                vehicleService: vehicleService,
              ),
        ),
      ],
      child: MaterialApp.router(
        title: 'YazDrive',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
