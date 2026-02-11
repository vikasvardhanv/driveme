import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:yazdrive/services/api_service.dart';

/// Azuga vehicle location data from webhook
class AzugaVehicleLocation {
  final String vehicleId;
  final String? vehicleName;
  final String? driverName;
  final double latitude;
  final double longitude;
  final double speed;
  final String? address;
  final String status; // moving, idle, offline
  final DateTime lastUpdate;

  AzugaVehicleLocation({
    required this.vehicleId,
    this.vehicleName,
    this.driverName,
    required this.latitude,
    required this.longitude,
    required this.speed,
    this.address,
    required this.status,
    required this.lastUpdate,
  });

  factory AzugaVehicleLocation.fromJson(Map<String, dynamic> json) {
    return AzugaVehicleLocation(
      vehicleId: json['id'] ?? json['vehicleId'] ?? '',
      vehicleName: json['vehicleName'],
      driverName: json['driverName'],
      latitude: (json['currentLat'] ?? json['lat'] ?? 0).toDouble(),
      longitude: (json['currentLng'] ?? json['lng'] ?? 0).toDouble(),
      speed: (json['currentSpeed'] ?? json['speed'] ?? 0).toDouble(),
      address: json['address'],
      status: json['status'] ?? 'offline',
      lastUpdate: json['lastLocationUpdate'] != null
        ? DateTime.parse(json['lastLocationUpdate'])
        : DateTime.now(),
    );
  }

  bool get isMoving => status == 'moving';
  bool get isIdle => status == 'idle';
  bool get isOffline => status == 'offline';
}

class LocationService extends ChangeNotifier {
  IO.Socket? _socket;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isTracking = false;
  String? _currentTripId;
  String? _currentUserId;

  // Azuga vehicle locations cache
  final Map<String, AzugaVehicleLocation> _vehicleLocations = {};
  // Callbacks for vehicle updates
  final List<Function(AzugaVehicleLocation)> _vehicleUpdateListeners = [];

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  String? get currentTripId => _currentTripId;
  Map<String, AzugaVehicleLocation> get vehicleLocations => Map.unmodifiable(_vehicleLocations);

  /// Set the current active trip ID for location updates
  void setCurrentTrip(String? tripId) {
    _currentTripId = tripId;
  }

  /// Add listener for Azuga vehicle updates
  void addVehicleUpdateListener(Function(AzugaVehicleLocation) listener) {
    _vehicleUpdateListeners.add(listener);
  }

  /// Remove listener for Azuga vehicle updates
  void removeVehicleUpdateListener(Function(AzugaVehicleLocation) listener) {
    _vehicleUpdateListeners.remove(listener);
  }

  // Initialize socket connection
  void initSocket(String userId) {
    _currentUserId = userId;
    // Use production URL from ApiService
    String socketUrl = ApiService.baseUrl;

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    _socket?.connect();

    _socket?.onConnect((_) {
      debugPrint('Connected to tracking server');
      // Register as driver for receiving trip updates
      _socket?.emit('driverConnect', {'driverId': userId});
    });

    // Listen for Azuga vehicle updates from backend
    _socket?.on('vehicle:update', (data) {
      _handleVehicleUpdate(data);
    });

    // Listen for updates for specific vehicle
    _socket?.on('vehicle:$userId', (data) {
      _handleVehicleUpdate(data);
    });

    _socket?.onDisconnect((_) {
      debugPrint('Disconnected from tracking server');
    });

    _socket?.onError((error) {
      debugPrint('Socket error: $error');
    });
  }

  void _handleVehicleUpdate(dynamic data) {
    try {
      final Map<String, dynamic> vehicleData = data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data);

      final location = AzugaVehicleLocation.fromJson(vehicleData);
      _vehicleLocations[location.vehicleId] = location;

      // Notify all listeners
      for (final listener in _vehicleUpdateListeners) {
        listener(location);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling vehicle update: $e');
    }
  }

  /// Request location permissions proactively (call at login/app start)
  /// Requests "Always" permission for background location tracking
  Future<bool> requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      debugPrint('Current location permission: $permission');
      
