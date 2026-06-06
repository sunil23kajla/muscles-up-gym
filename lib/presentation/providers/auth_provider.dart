import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  List<UserModel> _pendingRequests = [];
  List<UserModel> _staffList = [];

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingRequests => _pendingRequests;
  List<UserModel> get staffList => _staffList;

  // Clear errors helper
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Load persisted login session on startup
  Future<void> loadPersistedLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('auth_user');
      
      if (token != null && userJson != null) {
        ApiClient.setToken(token);
        _currentUser = UserModel.fromJson(jsonDecode(userJson));
        notifyListeners();
      }
    } catch (_) {}
  }

  // Handle Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.login(email, password);
      _currentUser = result['user'];
      
      // Save session credentials
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', result['token']);
      await prefs.setString('auth_user', jsonEncode(_currentUser!.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register Request
  Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authRepo.register(
        name: name,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Fetch pending registration requests (Admin Only)
  Future<void> fetchPendingRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _pendingRequests = await _authRepo.getPendingRequests();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Approve or Reject a user registration (Admin Only)
  Future<bool> updateRequestStatus(String userId, String status) async {
    try {
      await _authRepo.updateRequestStatus(userId, status);
      // Remove approved/rejected user from list locally to update UI instantly without full refetch!
      _pendingRequests.removeWhere((u) => u.id == userId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Change password of current logged-in user (Self)
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.changePassword(oldPassword, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile details of current user (Self - Name/Email update, e.g. to transfer admin account)
  Future<bool> updateProfile(String name, String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _authRepo.updateProfile(name, email);
      _currentUser = updatedUser;

      // Update persisted session storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_user', jsonEncode(updatedUser.toJson()));

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch approved staff list (Admin only)
  Future<void> fetchStaffList() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _staffList = await _authRepo.getStaffList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Delete a staff member (Admin only)
  Future<bool> deleteStaff(String staffId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.deleteStaff(staffId);
      _staffList.removeWhere((s) => s.id == staffId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Admin override password reset for staff user (Admin only)
  Future<bool> adminResetPassword(String targetId, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authRepo.adminResetPassword(targetId, newPassword);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout cleanly
  void logout() async {
    _currentUser = null;
    ApiClient.setToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('auth_user');
    } catch (_) {}
    notifyListeners();
  }
}
