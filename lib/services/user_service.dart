import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:yazdrive/models/user_model.dart';

/// Service for managing users (drivers, dispatchers, admins, members)
class UserService extends ChangeNotifier {
  static const String _storageKey = 'users';
  static const String _currentUserKey = 'current_user_id';
  final Uuid _uuid = const Uuid();
  
  List<UserModel> _users = [];
  String? _currentUserId;
  bool _isLoading = false;
  
  List<UserModel> get users => _users;
  UserModel? get currentUser => _currentUserId != null ? _users.firstWhere((u) => u.id == _currentUserId, orElse: () => _users.first) : null;
  bool get isLoading => _isLoading;
  
  List<UserModel> get drivers => _users.where((u) => u.role == UserRole.driver && u.isActive).toList();
  List<UserModel> get members => _users.where((u) => u.role == UserRole.member && u.isActive).toList();
  List<UserModel> get dispatchers => _users.where((u) => u.role == UserRole.dispatcher && u.isActive).toList();
  List<UserModel> get admins => _users.where((u) => u.role == UserRole.admin && u.isActive).toList();
  
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? usersJson = prefs.getString(_storageKey);
      final String? currentUserId = prefs.getString(_currentUserKey);
      
      if (usersJson != null) {
        final List<dynamic> decoded = jsonDecode(usersJson);
        _users = decoded.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
        _currentUserId = currentUserId;
      } else {
        await _initializeSampleData();
      }
    } catch (e) {
      debugPrint('Failed to load users: \$e');
      await _initializeSampleData();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> _saveUsers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(_users.map((u) => u.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      debugPrint('Failed to save users: \$e');
    }
  }
  
  Future<void> _initializeSampleData() async {
    final now = DateTime.now();
    _users = [
      // Admin
      UserModel(
        id: _uuid.v4(),
        email: 'admin@yazdrive.com',
        firstName: 'Sarah',
        lastName: 'Johnson',
        phoneNumber: '(602) 555-0100',
        role: UserRole.admin,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 365)),
        updatedAt: now,
      ),
      // Dispatchers
      UserModel(
        id: _uuid.v4(),
        email: 'dispatcher1@yazdrive.com',
        firstName: 'Michael',
        lastName: 'Chen',
        phoneNumber: '(602) 555-0101',
        role: UserRole.dispatcher,
        isActive: true,
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
      // Drivers
      UserModel(
        id: _uuid.v4(),
        email: 'driver1@yazdrive.com',
        firstName: 'James',
        lastName: 'Martinez',
        phoneNumber: '(602) 555-0201',
        role: UserRole.driver,
        isActive: true,
        licenseNumber: 'D1234567',
        licenseExpiry: DateTime(2025, 12, 31),
        certifications: ['CPR', 'First Aid', 'Defensive Driving'],
        createdAt: now.subtract(const Duration(days: 90)),
        updatedAt: now,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'driver2@yazdrive.com',
        firstName: 'Emily',
        lastName: 'Davis',
        phoneNumber: '(602) 555-0202',
        role: UserRole.driver,
        isActive: true,
        licenseNumber: 'D2345678',
        licenseExpiry: DateTime(2025, 10, 15),
        certifications: ['CPR', 'First Aid'],
        createdAt: now.subtract(const Duration(days: 60)),
        updatedAt: now,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'driver3@yazdrive.com',
        firstName: 'Robert',
        lastName: 'Wilson',
        phoneNumber: '(602) 555-0203',
        role: UserRole.driver,
        isActive: true,
        licenseNumber: 'D3456789',
        licenseExpiry: DateTime(2025, 8, 20),
        certifications: ['CPR', 'First Aid', 'Wheelchair Transport'],
        createdAt: now.subtract(const Duration(days: 45)),
        updatedAt: now,
      ),
      // Members
      UserModel(
        id: _uuid.v4(),
        email: 'member1@example.com',
        firstName: 'Patricia',
        lastName: 'Anderson',
        phoneNumber: '(602) 555-0301',
        role: UserRole.member,
        isActive: true,
        membershipId: 'AHC123456',
        dateOfBirth: '1955-03-15',
        address: '1234 E Main St',
        city: 'Phoenix',
        state: 'AZ',
        zipCode: '85001',
        emergencyContact: 'John Anderson',
        emergencyPhone: '(602) 555-0350',
        medicalConditions: ['Diabetes', 'Hypertension'],
        mobilityAid: 'walker',
        createdAt: now.subtract(const Duration(days: 200)),
        updatedAt: now,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'member2@example.com',
        firstName: 'David',
        lastName: 'Thompson',
        phoneNumber: '(602) 555-0302',
        role: UserRole.member,
        isActive: true,
        membershipId: 'AHC234567',
        dateOfBirth: '1948-07-22',
        address: '5678 W Central Ave',
        city: 'Phoenix',
        state: 'AZ',
        zipCode: '85003',
        emergencyContact: 'Mary Thompson',
        emergencyPhone: '(602) 555-0360',
        medicalConditions: ['COPD', 'Arthritis'],
        mobilityAid: 'wheelchair',
        createdAt: now.subtract(const Duration(days: 180)),
        updatedAt: now,
      ),
      UserModel(
        id: _uuid.v4(),
        email: 'member3@example.com',
        firstName: 'Linda',
        lastName: 'Garcia',
        phoneNumber: '(602) 555-0303',
        role: UserRole.member,
        isActive: true,
        membershipId: 'AHC345678',
        dateOfBirth: '1962-11-08',
        address: '9012 N 7th St',
        city: 'Phoenix',
        state: 'AZ',
        zipCode: '85020',
        emergencyContact: 'Carlos Garcia',
        emergencyPhone: '(602) 555-0370',
        medicalConditions: ['Dialysis Patient'],
        mobilityAid: 'none',
        createdAt: now.subtract(const Duration(days: 150)),
        updatedAt: now,
      ),
    ];
    
    // Set first driver as current user by default
    _currentUserId = drivers.first.id;
    await _saveUsers();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, _currentUserId!);
  }
  
  Future<void> setCurrentUser(String userId) async {
    _currentUserId = userId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserKey, userId);
    notifyListeners();
  }
  
  Future<void> addUser(UserModel user) async {
    _users.add(user);
    await _saveUsers();
    notifyListeners();
  }
  
  Future<void> updateUser(UserModel user) async {
    final index = _users.indexWhere((u) => u.id == user.id);
    if (index != -1) {
      _users[index] = user.copyWith(updatedAt: DateTime.now());
      await _saveUsers();
      notifyListeners();
    }
  }
  
  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    await _saveUsers();
    notifyListeners();
  }
  
  UserModel? getUserById(String id) => _users.firstWhere((u) => u.id == id, orElse: () => _users.first);
  
  Future<UserModel?> login(String email, String role) async {
    final user = _users.where((u) => u.email == email && u.role.toString().split('.').last == role.toLowerCase()).firstOrNull;
    if (user != null) {
      await setCurrentUser(user.id);
    }
    return user;
  }
  
  Future<void> logout() async {
    _currentUserId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    notifyListeners();
  }
}
