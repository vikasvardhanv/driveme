import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:yazdrive/models/user_model.dart';
import 'package:yazdrive/services/api_service.dart';

/// Service for managing users (drivers, dispatchers, admins, members)
class UserService extends ChangeNotifier {
  static const String _storageKey = 'users';
  static const String _currentUserKey = 'current_user_id';
  static const String _tokenKey = 'auth_token';

   // Dynamic Base URL
  static String get _baseUrl => ApiService.baseUrl;

  final Uuid _uuid = const Uuid();
  
  List<UserModel> _users = [];
  String? _currentUserId;
  bool _isLoading = false;
  
  List<UserModel> get users => _users;
  UserModel? get currentUser => _currentUserId != null 
      ? _users.firstWhere((u) => u.id == _currentUserId, orElse: () => _users.first) 
      : null;
  bool get isLoading => _isLoading;
  
  // Getters required by the app
  List<UserModel> get drivers => _users.where((u) => u.role == UserRole.driver && u.isActive).toList();
  List<UserModel> get members => _users.where((u) => u.role == UserRole.member && u.isActive).toList();
  List<UserModel> get admins => _users.where((u) => u.role == UserRole.admin && u.isActive).toList();
  List<UserModel> get dispatchers => _users.where((u) => u.role == UserRole.dispatcher && u.isActive).toList();


  Future<void> loadUsers() async {
     await _initializeSampleData();
     await fetchDrivers();
     notifyListeners();
  }
  
  // Helper method used by UI
  UserModel? getUserById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _initializeSampleData() async {
    // Basic fallback data if needed
  }
  
  Future<UserModel?> login(String email, String password, [String role = 'DRIVER']) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'role': role.toUpperCase()}),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['access_token'];
        final userJson = data['user'];
        
        final user = UserModel(
          id: userJson['id'],
          email: userJson['email'],
          firstName: userJson['firstName'],
          lastName: userJson['lastName'],
          phoneNumber: userJson['phone'] ?? '',
          role: UserRole.values.firstWhere(
            (e) => e.toString().split('.').last.toLowerCase() == (userJson['role'] as String).toLowerCase(),
            orElse: () => UserRole.driver
          ),
          isActive: userJson['isActive'] ?? true,
          createdAt: DateTime.parse(userJson['createdAt']),
          updatedAt: DateTime.parse(userJson['updatedAt']),
        );

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_currentUserKey, user.id);
        
        _currentUserId = user.id;
        
        if (!_users.any((u) => u.id == user.id)) {
          _users.add(user);
        }
        
        notifyListeners();
        return user;
      } else {
        debugPrint('Login failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Login error: $e');
      return null;
    }
  }

  Future<void> logout() async {
     _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_tokenKey);
    notifyListeners();
  }

  /// Submit a new driver application
  Future<bool> submitApplication({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String licenseNumber,
  }) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, this would POST to /api/driver/apply
      // For now, we'll just simulate success
      debugPrint('Application submitted for: $firstName $lastName');
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error submitting application: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Fetch drivers from backend (Azuga sync)
  Future<void> fetchDrivers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/azuga/drivers'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Clear existing drivers to avoid duplicates or assume full sync
        // Ideally we merge, but for now let's just add new ones if not present
        
        for (var item in data) {
          final id = item['id'];
          // Check if already exists
          if (_users.any((u) => u.id == id)) continue;
          
          // Parse name
          final nameParts = (item['name'] as String).split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : 'Unknown';
          final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
          
          final driver = UserModel(
            id: id,
            email: item['email'] ?? 'no-email-$id@example.com',
            firstName: firstName,
            lastName: lastName,
            phoneNumber: item['phone'] ?? '',
            role: UserRole.driver,
            isActive: item['isActive'] ?? true,
            createdAt: DateTime.now(), // Not provided by this endpoint
            updatedAt: DateTime.now(),
            vehicleId: item['vehicleId'],
          );
          
          _users.add(driver);
        }
        
        notifyListeners();
      } else {
        debugPrint('Failed to fetch drivers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching drivers: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
