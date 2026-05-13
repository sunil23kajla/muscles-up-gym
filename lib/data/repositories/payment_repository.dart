import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final ApiClient _client = ApiClient();

  // Record manual transaction
  Future<PaymentModel> createPayment({
    required String memberId,
    required double amount,
    required String paymentDate,
    String? notes,
  }) async {
    final response = await _client.post(ApiEndpoints.payments, {
      'memberId': memberId,
      'amount': amount,
      'paymentDate': paymentDate,
      'notes': notes,
    });
    return PaymentModel.fromJson(response);
  }

  // Get all transaction histories
  Future<List<PaymentModel>> getAllPayments() async {
    final response = await _client.get(ApiEndpoints.payments);
    if (response is List) {
      return response.map((p) => PaymentModel.fromJson(p)).toList();
    }
    return [];
  }

  // Fetch financial summary metrics and daily breakdown charting array
  Future<Map<String, dynamic>> getFinancialReports() async {
    final response = await _client.get(ApiEndpoints.financialReports);
    return response as Map<String, dynamic>;
  }

  // Retrieve general dashboard stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _client.get(ApiEndpoints.getDashboard);
    return response as Map<String, dynamic>;
  }
}
