import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

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
    // Use production URL by default
    String socketUrl = 'https://driveme-backedn-production.up.railway.app';

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

    // Start listening to position updates
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _sendLocationUpdate(userId, position);
      notifyListeners();
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
