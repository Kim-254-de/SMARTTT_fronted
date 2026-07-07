class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String? universityId;
  final String role;
  final String? phoneNumber;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.universityId,
    this.role = 'student',
    this.phoneNumber,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      universityId: json['university_id']?.toString(),
      role: json['role']?.toString() ?? 'student',
      phoneNumber: json['phone_number']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'university_id': universityId,
      'role': role,
      'phone_number': phoneNumber,
    };
  }
}
