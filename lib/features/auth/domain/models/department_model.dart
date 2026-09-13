class DepartmentModel {
  final String id;
  final String name;
  final String code;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
    );
  }

  @override
  String toString() => name;
}