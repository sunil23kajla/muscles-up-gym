import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/attendance_model.dart';
import '../models/workout_plan_model.dart';

class AttendanceRepository {
  final ApiClient _client = ApiClient();

  // Tick attendance
  Future<void> markAttendance({
    required String memberId,
    required String date,
    required String status, // 'present' or 'absent'
  }) async {
    await _client.post(ApiEndpoints.markAttendance, {
      'memberId': memberId,
      'date': date,
      'status': status,
    });
  }

  // Load roster of today or specific date
  Future<List<AttendanceModel>> getDailyAttendance(String date) async {
    final response = await _client.get(
      ApiEndpoints.dailyAttendance,
      queryParams: {'date': date},
    );
    if (response is List) {
      return response.map((a) => AttendanceModel.fromJson(a)).toList();
    }
    return [];
  }

  // Assign workout program
  Future<WorkoutPlanModel> assignWorkoutPlan({
    required String memberId,
    required String planName,
    required String details,
  }) async {
    final response = await _client.post(ApiEndpoints.workoutPlan, {
      'memberId': memberId,
      'planName': planName,
      'details': details,
    });
    return WorkoutPlanModel.fromJson(response['workout']);
  }

  // Retrieve current workout routine
  Future<WorkoutPlanModel?> getWorkoutPlan(String memberId) async {
    final response = await _client.get('${ApiEndpoints.workoutPlan}/$memberId');
    if (response == null) return null;
    return WorkoutPlanModel.fromJson(response);
  }
}
