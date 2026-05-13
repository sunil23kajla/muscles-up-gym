import 'package:flutter/material.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _paymentRepo = PaymentRepository();

  List<PaymentModel> _payments = [];
  Map<String, dynamic> _financialSummary = {
    'today': 0.0,
    'monthly': 0.0,
    'yearly': 0.0,
  };
  List<dynamic> _dailyChartData = [];
  
  // Dashboard overall telemetry metrics
  Map<String, dynamic> _dashboardStats = {
    'members': {
      'total': 0,
      'active': 0,
      'expired': 0,
      'pending': 0,
      'newToday': 0,
    },
    'collections': {
      'today': 0.0,
      'monthly': 0.0,
      'yearly': 0.0,
    },
    'alerts': {
      'upcomingExpirations': 0,
    }
  };

  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  Map<String, dynamic> get financialSummary => _financialSummary;
  List<dynamic> get dailyChartData => _dailyChartData;
  Map<String, dynamic> get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch central Dashboard numbers
  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _dashboardStats = await _paymentRepo.getDashboardStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch complete transactional financial reports
  Future<void> fetchFinancialReports() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _paymentRepo.getFinancialReports();
      _financialSummary = data['summary'];
      _dailyChartData = data['dailyChartData'] ?? [];
      
      // Also load full payment history list
      _payments = await _paymentRepo.getAllPayments();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Record manual transaction
  Future<bool> recordPayment({
    required String memberId,
    required double amount,
    required String paymentDate,
    String? notes,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newPayment = await _paymentRepo.createPayment(
        memberId: memberId,
        amount: amount,
        paymentDate: paymentDate,
        notes: notes,
      );
      
      _payments.insert(0, newPayment); // Prepend to transaction logs instantly
      
      // Refresh summaries locally
      _isLoading = false;
      notifyListeners();
      
      // Fully sync databases and report cards
      await fetchFinancialReports();
      await fetchDashboardStats();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
