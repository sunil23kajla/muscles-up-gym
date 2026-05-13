class AttendanceModel {
  final String id; // Member ID
  final String name;
  final String phone;
  final String? photo;
  String status; // 'present', 'absent', 'unmarked'

  AttendanceModel({
    required this.id,
    required this.name,
    required this.phone,
    this.photo,
    required this.status,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      photo: json['photo'],
      status: json['status'] ?? 'unmarked',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'photo': photo,
      'status': status,
    };
  }

  bool get isPresent => status == 'present';
  bool get isAbsent => status == 'absent';
  bool get isUnmarked => status == 'unmarked';
}
