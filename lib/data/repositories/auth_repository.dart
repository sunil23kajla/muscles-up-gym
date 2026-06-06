import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client = ApiClient();

  // Handle Login and save global token
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _client.post(ApiEndpoints.login, {
      'email': email,
      'password': password,
    });

    final token = response['token'];
    final user = UserModel.fromJson(response['user']);
    
    // Configure global Bearer authorization token on success
    ApiClient.setToken(token);

    return {
      'token': token,
      'user': user,
    };
  }

  // Handle Staff Registration requests
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String role = 'staff',
  }) async {
    final response = await _client.post(ApiEndpoints.register, {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });

    return {
      'message': response['message'] ?? 'Registration requested successfully.',
      'user': response['user'] != null ? UserModel.fromJson(response['user']) : null,
    };
  }

  // Get list of pending registration approvals (Admin only)
  Future<List<UserModel>> getPendingRequests() async {
    final response = await _client.get(ApiEndpoints.pendingRequests);
    if (response is List) {
      return response.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  // Approve or Reject a user registration (Admin only)
  Future<void> updateRequestStatus(String userId, String status) async {
    await _client.post(ApiEndpoints.updateRequestStatus, {
      'userId': userId,
      'status': status,
    });
  }

  // Change password of current logged-in user (Self)
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _client.post(ApiEndpoints.changePassword, {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    });
  }

  // Update profile details of current user (Self - Name/Email, e.g., to transfer admin account)
  Future<UserModel> updateProfile(String name, String email) async {
    final response = await _client.put(ApiEndpoints.updateProfile, {
      'name': name,
      'email': email,
    });
    return UserModel.fromJson(response['user']);
  }

  // Fetch list of all approved staff members (Admin only)
  Future<List<UserModel>> getStaffList() async {
    final response = await _client.get(ApiEndpoints.staff);
    if (response is List) {
      return response.map((u) => UserModel.fromJson(u)).toList();
    }
    return [];
  }

  // Delete a staff member from system (Admin only)
  Future<void> deleteStaff(String staffId) async {
    await _client.delete('${ApiEndpoints.staff}/$staffId');
  }

  // Admin manually overrides and resets password for a Staff user (Admin only)
  Future<void> adminResetPassword(String targetId, String newPassword) async {
    await _client.post(ApiEndpoints.adminResetPassword, {
      'targetId': targetId,
      'newPassword': newPassword,
    });
  }
}
