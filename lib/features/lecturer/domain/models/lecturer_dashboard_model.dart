/// A single teaching session, as returned inside `timetable` (grouped by
/// day) or `today_sessions` (flat, today only, with a `status`) from
/// GET /api/v1/auth/lecturer/profile/.
class LecturerSessionModel {
  final String id;
  final String unitId;
  final String unitCode;
  final String unitName;
  final String day;
  final String startTime; // "HH:mm"
  final String endTime; // "HH:mm"
  final String room;
  final String program;
  final int studentCount;
  final String? status; // "now" | "upcoming" | "completed" — only set for today's sessions

  LecturerSessionModel({
    required this.id,
    required this.unitId,
    required this.unitCode,
    required this.unitName,
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.room,
    required this.program,
    required this.studentCount,
    this.status,
  });

  String get timeRange => '$startTime - $endTime';

  factory LecturerSessionModel.fromJson(Map<String, dynamic> json) {
    return LecturerSessionModel(
      id: json['id']?.toString() ?? '',
      unitId: json['unit_id']?.toString() ?? '',
      unitCode: json['unit_code']?.toString() ?? '',
      unitName: json['unit_name']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      room: json['room']?.toString() ?? 'TBA',
      program: json['program']?.toString() ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString(),
    );
  }
}

/// A unit the lecturer teaches — used to populate the Send Notification
/// screen's unit dropdown (needs the actual id, not just the display code).
class LecturerUnitModel {
  final String id;
  final String code;
  final String name;

  LecturerUnitModel({required this.id, required this.code, required this.name});

  factory LecturerUnitModel.fromJson(Map<String, dynamic> json) {
    return LecturerUnitModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  @override
  String toString() => code;
}

class LecturerSummaryModel {
  final int unitsCount;
  final int weeklySessions;
  final int totalStudents;
  final int completedToday;
  final int remainingToday;

  LecturerSummaryModel({
    required this.unitsCount,
    required this.weeklySessions,
    required this.totalStudents,
    required this.completedToday,
    required this.remainingToday,
  });

  factory LecturerSummaryModel.fromJson(Map<String, dynamic> json) {
    return LecturerSummaryModel(
      unitsCount: (json['units_count'] as num?)?.toInt() ?? 0,
      weeklySessions: (json['weekly_sessions'] as num?)?.toInt() ?? 0,
      totalStudents: (json['total_students'] as num?)?.toInt() ?? 0,
      completedToday: (json['completed_today'] as num?)?.toInt() ?? 0,
      remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
    );
  }
}

class LecturerInfoModel {
  final String staffId;
  final String department;
  final String rank;

  LecturerInfoModel({required this.staffId, required this.department, required this.rank});

  factory LecturerInfoModel.fromJson(Map<String, dynamic> json) {
    return LecturerInfoModel(
      staffId: json['staff_id']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      rank: json['rank']?.toString() ?? '',
    );
  }
}

/// A room option for the venue-change picker on Send Notification.
class RoomModel {
  final String id;
  final String code;
  final String name;
  final int capacity;

  RoomModel({required this.id, required this.code, required this.name, required this.capacity});

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    );
  }

  String get label => '$code (capacity $capacity)';

  @override
  String toString() => label;
}

/// Full dashboard payload — one call feeds Home, Schedule and Profile.
class LecturerDashboardModel {
  final LecturerInfoModel? lecturer;
  final String? currentTerm;
  final String today; // "MON".."SAT"
  final List<String> allocatedUnits; // display codes, e.g. for the Schedule screen chips
  final List<LecturerUnitModel> units; // id+code+name, for the notification form
  final LecturerSummaryModel summary;
  final Map<String, List<LecturerSessionModel>> timetable; // day code -> sessions
  final List<LecturerSessionModel> todaySessions;

  LecturerDashboardModel({
    required this.lecturer,
    required this.currentTerm,
    required this.today,
    required this.allocatedUnits,
    required this.units,
    required this.summary,
    required this.timetable,
    required this.todaySessions,
  });

  factory LecturerDashboardModel.fromJson(Map<String, dynamic> json) {
    final timetableJson = (json['timetable'] as Map?)?.cast<String, dynamic>() ?? {};
    return LecturerDashboardModel(
      lecturer: json['lecturer'] != null
          ? LecturerInfoModel.fromJson(json['lecturer'] as Map<String, dynamic>)
          : null,
      currentTerm: json['current_term']?.toString(),
      today: json['today']?.toString() ?? 'MON',
      allocatedUnits: (json['allocated_units'] as List? ?? []).map((e) => e.toString()).toList(),
      units: (json['units'] as List? ?? [])
          .map((e) => LecturerUnitModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: LecturerSummaryModel.fromJson((json['summary'] as Map?)?.cast<String, dynamic>() ?? {}),
      timetable: timetableJson.map((day, sessions) => MapEntry(
            day,
            (sessions as List)
                .map((s) => LecturerSessionModel.fromJson(s as Map<String, dynamic>))
                .toList(),
          )),
      todaySessions: (json['today_sessions'] as List? ?? [])
          .map((e) => LecturerSessionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
