import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:yazdrive/models/trip_model.dart';
import 'package:yazdrive/services/notification_service.dart';
import 'package:yazdrive/services/api_service.dart';

/// Service for managing NEMT trips with real-time sync
class TripService extends ChangeNotifier {
  static const String _storageKey = 'trips';
  final Uuid _uuid = const Uuid();

  List<TripModel> _trips = [];
  bool _isLoading = false;
  IO.Socket? _socket;
  String? _currentDriverId;
  Timer? _pollingTimer;
  static const Duration _pollingInterval = Duration(seconds: 30);

  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;

  /// Get the backend API URL
  static String get _baseUrl => ApiService.baseUrl;

  /// Initialize WebSocket connection for real-time trip updates
  void initializeSocketConnection(String driverId) {
    if (_socket != null && _socket!.connected && _currentDriverId == driverId) {
      // Already connected, but ensure polling is running
      _startPeriodicPolling(driverId);
      return;
    }
    
    // Disconnect existing if different driver (shouldn't happen usually but good safety)
    if (_socket != null) {
      disconnectSocket();
    }

    _currentDriverId = driverId;

    // Start periodic polling for trips (fallback to HTTP if socket fails)
    _startPeriodicPolling(driverId);

    _socket = IO.io(_baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
      'reconnectionAttempts': 10,
      'reconnectionDelay': 2000,
      'reconnectionDelayMax': 10000,
      'timeout': 10000,
    });

    _socket!.onConnect((_) {
      debugPrint('TripService: Socket connected');
      // Register as driver
      _socket!.emit('driverConnect', {'driverId': driverId});
      // Fetch latest trips immediately on connection
      fetchTripsFromBackend(driverId);
    });

    _socket!.on('connected', (data) {
      debugPrint('TripService: Driver connected confirmed: $data');
    });

    // Listen for new trip assignments
    _socket!.on('trip:assigned', (data) {
      debugPrint('TripService: New trip assigned: $data');
      _handleTripAssignment(data);
    });

    // Listen for trip updates
    _socket!.on('trip:updated', (data) {
      debugPrint('TripService: Trip updated: $data');
      _handleTripUpdate(data);
    });

    // Listen for trip cancellations
    _socket!.on('trip:cancelled', (data) {
      debugPrint('TripService: Trip cancelled: $data');
      _handleTripCancellation(data);
    });

    // Listen for status change acknowledgments
    _socket!.on('tripUpdateAck', (data) {
      debugPrint('TripService: Trip update acknowledged: $data');
    });

    _socket!.onDisconnect((_) {
      debugPrint('TripService: Socket disconnected');
    });

    _socket!.onReconnect((data) {
      debugPrint('TripService: Socket reconnected');
      // Fetch latest trips on reconnection
      if (_currentDriverId != null) {
        fetchTripsFromBackend(_currentDriverId!);
      }
    });

    _socket!.onError((error) {
      debugPrint('TripService: Socket error: $error');
    });

