import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:yazdrive/models/user_model.dart';

/// Service for managing users (drivers, dispatchers, admins, members)
class UserService extends ChangeNotifier {
  static const String _storageKey = 'users';
  static const String _currentUserKey = 'current_user_id';
  static const String _tokenKey = 'auth_token';

   // Dynamic Base URL
  static String get _baseUrl {
    // Use production URL if needed, otherwise use local
    const useProduction = bool.fromEnvironment('USE_PRODUCTION', defaultValue: false);

    if (useProduction) {
      return 'https://driveme-backedn-production.up.railway.app';
    }

    if (kIsWeb) return 'http://localhost:3001';
    return Platform.isAndroid ? 'http://10.0.2.2:3001' : 'http://localhost:3001';
  } 

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
  
  Future<UserModel?> login(String email, String role) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'role': role}),
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
}
