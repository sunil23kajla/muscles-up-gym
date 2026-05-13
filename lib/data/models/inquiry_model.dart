class InquiryModel {
  final String id;
  final String name;
  final String phone;
  final String packageName;
  final String? message;
  final String status; // 'pending', 'contacted', 'joined'
  final String createdAt;

  InquiryModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.packageName,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory InquiryModel.fromJson(Map<String, dynamic> json) {
    return InquiryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      packageName: json['packageName'] ?? '',
      message: json['message'],
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'packageName': packageName,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
