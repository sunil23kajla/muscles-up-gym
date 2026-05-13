import 'member_model.dart';

class PaymentModel {
  final int id;
  final String memberId;
  final double amount;
  final String paymentDate; // YYYY-MM-DD
  final String? notes;
  final MemberModel? member; // Optional nested member association

  PaymentModel({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.paymentDate,
    this.notes,
    this.member,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      paymentDate: json['paymentDate'] ?? '',
      notes: json['notes'],
      member: json['member'] != null ? MemberModel.fromJson(json['member']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'amount': amount,
      'paymentDate': paymentDate,
      'notes': notes,
    };
  }
}
