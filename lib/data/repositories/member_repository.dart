import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/member_model.dart';

class MemberRepository {
  final ApiClient _client = ApiClient();

  // Get active directory index with searching/filtering options
  Future<List<MemberModel>> getMembers({String? status, String? search}) async {
    final Map<String, String> queryParams = {};
    if (status != null) queryParams['status'] = status;
    if (search != null) queryParams['search'] = search;

    final response = await _client.get(ApiEndpoints.members, queryParams: queryParams);
    if (response is List) {
      return response.map((m) => MemberModel.fromJson(m)).toList();
    }
    return [];
  }

  // Get specific member details (includes attendance, payments, and workout plans)
  Future<MemberModel> getMemberById(String id) async {
    final response = await _client.get('${ApiEndpoints.members}/$id');
    return MemberModel.fromJson(response);
  }

  // Create new member record
  Future<MemberModel> createMember(Map<String, dynamic> data) async {
    final response = await _client.post(ApiEndpoints.members, data);
    return MemberModel.fromJson(response);
  }

  // Update existing member record
  Future<MemberModel> updateMember(String id, Map<String, dynamic> data) async {
    final response = await _client.put('${ApiEndpoints.members}/$id', data);
    return MemberModel.fromJson(response);
  }

  // Delete member from system (Admin only)
  Future<void> deleteMember(String id) async {
    await _client.delete('${ApiEndpoints.members}/$id');
  }

  // Get members with expiration in the next 10 days
  Future<List<MemberModel>> getUpcomingExpiries() async {
    final response = await _client.get(ApiEndpoints.upcomingExpiries);
    if (response is List) {
      return response.map((m) => MemberModel.fromJson(m)).toList();
    }
    return [];
  }

  // Get expired members list
  Future<List<MemberModel>> getExpiredMembers() async {
    final response = await _client.get(ApiEndpoints.expiredMembers);
    if (response is List) {
      return response.map((m) => MemberModel.fromJson(m)).toList();
    }
    return [];
  }
}
