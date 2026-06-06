import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String pcHostIp = '192.168.1.22';

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        return 'http://$pcHostIp:5000/api';
      }
    } catch (_) {}
    return 'http://localhost:5000/api';
  }

  // Auth paths
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String pendingRequests = '/auth/pending-requests';
  static const String updateRequestStatus = '/auth/update-status';
  static const String changePassword = '/auth/change-password';
  static const String updateProfile = '/auth/update-profile';
  static const String staff = '/auth/staff';
  static const String adminResetPassword = '/auth/admin-reset-password';

  // Members paths
  static const String members = '/members';
  static const String upcomingExpiries = '/members/expiring';
  static const String expiredMembers = '/members/expired';

  // Financial paths
  static const String payments = '/payments';
  static const String financialReports = '/payments/reports';

  // Core administrative paths
  static const String markAttendance = '/attendance/mark';
  static const String dailyAttendance = '/attendance/daily';
  static const String workoutPlan = '/attendance/workout';
  static const String getDashboard = '/dashboard/stats';

  // Website & Inquiries paths
  static const String websiteSettings = '/website';
  static const String inquiries = '/inquiries';
}
