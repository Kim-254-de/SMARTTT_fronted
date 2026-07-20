class AcademicTermModel {
  final String id;
  final String academicYear;
  final int semester;
  final String startDate;
  final String endDate;
  final bool isCurrent;

  AcademicTermModel({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.startDate,
    required this.endDate,
    required this.isCurrent,
  });

  factory AcademicTermModel.fromJson(Map<String, dynamic> json) {
    return AcademicTermModel(
      id: json['id'].toString(),
      academicYear: json['academic_year'],
      semester: json['semester'],
      startDate: json['start_date'],
      endDate: json['end_date'],
      isCurrent: json['is_current'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'academic_year': academicYear,
      'semester': semester,
      'start_date': startDate,
      'end_date': endDate,
      'is_current': isCurrent,
    };
  }
}
