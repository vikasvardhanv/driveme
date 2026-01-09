import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:yazdrive/models/vehicle_model.dart';

/// Service for managing vehicles
class VehicleService extends ChangeNotifier {
  static const String _storageKey = 'vehicles';
  final Uuid _uuid = const Uuid();
  
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  
  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  List<VehicleModel> get activeVehicles => _vehicles.where((v) => v.isActive).toList();
  List<VehicleModel> get wheelchairAccessibleVehicles => _vehicles.where((v) => v.isActive && v.wheelchairAccessible).toList();
  
  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? vehiclesJson = prefs.getString(_storageKey);
      
      if (vehiclesJson != null) {
        final List<dynamic> decoded = jsonDecode(vehiclesJson);
        _vehicles = decoded.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        await _initializeSampleData();
      }
    } catch (e) {
      debugPrint('Failed to load vehicles: \$e');
      await _initializeSampleData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _saveVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_vehicles.map((v) => v.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Failed to save vehicles: \$e');
    }
  }
  
  Future<void> _initializeSampleData() async {
    final now = DateTime.now();
    _vehicles = [
      VehicleModel(
        id: _uuid.v4(),
        make: 'Toyota',
        model: 'Sienna',
        year: 2023,
        licensePlate: 'AZ-NEMT-001',
        vin: '5TDKZ3DC5PS123456',
        color: 'Silver',
        type: VehicleType.van,
        capacity: 7,
        wheelchairAccessible: false,
        hasOxygen: false,
        isActive: true,
        currentMileage: 15420,
        lastMaintenance: now.subtract(const Duration(days: 45)),
        nextMaintenanceDue: now.add(const Duration(days: 15)),
        insuranceProvider: 'State Farm',
        insurancePolicyNumber: 'POL-2023-001',
        insuranceExpiry: DateTime(2025, 6, 30),
        registrationExpiry: DateTime(2025, 3, 15),
        registrationState: 'AZ',
        lastInspection: now.subtract(const Duration(days: 60)),
        nextInspectionDue: now.add(const Duration(days: 305)),
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
      VehicleModel(
        id: _uuid.v4(),
        make: 'Chrysler',
        model: 'Pacifica',
        year: 2022,
        licensePlate: 'AZ-NEMT-002',
        vin: '2C4RC1BG5NR234567',
        color: 'White',
        type: VehicleType.wheelchairVan,
        capacity: 4,
        wheelchairAccessible: true,
        hasOxygen: true,
        isActive: true,
        currentMileage: 28750,
        lastMaintenance: now.subtract(const Duration(days: 30)),
        nextMaintenanceDue: now.add(const Duration(days: 30)),
        insuranceProvider: 'State Farm',
        insurancePolicyNumber: 'POL-2023-002',
        insuranceExpiry: DateTime(2025, 6, 30),
        registrationExpiry: DateTime(2025, 4, 20),
        registrationState: 'AZ',
        lastInspection: now.subtract(const Duration(days: 75)),
        nextInspectionDue: now.add(const Duration(days: 290)),
        createdAt: now.subtract(const Duration(days: 240)),
        updatedAt: now,
      ),
      VehicleModel(
        id: _uuid.v4(),
        make: 'Honda',
        model: 'Odyssey',
        year: 2023,
        licensePlate: 'AZ-NEMT-003',
        vin: '5FNRL6H78NB345678',
        color: 'Blue',
        type: VehicleType.van,
        capacity: 7,
        wheelchairAccessible: false,
        hasOxygen: false,
        isActive: true,
        currentMileage: 12340,
        lastMaintenance: now.subtract(const Duration(days: 20)),
        nextMaintenanceDue: now.add(const Duration(days: 40)),
        insuranceProvider: 'State Farm',
        insurancePolicyNumber: 'POL-2023-003',
        insuranceExpiry: DateTime(2025, 6, 30),
        registrationExpiry: DateTime(2025, 5, 10),
        registrationState: 'AZ',
        lastInspection: now.subtract(const Duration(days: 50)),
        nextInspectionDue: now.add(const Duration(days: 315)),
        createdAt: now.subtract(const Duration(days: 120)),
        updatedAt: now,
      ),
    ];
    await _saveVehicles();
  }
  
  Future<void> addVehicle(VehicleModel vehicle) async {
    _vehicles.add(vehicle);
    await _saveVehicles();
    notifyListeners();
  }
  
  Future<void> updateVehicle(VehicleModel vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle.copyWith(updatedAt: DateTime.now());
      await _saveVehicles();
      notifyListeners();
    }
  }
  
  Future<void> deleteVehicle(String vehicleId) async {
    _vehicles.removeWhere((v) => v.id == vehicleId);
    await _saveVehicles();
    notifyListeners();
  }
  
  VehicleModel? getVehicleById(String id) => _vehicles.firstWhere((v) => v.id == id, orElse: () => _vehicles.first);
}
