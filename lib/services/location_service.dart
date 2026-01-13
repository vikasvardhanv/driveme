import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LocationService extends ChangeNotifier {
  IO.Socket? _socket;
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // Initialize socket connection
  void initSocket(String userId) {
    String socketUrl = kIsWeb 
        ? 'http://localhost:3001' 
        : (Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001');

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'query': {'userId': userId},
    });

    _socket?.connect();
    
    _socket?.onConnect((_) {
      debugPrint('Connected to tracking server');
    });
    
    _socket?.onDisconnect((_) {
      debugPrint('Disconnected from tracking server');
    });
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

  void _sendLocationUpdate(String userId, Position position) {
    if (_socket?.connected == true) {
      _socket?.emit('locationUpdate', {
        'userId': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