    _socket!.connect();
  }

  /// Start periodic polling to keep trips in sync
  void _startPeriodicPolling(String driverId) {
    // Cancel existing timer if any
    _pollingTimer?.cancel();
    
    // Create new timer
    _pollingTimer = Timer.periodic(_pollingInterval, (timer) {
      debugPrint('TripService: Periodic polling - fetching trips');
      fetchTripsFromBackend(driverId);
    });
    
    debugPrint('TripService: Started periodic polling every ${_pollingInterval.inSeconds}s');
  }

  void _handleTripAssignment(dynamic data) {
    try {
      final tripData = data is Map<String, dynamic> ? data : jsonDecode(data);
      final trip = _parseTripFromBackend(tripData);

      // Add trip if not already present
      final existingIndex = _trips.indexWhere((t) => t.id == trip.id);
      final isNewTrip = existingIndex == -1;

      if (isNewTrip) {
        _trips.add(trip);
      } else {
        _trips[existingIndex] = trip;
      }

      _saveTrips();
      notifyListeners();

      // Show push notification for new trip assignment
      if (isNewTrip) {
        final timeFormat = DateFormat('h:mm a');
        NotificationService().showTripAssignedNotification(
          tripId: trip.id,
          pickupAddress: trip.pickupAddress,
          pickupTime: timeFormat.format(trip.scheduledPickupTime),
          memberName: tripData['member']?['firstName'] != null
            ? '${tripData['member']['firstName']} ${tripData['member']['lastName'] ?? ''}'
            : null,
        );
      }
    } catch (e) {
      debugPrint('Error handling trip assignment: $e');
    }
  }

  void _handleTripUpdate(dynamic data) {
    try {
      final tripData = data is Map<String, dynamic> ? data : jsonDecode(data);
      final trip = _parseTripFromBackend(tripData);

      final existingIndex = _trips.indexWhere((t) => t.id == trip.id);
      if (existingIndex != -1) {
        _trips[existingIndex] = trip;
        _saveTrips();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling trip update: $e');
    }
  }

  void _handleTripCancellation(dynamic data) {
    try {
      final tripId = data is Map ? data['tripId'] : data;
      final existingIndex = _trips.indexWhere((t) => t.id == tripId);
      if (existingIndex != -1) {
        final trip = _trips[existingIndex];
        _trips[existingIndex] = trip.copyWith(
          status: TripStatus.cancelled,
          updatedAt: DateTime.now(),
        );
        _saveTrips();
        notifyListeners();

        // Show push notification for trip cancellation
        final timeFormat = DateFormat('h:mm a');
        NotificationService().showTripCancelledNotification(
          tripId: trip.id,
          pickupAddress: trip.pickupAddress,
          pickupTime: timeFormat.format(trip.scheduledPickupTime),
        );
      }
    } catch (e) {
      debugPrint('Error handling trip cancellation: $e');
    }
  }

  TripModel _parseTripFromBackend(Map<String, dynamic> data) {
    // Parse backend trip format to TripModel
    return TripModel(
      id: data['id'],
      memberId: data['memberId'] ?? data['member']?['id'] ?? '',
      driverId: data['driverId'],
      vehicleId: data['vehicleId'],
      tripType: _parseTripType(data['tripType']),
      status: _parseTripStatus(data['status']),
      scheduledPickupTime: DateTime.parse(data['scheduledPickupTime']),
      actualPickupTime: data['actualPickupTime'] != null
        ? DateTime.parse(data['actualPickupTime']) : null,
      actualDropoffTime: data['actualDropoffTime'] != null
        ? DateTime.parse(data['actualDropoffTime']) : null,
      pickupAddress: data['pickupAddress'] ?? '',
      pickupCity: data['pickupCity'] ?? '',
      pickupState: data['pickupState'] ?? 'AZ',
      pickupZip: data['pickupZip'] ?? '',
      pickupLatitude: data['pickupLat']?.toDouble(),
      pickupLongitude: data['pickupLng']?.toDouble(),
      dropoffAddress: data['dropoffAddress'] ?? '',
      dropoffCity: data['dropoffCity'] ?? '',
      dropoffState: data['dropoffState'] ?? 'AZ',
      dropoffZip: data['dropoffZip'] ?? '',
      dropoffLatitude: data['dropoffLat']?.toDouble(),
      dropoffLongitude: data['dropoffLng']?.toDouble(),
      customerName: data['customerName'],
      customerPhone: data['customerPhone'],
      customerEmail: data['customerEmail'],
      appointmentType: data['reasonForVisit'],
      facilityName: data['facilityName'],
      estimatedMiles: data['tripMiles']?.toDouble(),
      authorizationNumber: data['authorizationNumber'] ?? 'N/A',
      membershipId: data['member']?['ahcccsNumber'] ?? data['membershipId'] ?? '',
      createdAt: data['createdAt'] != null
        ? DateTime.parse(data['createdAt']) : DateTime.now(),
      updatedAt: data['updatedAt'] != null 
        ? DateTime.parse(data['updatedAt']) : DateTime.now(),
      pdfReportUrl: data['pdfURL'] ?? data['pdfReportUrl'], // Map from backend response
    );
  }

  TripType _parseTripType(String? type) {
    switch (type?.toLowerCase()) {
      case 'round-trip':
      case 'roundtrip':
        return TripType.roundTrip;
      case 'multiple-stops':
      case 'multistop':
        return TripType.multiStop;
      default:
        return TripType.oneWay;
    }
  }

  TripStatus _parseTripStatus(String? status) {
    switch (status?.toUpperCase()) {
      case 'SCHEDULED':
        return TripStatus.scheduled;
      case 'ASSIGNED':
        return TripStatus.assigned;
      case 'EN_ROUTE':
        return TripStatus.enRoute;
      case 'ARRIVED':
        return TripStatus.arrived;
      case 'PICKED_UP':
        return TripStatus.pickedUp;
      case 'COMPLETED':
        return TripStatus.completed;
      case 'CANCELLED':
        return TripStatus.cancelled;
      case 'NO_SHOW':
        return TripStatus.noShow;
      default:
        return TripStatus.scheduled;
    }
  }

  /// Disconnect WebSocket
  void disconnectSocket() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _currentDriverId = null;
    debugPrint('TripService: Socket disconnected and polling stopped');
  }

  /// Emit trip status update via WebSocket
  void _emitTripStatusUpdate(String tripId, TripStatus status, {
    int? pickupOdometer,
    int? dropoffOdometer,
    String? driverSignature,
    String? memberSignature,
  }) {
    if (_socket == null || _currentDriverId == null) return;

    final payload = {
      'tripId': tripId,
      'status': _mapStatusToBackendString(status),
      'driverId': _currentDriverId,
      if (pickupOdometer != null) 'pickupOdometer': pickupOdometer,
      if (dropoffOdometer != null) 'dropoffOdometer': dropoffOdometer,
      if (status == TripStatus.pickedUp) 'actualPickupTime': DateTime.now().toIso8601String(),
      if (status == TripStatus.completed) 'actualDropoffTime': DateTime.now().toIso8601String(),
      if (driverSignature != null) 'driverSignatureUrl': driverSignature,
      if (memberSignature != null) 'memberSignatureUrl': memberSignature,
    };

    _socket!.emit('tripStatusUpdate', payload);
  }

  String _mapStatusToBackendString(TripStatus status) {
    switch (status) {
      case TripStatus.enRoute:
        return 'EN_ROUTE';
      case TripStatus.pickedUp:
        return 'PICKED_UP';
      case TripStatus.noShow:
        return 'NO_SHOW';
      default:
        return status.toString().split('.').last.toUpperCase();
    }
  }

  bool _isFirstLoad = true;

  /// Fetch trips from backend API
  Future<void> fetchTripsFromBackend(String driverId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(
        Uri.parse('$_baseUrl/trips?driverId=$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final newTrips = data
          .where((t) => t['driverId'] == driverId)
          .map((t) => _parseTripFromBackend(t))
          .toList();
          
        // Check for new assignments to trigger notification
        // We only notify if this isn't the very first load to avoid spamming on startup
        // OR if the list was empty but now has items (which technically is an update if proper empty state existed)
        if (!_isFirstLoad) {
           final existingIds = _trips.map((t) => t.id).toSet();
           for (final trip in newTrips) {
             if (!existingIds.contains(trip.id) && 
                (trip.status == TripStatus.assigned || trip.status == TripStatus.scheduled)) {
               
               // Found a new trip! Notify user.
               final timeFormat = DateFormat('h:mm a');
               
               NotificationService().showTripAssignedNotification(
                  tripId: trip.id,
                  pickupAddress: trip.pickupAddress,
                  pickupTime: timeFormat.format(trip.scheduledPickupTime),
                  memberName: null,
               );
             }
           }
        }
        
        _trips = newTrips;
        _isFirstLoad = false;
        await _saveTrips();
      }
    } catch (e) {
      debugPrint('Error fetching trips from backend: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<TripModel> getDriverTrips(String driverId) => _trips.where((t) => t.driverId == driverId).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  
  List<TripModel> getTodayTrips(String driverId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    // Include ALL active trips (not completed/cancelled) scheduled before tomorrow. 
    // This ensures overdue/past trips still show up in the "Today" list/count.
    return _trips.where((t) => 
      t.driverId == driverId && 
      t.scheduledPickupTime.isBefore(tomorrow) && 
      t.status != TripStatus.completed && 
      t.status != TripStatus.cancelled &&
      t.status != TripStatus.noShow
    ).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  }

  List<TripModel> getCompletedTripsForToday(String driverId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _trips.where((t) => 
      t.driverId == driverId && 
      t.status == TripStatus.completed &&
      // Check actual dropoff time first, then scheduled time as fallback
      ((t.actualDropoffTime != null && t.actualDropoffTime!.isAfter(today) && t.actualDropoffTime!.isBefore(tomorrow)) || 
       (t.scheduledPickupTime.isAfter(today) && t.scheduledPickupTime.isBefore(tomorrow)))
    ).toList()..sort((a, b) => (b.actualDropoffTime ?? b.scheduledPickupTime).compareTo(a.actualDropoffTime ?? a.scheduledPickupTime));
  }
  
  List<TripModel> getUpcomingTrips(String driverId) {
    final now = DateTime.now();
    // upcoming means scheduled in the future (after now)
    return _trips.where((t) => 
      t.driverId == driverId && 
      t.scheduledPickupTime.isAfter(now) && 
      (t.status == TripStatus.scheduled || t.status == TripStatus.assigned)
    ).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  }
  
  List<TripModel> getUnassignedTrips() => _trips.where((t) => t.driverId == null && t.status == TripStatus.scheduled).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  
  Future<void> loadTrips() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tripsJson = prefs.getString(_storageKey);
      
      if (tripsJson != null) {
        final List<dynamic> decoded = jsonDecode(tripsJson);
        _trips = decoded.map((json) => TripModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Sample data will be initialized when initializeSampleTrips is called
        _trips = [];
      }
    } catch (e) {
      debugPrint('Failed to load trips: $e');
      _trips = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> initializeSampleTrips(List<dynamic> members, List<dynamic> drivers) async {
    if (_trips.isNotEmpty) return; // Already has data
    if (members.length < 3 || drivers.isEmpty) return; // Need users first
    
    await _initializeSampleDataWithUsers(members, drivers);
  }
  
  Future<void> _saveTrips() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_trips.map((t) => t.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Failed to save trips: $e');
    }
  }
  
  Future<void> _initializeSampleDataWithUsers(List<dynamic> members, List<dynamic> drivers) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final member1 = members[0];
    final member2 = members[1];
    final member3 = members[2];
    final driver1 = drivers[0];
    final driver2 = drivers.length > 1 ? drivers[1] : drivers[0];
    
    _trips = [
      // Today's trips
      TripModel(
        id: _uuid.v4(),
        memberId: member1.id,
        driverId: driver1.id,
        tripType: TripType.oneWay,
        status: TripStatus.assigned,
        scheduledPickupTime: today.add(const Duration(hours: 9, minutes: 30)),
        estimatedDropoffTime: today.add(const Duration(hours: 10, minutes: 15)),
        pickupAddress: member1.address ?? '1234 E Main St',
        pickupCity: member1.city ?? 'Phoenix',
        pickupState: member1.state ?? 'AZ',
        pickupZip: member1.zipCode ?? '85001',
        dropoffAddress: 'Banner University Medical Center, 1111 E McDowell Rd',
        dropoffCity: 'Phoenix',
        dropoffState: 'AZ',
        dropoffZip: '85006',
        appointmentType: 'Dialysis',
        facilityName: 'Banner University Medical Center',
        facilityPhone: '(602) 839-2000',
        mobilityAid: member1.mobilityAid ?? 'walker',
        requiresAttendant: false,
        attendantCount: 0,
        oxygenRequired: false,
        authorizationNumber: 'AUTH-2024-001',
        membershipId: member1.membershipId ?? 'AHC123456',
        priority: 'routine',
        estimatedMiles: 8.5,
        estimatedDuration: 45,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now,
      ),
      TripModel(
        id: _uuid.v4(),
        memberId: member2.id,
        driverId: driver1.id,
        tripType: TripType.oneWay,
        status: TripStatus.assigned,
        scheduledPickupTime: today.add(const Duration(hours: 13, minutes: 0)),
        estimatedDropoffTime: today.add(const Duration(hours: 13, minutes: 45)),
        pickupAddress: member2.address ?? '5678 W Central Ave',
        pickupCity: member2.city ?? 'Phoenix',
        pickupState: member2.state ?? 'AZ',
        pickupZip: member2.zipCode ?? '85003',
        dropoffAddress: 'CVS Pharmacy, 2929 E Thomas Rd',
        dropoffCity: 'Phoenix',
        dropoffState: 'AZ',
        dropoffZip: '85016',
        appointmentType: 'Pharmacy',
        facilityName: 'CVS Pharmacy',
        mobilityAid: member2.mobilityAid ?? 'wheelchair',
        requiresAttendant: true,
        attendantCount: 1,
        oxygenRequired: false,
        authorizationNumber: 'AUTH-2024-002',
        membershipId: member2.membershipId ?? 'AHC234567',
        priority: 'routine',
        estimatedMiles: 6.2,
        estimatedDuration: 45,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now,
      ),
      TripModel(
        id: _uuid.v4(),
        memberId: member3.id,
        driverId: driver1.id,
        tripType: TripType.oneWay,
        status: TripStatus.assigned,
        scheduledPickupTime: today.add(const Duration(hours: 15, minutes: 30)),
        estimatedDropoffTime: today.add(const Duration(hours: 16, minutes: 0)),
        pickupAddress: member3.address ?? '9012 N 7th St',
        pickupCity: member3.city ?? 'Phoenix',
        pickupState: member3.state ?? 'AZ',
        pickupZip: member3.zipCode ?? '85020',
        dropoffAddress: 'Phoenix VA Health Care System, 650 E Indian School Rd',
        dropoffCity: 'Phoenix',
        dropoffState: 'AZ',
        dropoffZip: '85012',
        appointmentType: 'Medical',
        facilityName: 'Phoenix VA Health Care System',
        facilityPhone: '(602) 277-5551',
        mobilityAid: member3.mobilityAid ?? 'none',
        requiresAttendant: false,
        attendantCount: 0,
        oxygenRequired: false,
        authorizationNumber: 'AUTH-2024-003',
        membershipId: member3.membershipId ?? 'AHC345678',
        priority: 'routine',
        estimatedMiles: 5.8,
        estimatedDuration: 30,
        createdAt: now.subtract(const Duration(hours: 12)),
        updatedAt: now,
      ),
      // Tomorrow's trips
      TripModel(
        id: _uuid.v4(),
        memberId: member1.id,
        driverId: driver2.id,
        tripType: TripType.oneWay,
        status: TripStatus.assigned,
        scheduledPickupTime: today.add(const Duration(days: 1, hours: 8, minutes: 0)),
        pickupAddress: member1.address ?? '1234 E Main St',
        pickupCity: member1.city ?? 'Phoenix',
        pickupState: member1.state ?? 'AZ',
        pickupZip: member1.zipCode ?? '85001',
        dropoffAddress: 'Fresenius Kidney Care, 2222 E Highland Ave',
        dropoffCity: 'Phoenix',
        dropoffState: 'AZ',
        dropoffZip: '85016',
        appointmentType: 'Dialysis',
        facilityName: 'Fresenius Kidney Care',
        mobilityAid: member1.mobilityAid ?? 'walker',
        authorizationNumber: 'AUTH-2024-004',
        membershipId: member1.membershipId ?? 'AHC123456',
        priority: 'routine',
        estimatedMiles: 7.3,
        estimatedDuration: 40,
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now,
      ),
      // Unassigned trip
      TripModel(
        id: _uuid.v4(),
        memberId: member2.id,
        tripType: TripType.oneWay,
        status: TripStatus.scheduled,
        scheduledPickupTime: today.add(const Duration(days: 2, hours: 10, minutes: 30)),
        pickupAddress: member2.address ?? '5678 W Central Ave',
        pickupCity: member2.city ?? 'Phoenix',
        pickupState: member2.state ?? 'AZ',
        pickupZip: member2.zipCode ?? '85003',
        dropoffAddress: 'Mayo Clinic, 5777 E Mayo Blvd',
        dropoffCity: 'Phoenix',
        dropoffState: 'AZ',
        dropoffZip: '85054',
        appointmentType: 'Medical',
        facilityName: 'Mayo Clinic',
        facilityPhone: '+1 480 910 6805',
        mobilityAid: member2.mobilityAid ?? 'wheelchair',
        requiresAttendant: true,
        attendantCount: 1,
        authorizationNumber: 'AUTH-2024-005',
        membershipId: member2.membershipId ?? 'AHC234567',
        priority: 'urgent',
        estimatedMiles: 12.5,
        estimatedDuration: 60,
        createdAt: now,
        updatedAt: now,
      ),
    ];
    await _saveTrips();
    notifyListeners();
  }
  
  Future<void> addTrip(TripModel trip) async {
    _trips.add(trip);
    await _saveTrips();
    notifyListeners();
  }
  
  Future<void> updateTrip(TripModel trip) async {
    final index = _trips.indexWhere((t) => t.id == trip.id);
    if (index != -1) {
      _trips[index] = trip.copyWith(updatedAt: DateTime.now());
      await _saveTrips();
      notifyListeners();
    }
  }
  
  Future<void> deleteTrip(String tripId) async {
    _trips.removeWhere((t) => t.id == tripId);
    await _saveTrips();
    notifyListeners();
  }
  
  Future<void> assignDriver(String tripId, String driverId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(driverId: driverId, status: TripStatus.assigned));
  }
  
  Future<void> startTrip(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(status: TripStatus.enRoute));
    _emitTripStatusUpdate(tripId, TripStatus.enRoute);
    _updateTripOnBackend(tripId, {'status': 'EN_ROUTE'});
  }

  Future<void> arriveAtPickup(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(status: TripStatus.arrived));
    _emitTripStatusUpdate(tripId, TripStatus.arrived);
    _updateTripOnBackend(tripId, {'status': 'ARRIVED'});
  }

  Future<void> pickupMember(String tripId, {int? pickupOdometer}) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(
      status: TripStatus.pickedUp,
      actualPickupTime: DateTime.now(),
    ));
    _emitTripStatusUpdate(tripId, TripStatus.pickedUp, pickupOdometer: pickupOdometer);
    _updateTripOnBackend(tripId, {
      'status': 'PICKED_UP',
      'actualPickupTime': DateTime.now().toIso8601String(),
      if (pickupOdometer != null) 'pickupOdometer': pickupOdometer,
    });
  }

  Future<void> undoLastAction(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    TripStatus newStatus = trip.status;
    
    switch (trip.status) {
      case TripStatus.enRoute:
        newStatus = TripStatus.assigned;
        break;
      case TripStatus.arrived:
        newStatus = TripStatus.enRoute;
        break;
      case TripStatus.pickedUp:
        newStatus = TripStatus.arrived;
        break;
      case TripStatus.completed: // Optional: allow undoing completion if accidental
        newStatus = TripStatus.pickedUp;
        break;
      default:
        return;
    }
    
    await updateTrip(trip.copyWith(status: newStatus));
    _emitTripStatusUpdate(tripId, newStatus);
    _updateTripOnBackend(tripId, {'status': _mapStatusToBackendString(newStatus)});
  }

  Future<void> completeTrip(String tripId, {double? actualMiles, String? notes, String? driverSignature, String? memberSignature}) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final pickupTime = trip.actualPickupTime ?? DateTime.now();
    final dropoffTime = DateTime.now();
    final duration = dropoffTime.difference(pickupTime).inMinutes;

    await updateTrip(trip.copyWith(
      status: TripStatus.completed,
      actualDropoffTime: dropoffTime,
      actualMiles: actualMiles,
      actualDuration: duration,
      notes: notes,
      driverSignature: driverSignature,
      memberSignature: memberSignature,
    ));
    _emitTripStatusUpdate(tripId, TripStatus.completed,
      driverSignature: driverSignature,
      memberSignature: memberSignature,
    );
  }

  /// Complete trip with full AHCCCS Daily Trip Report data
  Future<void> completeTripWithReport(
    String tripId, {
    int? pickupOdometer,
    int? dropoffOdometer,
    double? actualMiles,
    String? reasonForVisit,
    String? escortName,
    String? escortRelationship,
    String? driverSignature,
    String? memberSignature,
    String? notes,
  }) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final pickupTime = trip.actualPickupTime ?? DateTime.now();
    final dropoffTime = DateTime.now();
    final duration = dropoffTime.difference(pickupTime).inMinutes;

    // Calculate trip miles from odometer if not provided
    final calculatedMiles = actualMiles ??
      (pickupOdometer != null && dropoffOdometer != null
        ? (dropoffOdometer - pickupOdometer).toDouble()
        : null);

    // Update local trip
    await updateTrip(trip.copyWith(
      status: TripStatus.completed,
      actualDropoffTime: dropoffTime,
      actualMiles: calculatedMiles,
      actualDuration: duration,
      notes: notes,
      driverSignature: driverSignature,
      memberSignature: memberSignature,
    ));

    // Emit WebSocket update
    _emitTripStatusUpdate(
      tripId,
      TripStatus.completed,
      pickupOdometer: pickupOdometer,
      dropoffOdometer: dropoffOdometer,
      driverSignature: driverSignature,
      memberSignature: memberSignature,
    );

    // Update on backend - this triggers PDF generation and email
    await _updateTripOnBackend(tripId, {
      'status': 'COMPLETED',
      'actualDropoffTime': dropoffTime.toIso8601String(),
      if (pickupOdometer != null) 'pickupOdometer': pickupOdometer,
      if (dropoffOdometer != null) 'dropoffOdometer': dropoffOdometer,
      if (reasonForVisit != null) 'reasonForVisit': reasonForVisit,
      if (escortName != null) 'escortName': escortName,
      if (escortRelationship != null) 'escortRelationship': escortRelationship,
      if (driverSignature != null) 'driverSignatureUrl': driverSignature,
      if (memberSignature != null) 'memberSignatureUrl': memberSignature,
      if (notes != null) 'notes': notes,
    });
  }

  /// Update trip on backend via HTTP API
  Future<void> _updateTripOnBackend(String tripId, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/trips/$tripId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode != 200) {
        debugPrint('Failed to update trip on backend: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error updating trip on backend: $e');
    }
  }

  Future<void> cancelTrip(String tripId, String reason, String description) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(
      status: TripStatus.cancelled,
      cancellationReason: reason,
      cancellationTime: DateTime.now(),
      notes: 'CANCELLATION: $description',
    ));
    _updateTripOnBackend(tripId, {
      'status': 'CANCELLED',
      'notes': 'CANCELLATION: $reason - $description',
    });
  }
  
  
  TripModel? getTripById(String id) => _trips.firstWhere((t) => t.id == id, orElse: () => _trips.first);
  
  String createTripId() => _uuid.v4();

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
