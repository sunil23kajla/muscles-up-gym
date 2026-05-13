class WorkoutPlanModel {
  final int id;
  final String memberId;
  final String planName;
  final String details; // Description or JSON serialization details

  WorkoutPlanModel({
    required this.id,
    required this.memberId,
    required this.planName,
    required this.details,
  });

  factory WorkoutPlanModel.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanModel(
      id: json['id'] ?? 0,
      memberId: json['memberId'] ?? '',
      planName: json['planName'] ?? 'General Fitness',
      details: json['details'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'memberId': memberId,
      'planName': planName,
      'details': details,
    };
  }
}
