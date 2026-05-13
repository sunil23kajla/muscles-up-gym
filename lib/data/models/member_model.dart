class MemberModel {
  final String id;
  final String name;
  final String phone;
  final String? photo; // Base64 representation or path
  final double? height;
  final double? weight;
  final String? bloodGroup;
  final String subscriptionStart; // YYYY-MM-DD
  final String subscriptionEnd;   // YYYY-MM-DD
  final String status;            // 'active', 'expired', 'pending'
  final String plan;              // '1 Month', '3 Months', etc.

  // Nested embedded models parsed during detailed retrieval
  final List<dynamic> payments;
  final List<dynamic> attendance;
  final Map<String, dynamic>? workout;

  MemberModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photo,
    this.height,
    this.weight,
    this.bloodGroup,
    required this.subscriptionStart,
    required this.subscriptionEnd,
    required this.status,
    this.plan = '1 Month',
    this.payments = const [],
    this.attendance = const [],
    this.workout,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    return MemberModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      height: json['height'] != null ? double.tryParse(json['height'].toString()) : null,
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      bloodGroup: json['bloodGroup'],
      subscriptionStart: json['subscriptionStart'] ?? '',
      subscriptionEnd: json['subscriptionEnd'] ?? '',
      status: json['status'] ?? 'pending',
      plan: json['plan'] ?? '1 Month',
      payments: json['payments'] ?? const [],
      attendance: json['attendance'] ?? const [],
      workout: json['workout'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo': photo,
      'height': height,
      'weight': weight,
      'bloodGroup': bloodGroup,
      'subscriptionStart': subscriptionStart,
      'subscriptionEnd': subscriptionEnd,
      'status': status,
      'plan': plan,
      'payments': payments,
      'attendance': attendance,
      'workout': workout,
    };
  }

  // Computed helper property showing remaining duration
  int get daysRemaining {
    try {
      final end = DateTime.parse(subscriptionEnd);
      final today = DateTime.now();
      final cleanToday = DateTime(today.year, today.month, today.day);
      final difference = end.difference(cleanToday).inDays;
      return difference;
    } catch (_) {
      return 0;
    }
  }

  bool get isActive => status == 'active';
  bool get isExpired => status == 'expired';
  bool get isPending => status == 'pending';
  bool get isUrgentExpiry => isActive && daysRemaining >= 0 && daysRemaining <= 10;
}
