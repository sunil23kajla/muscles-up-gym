class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'staff'
  final String status; // 'pending', 'approved', 'rejected'

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'staff',
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'status': status,
    };
  }

  bool get isAdmin => role == 'admin';
  bool get isApproved => status == 'approved';
}
