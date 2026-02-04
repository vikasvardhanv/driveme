import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yazdrive/models/vehicle_model.dart';
import 'package:yazdrive/services/api_service.dart';

/// Service for managing vehicles
class VehicleService extends ChangeNotifier {
  static const String _storageKey = 'vehicles';
  final ApiService _apiService = ApiService();
  
  List<VehicleModel> _vehicles = [];
  bool _isLoading = false;
  VehicleModel? _selectedVehicle;
  
  List<VehicleModel> get vehicles => _vehicles;
  bool get isLoading => _isLoading;
  VehicleModel? get selectedVehicle => _selectedVehicle;
  List<VehicleModel> get activeVehicles => _vehicles.where((v) => v.isActive).toList();
  List<VehicleModel> get wheelchairAccessibleVehicles => _vehicles.where((v) => v.isActive && v.wheelchairAccessible).toList();
  
  /// Select a vehicle for the current driving session
  void selectVehicle(VehicleModel vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }
  
  /// Clear selected vehicle (when driver logs out or ends shift)
  void clearSelectedVehicle() {
    _selectedVehicle = null;
    notifyListeners();
  }
  
  /// Search vehicles by license plate, VIN, make, or model
  List<VehicleModel> searchVehicles(String query) {
    if (query.isEmpty) return activeVehicles;
    return activeVehicles.where((v) =>
      v.licensePlate.toLowerCase().contains(query.toLowerCase()) ||
      v.vin.toLowerCase().contains(query.toLowerCase()) ||
      v.make.toLowerCase().contains(query.toLowerCase()) ||
      v.model.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Try to fetch from API
      try {
        final List<dynamic> data = await _apiService.get('/vehicles');
        _vehicles = data.map((json) {
           // Ensure the backend response matches VehicleModel expectations
           // If backend returns different specific fields, map them here.
           // For now assuming direct mapping + some defaults for missing fields
           return VehicleModel(
             id: json['id'] ?? '',
             make: json['make'] ?? 'Unknown',
             model: json['model'] ?? 'Unknown',
             year: json['year'] ?? 2020,
             licensePlate: json['licensePlate'] ?? '',
             vin: json['vin'] ?? '',
             color: json['color'] ?? 'Unknown',
             // Map backend 'vehicleType' to enum if needed, defaulting for now
             type: _parseVehicleType(json['vehicleType']),
             capacity: json['capacity'] ?? 4,
             wheelchairAccessible: json['wheelchairAccessible'] ?? false,
             hasOxygen: json['hasOxygen'] ?? false,
             isActive: json['isActive'] ?? true,
             currentMileage: json['currentMileage'] ?? 0,
             lastMaintenance: json['lastMaintenance'] != null ? DateTime.parse(json['lastMaintenance']) : DateTime.now(),
             nextMaintenanceDue: json['nextMaintenanceDue'] != null ? DateTime.parse(json['nextMaintenanceDue']) : DateTime.now().add(const Duration(days: 90)),
             insuranceProvider: json['insuranceProvider'] ?? '',
             insurancePolicyNumber: json['insurancePolicyNumber'] ?? '',
             insuranceExpiry: json['insuranceExpiry'] != null ? DateTime.parse(json['insuranceExpiry']) : DateTime.now().add(const Duration(days: 365)),
             registrationExpiry: json['registrationExpiry'] != null ? DateTime.parse(json['registrationExpiry']) : DateTime.now().add(const Duration(days: 365)),
             registrationState: json['registrationState'] ?? 'AZ',
             lastInspection: json['lastInspection'] != null ? DateTime.parse(json['lastInspection']) : DateTime.now(),
             nextInspectionDue: json['nextInspectionDue'] != null ? DateTime.parse(json['nextInspectionDue']) : DateTime.now().add(const Duration(days: 365)),
             createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
             updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
           );
        }).toList();
        
        // Save to local storage for offline fallback
        await _saveVehicles();
        
      } catch (e) {
        debugPrint('API Error loading vehicles, falling back to cache: \$e');
        // Fallback to local storage
        final prefs = await SharedPreferences.getInstance();
        final String? vehiclesJson = prefs.getString(_storageKey);
        
        if (vehiclesJson != null) {
          final List<dynamic> decoded = jsonDecode(vehiclesJson);
          _vehicles = decoded.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>)).toList();
        }
      }
    } catch (e) {
      debugPrint('Failed to load vehicles completely: \$e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  VehicleType _parseVehicleType(String? type) {
    if (type == null) return VehicleType.sedan;
    final t = type.toLowerCase();
    if (t.contains('wheelchair')) return VehicleType.wheelchairVan;
    if (t.contains('van')) return VehicleType.van;
    if (t.contains('ambulette')) return VehicleType.ambulette;
    if (t.contains('suv')) return VehicleType.suv;
    return VehicleType.sedan;
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
  
  Future<void> addVehicle(VehicleModel vehicle) async {
    // Optimistic update
    _vehicles.add(vehicle);
    notifyListeners();
    // TODO: Implement API call
  }
  
  Future<void> updateVehicle(VehicleModel vehicle) async {
     // Optimistic update
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle.copyWith(updatedAt: DateTime.now());
      notifyListeners();
      // TODO: Implement API call
    }
  }
  
  Future<void> deleteVehicle(String vehicleId) async {
    // Optimistic update
    _vehicles.removeWhere((v) => v.id == vehicleId);
    notifyListeners();
     // TODO: Implement API call
  }
  
  VehicleModel? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return _vehicles.isNotEmpty ? _vehicles.first : null;
    }
  }
}

