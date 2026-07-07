/// Represents a single scheduled class session.
/// Built from the slot objects nested inside the backend's
/// GET /schedule/me/ response: timetable.{DAY}: [ {...}, ... ]
class TimetableSessionModel {
  final String id;
  final String unitCode;
  final String unitTitle;
  final String dayOfWeek; // e.g. "MON"
  final String startTime; // "08:00"
  final String endTime;   // "10:00"
  final String? roomCode;
  final String? lecturerName;
  final String? program;
  final int? yearOfStudy;

  TimetableSessionModel({
    required this.id,
    required this.unitCode,
    required this.unitTitle,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.roomCode,
    this.lecturerName,
    this.program,
    this.yearOfStudy,
  });

  /// Human readable "08:00–10:00" time range, used by the UI.
  String get timeRange => '$startTime - $endTime';

  factory TimetableSessionModel.fromJson(Map<String, dynamic> json, {String? day}) {
    return TimetableSessionModel(
      id: json['id']?.toString() ?? '',
      unitCode: json['unit_code']?.toString() ?? '',
      unitTitle: json['unit_name']?.toString() ?? '',
      dayOfWeek: (day ?? json['day']?.toString() ?? '').toUpperCase(),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      roomCode: json['room']?.toString(),
      lecturerName: json['lecturer']?.toString(),
      program: json['program']?.toString(),
      yearOfStudy: json['year_of_study'] is int ? json['year_of_study'] as int : null,
    );
  }
}
