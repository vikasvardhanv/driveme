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
        debugPrint('Attempting to fetch vehicles from API: ${_apiService.toString()}');
        final List<dynamic> data = await _apiService.get('/vehicles');
        debugPrint('Successfully fetched ${data.length} vehicles from API');
        _vehicles = data.map((json) {
           // Map backend response to VehicleModel
           // Backend uses: wheelchairAccessible, oxygenCapable, currentOdometer
           return VehicleModel(
             id: json['id'] ?? '',
             make: json['make'] ?? 'Unknown',
             model: json['model'] ?? 'Unknown',
             year: json['year'] ?? 2020,
             licensePlate: json['licensePlate'] ?? '',
             vin: json['vin'] ?? '',
             color: json['color'] ?? 'Not Specified',
             type: _parseVehicleType(json['vehicleType']),
             capacity: json['capacity'] ?? 4,
             wheelchairAccessible: json['wheelchairAccessible'] ?? false,
             hasOxygen: json['oxygenCapable'] ?? false,  // Backend uses 'oxygenCapable'
             isActive: json['isActive'] ?? true,
             currentMileage: json['currentOdometer'] ?? 0,  // Backend uses 'currentOdometer'
             lastMaintenance: json['lastMaintenance'] != null ? DateTime.parse(json['lastMaintenance']) : DateTime.now().subtract(const Duration(days: 30)),
             nextMaintenanceDue: json['nextMaintenanceDue'] != null ? DateTime.parse(json['nextMaintenanceDue']) : DateTime.now().add(const Duration(days: 60)),
             insuranceProvider: json['insuranceProvider'] ?? '',
             insurancePolicyNumber: json['insurancePolicyNumber'] ?? '',
             insuranceExpiry: json['insuranceExpiry'] != null ? DateTime.parse(json['insuranceExpiry']) : DateTime.now().add(const Duration(days: 365)),
             registrationExpiry: json['registrationExpiry'] != null ? DateTime.parse(json['registrationExpiry']) : DateTime.now().add(const Duration(days: 365)),
             registrationState: json['registrationState'] ?? 'AZ',
             lastInspection: json['lastInspection'] != null ? DateTime.parse(json['lastInspection']) : DateTime.now().subtract(const Duration(days: 60)),
             nextInspectionDue: json['nextInspectionDue'] != null ? DateTime.parse(json['nextInspectionDue']) : DateTime.now().add(const Duration(days: 305)),
             createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
             updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.parse(json['updatedAt']),
           );
        }).toList();

        // Save to local storage for offline fallback
        await _saveVehicles();

      } catch (e) {
        debugPrint('API Error loading vehicles: $e');
        debugPrint('Error details: ${e.runtimeType}');
        if (e.toString().isNotEmpty) {
          debugPrint('Full error message: ${e.toString()}');
        }
        // Fallback to local storage
        final prefs = await SharedPreferences.getInstance();
        final String? vehiclesJson = prefs.getString(_storageKey);

        if (vehiclesJson != null) {
          debugPrint('Loading vehicles from cache');
          final List<dynamic> decoded = jsonDecode(vehiclesJson);
          _vehicles = decoded.map((json) => VehicleModel.fromJson(json as Map<String, dynamic>)).toList();
          debugPrint('Loaded ${_vehicles.length} vehicles from cache');
        } else {
          debugPrint('No vehicles available - backend API unavailable and no cache found');
          _vehicles = [];
        }
      }
    } catch (e) {
      debugPrint('Failed to load vehicles: \$e');
      _vehicles = [];
    } finally {
      debugPrint('Total vehicles available: ${_vehicles.length}');
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

