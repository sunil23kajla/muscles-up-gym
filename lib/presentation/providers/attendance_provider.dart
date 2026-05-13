import 'package:flutter/material.dart';
import '../../data/models/attendance_model.dart';
import '../../data/models/workout_plan_model.dart';
import '../../data/repositories/attendance_repository.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceRepository _attendanceRepo = AttendanceRepository();

  List<AttendanceModel> _dailyRoster = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<AttendanceModel> get dailyRoster => _dailyRoster;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load attendance register for specific date (YYYY-MM-DD)
  Future<void> fetchDailyRoster(String date) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dailyRoster = await _attendanceRepo.getDailyAttendance(date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record member attendance status
  Future<bool> markAttendance({
    required String memberId,
    required String date,
    required String status,
  }) async {
    try {
      await _attendanceRepo.markAttendance(
        memberId: memberId,
        date: date,
        status: status,
      );

      // Update the local list instantly to ensure high-performance non-flickering toggles!
      final idx = _dailyRoster.indexWhere((m) => m.id == memberId);
      if (idx != -1) {
        _dailyRoster[idx].status = status;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Assign routine program
  Future<WorkoutPlanModel?> assignWorkoutPlan({
    required String memberId,
    required String planName,
    required String details,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plan = await _attendanceRepo.assignWorkoutPlan(
        memberId: memberId,
        planName: planName,
        details: details,
      );
      _isLoading = false;
      notifyListeners();
      return plan;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Retrieve member routine program
  Future<WorkoutPlanModel?> getWorkoutPlan(String memberId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final plan = await _attendanceRepo.getWorkoutPlan(memberId);
      _isLoading = false;
      notifyListeners();
      return plan;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
}
