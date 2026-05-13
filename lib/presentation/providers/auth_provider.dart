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

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<UserModel> get pendingRequests => _pendingRequests;

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