      // If denied, request permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        debugPrint('After request, permission is: $permission');
      }
      
      // If permission is deniedForever, user needs to enable in settings
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied forever. User must enable in Settings.');
        return false;
      }
      
      // If still denied after request
      if (permission == LocationPermission.denied) {
        debugPrint('⚠️ Location permission denied by user.');
        return false;
      }
      
      // If we have whileInUse, we need to prompt for Always permission for background tracking
      if (permission == LocationPermission.whileInUse) {
        debugPrint('ℹ️ Have "While in Use" permission. For background tracking, we need "Always" permission.');
        debugPrint('ℹ️ Note: iOS will automatically prompt user to upgrade to "Always" after some time using the app.');
        // On iOS, you can't directly request "Always" - user gets prompted after using "When in Use"
        // The prompt appears automatically after the app has been used with location for a while
      }
      
      debugPrint('✅ Location permission granted: $permission');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }

  /// Check if location permissions are granted (either whileInUse or always)
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }
  
  /// Check if we have background location permission (always)
  Future<bool> hasBackgroundPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always;
  }

  Future<void> startTracking(String userId) async {
    if (_isTracking) return;

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied) {
        return; // Handle permission denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return; // Handle permanently denied
    }

    _isTracking = true;
    notifyListeners();

    // Configure location settings for background tracking
    LocationSettings locationSettings;
    
    if (Platform.isIOS) {
      // iOS-specific settings for background location
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.automotiveNavigation, // Optimized for driving
        distanceFilter: 10, // Update every 10 meters
        pauseLocationUpdatesAutomatically: false, // Keep tracking even when stationary
        showBackgroundLocationIndicator: true, // Show blue bar when using location in background
      );
      debugPrint('🚗 Started iOS location tracking with automotive navigation mode');
    } else if (Platform.isAndroid) {
      // Android-specific settings
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationText: "Drivemeyaz is tracking your location for trip tracking",
          notificationTitle: "Trip Tracking Active",
          enableWakeLock: true,
        ),
      );
      debugPrint('🚗 Started Android location tracking with foreground service');
    } else {
      // Default settings for other platforms
      locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      debugPrint('🚗 Started location tracking with default settings');
    }

    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      _currentPosition = position;
      _sendLocationUpdate(userId, position);
      notifyListeners();
      debugPrint('📍 Location update: ${position.latitude}, ${position.longitude} - Speed: ${position.speed}m/s');
    });
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _isTracking = false;
    _currentPosition = null;
    notifyListeners();
  }

  /// Check if current location is within specified range of target coordinates
  /// Used for geofencing - prevents status updates if driver is too far from location
  Future<bool> isWithinRange(double targetLat, double targetLng, double radiusMiles) async {
    try {
      // Get current position if not available
      Position? position = _currentPosition;
      if (position == null) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          // Can't check location, allow action to proceed
          return true;
        }
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _currentPosition = position;
      }
      
      // Calculate distance in meters
      final distanceMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        targetLat,
        targetLng,
      );
      
      // Convert radius from miles to meters (1 mile = 1609.34 meters)
      final radiusMeters = radiusMiles * 1609.34;
      
      return distanceMeters <= radiusMeters;
    } catch (e) {
      debugPrint('Error checking location range: $e');
      // On error, allow action to proceed
      return true;
    }
  }

  void _sendLocationUpdate(String userId, Position position) {
    if (_socket?.connected == true) {
      _socket?.emit('locationUpdate', {
        'userId': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
        if (_currentTripId != null) 'tripId': _currentTripId,
      });
    }
  }

  /// Get vehicle location by ID (from Azuga cache)
  AzugaVehicleLocation? getVehicleLocation(String vehicleId) {
    return _vehicleLocations[vehicleId];
  }

  /// Get all active vehicles (from Azuga cache)
  List<AzugaVehicleLocation> getActiveVehicles() {
    return _vehicleLocations.values
      .where((v) => !v.isOffline)
      .toList();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
