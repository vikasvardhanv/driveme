import 'package:flutter/foundation.dart';
import 'package:yazdrive/services/user_service.dart';
import 'package:yazdrive/services/trip_service.dart';
import 'package:yazdrive/services/vehicle_service.dart';

/// Provider to initialize app data and ensure proper data relationships
class AppInitProvider extends ChangeNotifier {
  final UserService userService;
  final TripService tripService;
  final VehicleService vehicleService;
  
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  
  AppInitProvider({
    required this.userService,
    required this.tripService,
    required this.vehicleService,
  }) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Load users first
      await userService.loadUsers();
      
      // Load vehicles
      await vehicleService.loadVehicles();
      
      // Load trips
      await tripService.loadTrips();
      
      // Initialize sample trips if needed
      await tripService.initializeSampleTrips(
        userService.members,
        userService.drivers,
      );
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to initialize app: \$e');
      _isInitialized = true;
      notifyListeners();
    }
  }
}
