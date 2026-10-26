/// The exam timetable as SMARTTT serves it:
///   GET /exams/my/          a student's papers, each with their own room
///   GET /exams/my-duties/   a lecturer's papers as examiner, and invigilation duties
/// See apps/schedule/exam_views.py in SMARTTT_BACKEND.
library;

/// The current term, with whether it's in exam mode.
class ExamTerm {
  final String id;
  final String academicYear;
  final int semester;

  /// 'teaching' or 'exams'.
  final String mode;

  /// When the Director scheduled the switch to exams, if they did.
  final DateTime? examSwitchAt;
  final DateTime? switchedAt;

  const ExamTerm({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.mode,
    this.examSwitchAt,
    this.switchedAt,
  });

  bool get inExamMode => mode == 'exams';

  factory ExamTerm.fromJson(Map<String, dynamic> json) {
    return ExamTerm(
      id: json['id']?.toString() ?? '',
      academicYear: json['academic_year']?.toString() ?? '',
      semester: json['semester'] is int ? json['semester'] as int : int.tryParse('${json['semester']}') ?? 0,
      mode: json['mode']?.toString() ?? 'teaching',
      examSwitchAt: _instant(json['exam_switch_at']),
      switchedAt: _instant(json['switched_at']),
    );
  }
}

/// One paper: when it is and, for a student, the room they sit it in.
class ExamPaper {
  final String key;

  /// "COSC 130/COSC 131" for a paper shared by several units.
  final String codes;
  final String title;
  final DateTime date;
  final String startTime; // "08:30"
  final String endTime; // "10:30"
  final String? room;
  final String? building;

  const ExamPaper({
    required this.key,
    required this.codes,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.room,
    this.building,
  });

  String get timeRange => '$startTime - $endTime';

  /// When the paper starts, on the device's clock (campus time).
  DateTime get startsAt => _at(date, startTime);
  DateTime get endsAt => _at(date, endTime);

  factory ExamPaper.fromJson(Map<String, dynamic> json) {
    final unitCodes = (json['unit_codes'] as List?)?.map((c) => c.toString()).toList() ?? const <String>[];
    return ExamPaper(
      key: json['key']?.toString() ?? '',
      // ODEL and part-time classes sit papers of their own.
      codes: (json['codes']?.toString() ?? unitCodes.join('/')) + (json['sitting'] == 'odel' ? ' (ODEL)' : ''),
      title: json['title']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      room: _text(json['room']),
      building: _text(json['building']),
    );
  }
}

/// An invigilation duty. The main invigilator sits in the biggest room and
/// collects the scripts from [collectFrom]; an extra one minds their own room.
class ExamDuty {
  final ExamPaper paper;

  /// 'main' or 'extra'.
  final String role;
  final int students;
  final List<String> collectFrom;

  const ExamDuty({required this.paper, required this.role, required this.students, this.collectFrom = const []});

  bool get isMain => role == 'main';

  factory ExamDuty.fromJson(Map<String, dynamic> json) {
    return ExamDuty(
      paper: ExamPaper.fromJson(json),
      role: json['role']?.toString() ?? 'extra',
      students: json['students'] is int ? json['students'] as int : 0,
      collectFrom: (json['collect_from'] as List?)?.map((r) => r.toString()).toList() ?? const [],
    );
  }
}

/// A practical, set by the department rather than the Generator.
class ExamPractical {
  final String codes;
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;

  const ExamPractical({
    required this.codes,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  String get timeRange => '$startTime - $endTime';

  factory ExamPractical.fromJson(Map<String, dynamic> json) {
    return ExamPractical(
      codes: (json['unit_codes'] as List?)?.map((c) => c.toString()).join('/') ?? '',
      title: json['title']?.toString() ?? '',
      date: DateTime.parse(json['date'].toString()),
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
    );
  }
}

class StudentExams {
  final ExamTerm? term;

  /// The exam timetable's version; null when none is published yet.
  final int? version;
  final List<ExamPaper> papers;
  final List<ExamPractical> practicals;

  const StudentExams({this.term, this.version, this.papers = const [], this.practicals = const []});

  bool get published => version != null;

  factory StudentExams.fromJson(Map<String, dynamic> json) {
    return StudentExams(
      term: json['term'] is Map ? ExamTerm.fromJson(Map<String, dynamic>.from(json['term'] as Map)) : null,
      version: json['version'] is int ? json['version'] as int : null,
      papers: _list(json['papers'], ExamPaper.fromJson),
      practicals: _list(json['practicals'], ExamPractical.fromJson),
    );
  }
}

class LecturerExams {
  final ExamTerm? term;
  final int? version;

  /// Papers the lecturer set (examiner).
  final List<ExamPaper> examiner;
  final List<ExamDuty> duties;

  const LecturerExams({this.term, this.version, this.examiner = const [], this.duties = const []});

  bool get published => version != null;

  factory LecturerExams.fromJson(Map<String, dynamic> json) {
    return LecturerExams(
      term: json['term'] is Map ? ExamTerm.fromJson(Map<String, dynamic>.from(json['term'] as Map)) : null,
      version: json['version'] is int ? json['version'] as int : null,
      examiner: _list(json['examiner'], ExamPaper.fromJson),
      duties: _list(json['duties'], ExamDuty.fromJson),
    );
  }
}

/// Groups items by calendar day, earliest first, keeping their order within a day.
Map<DateTime, List<T>> byDay<T>(List<T> items, DateTime Function(T) dateOf) {
  final out = <DateTime, List<T>>{};
  for (final item in items) {
    final d = dateOf(item);
    out.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(item);
  }
  final keys = out.keys.toList()..sort();
  return {for (final k in keys) k: out[k]!};
}

const _weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Monday 23 Nov".
String examDayLabel(DateTime d) => '${_weekdays[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

List<T> _list<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return <T>[];
  return raw.whereType<Map>().map((m) => parse(Map<String, dynamic>.from(m))).toList();
}

String? _text(dynamic v) {
  final s = v?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

DateTime? _instant(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

DateTime _at(DateTime date, String hhmm) {
  final parts = hhmm.split(':');
  final h = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 0 : 0;
  final m = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, h, m);
}
