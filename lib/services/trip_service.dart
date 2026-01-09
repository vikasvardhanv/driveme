import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:yazdrive/models/trip_model.dart';

/// Service for managing NEMT trips
class TripService extends ChangeNotifier {
  static const String _storageKey = 'trips';
  final Uuid _uuid = const Uuid();
  
  List<TripModel> _trips = [];
  bool _isLoading = false;
  
  List<TripModel> get trips => _trips;
  bool get isLoading => _isLoading;
  
  List<TripModel> getDriverTrips(String driverId) => _trips.where((t) => t.driverId == driverId).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  
  List<TripModel> getTodayTrips(String driverId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    return _trips.where((t) => t.driverId == driverId && t.scheduledPickupTime.isAfter(today) && t.scheduledPickupTime.isBefore(tomorrow) && t.status != TripStatus.completed && t.status != TripStatus.cancelled).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
  }
  
  List<TripModel> getUpcomingTrips(String driverId) {
    final now = DateTime.now();
    return _trips.where((t) => t.driverId == driverId && t.scheduledPickupTime.isAfter(now) && (t.status == TripStatus.scheduled || t.status == TripStatus.assigned)).toList()..sort((a, b) => a.scheduledPickupTime.compareTo(b.scheduledPickupTime));
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
      debugPrint('Failed to load trips: \$e');
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
      debugPrint('Failed to save trips: \$e');
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
        facilityPhone: '(480) 301-8000',
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
  }
  
  Future<void> arriveAtPickup(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(status: TripStatus.arrived));
  }
  
  Future<void> pickupMember(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(status: TripStatus.pickedUp, actualPickupTime: DateTime.now()));
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
  }
  
  Future<void> cancelTrip(String tripId, String reason) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    await updateTrip(trip.copyWith(
      status: TripStatus.cancelled,
      cancellationReason: reason,
      cancellationTime: DateTime.now(),
    ));
  }
  
  TripModel? getTripById(String id) => _trips.firstWhere((t) => t.id == id, orElse: () => _trips.first);
  
  String createTripId() => _uuid.v4();
}
