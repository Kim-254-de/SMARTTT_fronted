import 'dart:convert';
import 'dart:developer' as dev;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

/// A room the student sits a paper in. `part`/`parts` > 1 when their class
/// is split over several rooms.
class ExamRoom {
  final String room;
  final String classRow;
  final int part;
  final int parts;

  ExamRoom({required this.room, required this.classRow, required this.part, required this.parts});

  factory ExamRoom.fromJson(Map<String, dynamic> json) => ExamRoom(
        room: json['room']?.toString() ?? '',
        classRow: json['class_row']?.toString() ?? '',
        part: json['part'] is int ? json['part'] as int : 1,
        parts: json['parts'] is int ? json['parts'] as int : 1,
      );
}

/// One written paper or practical of a unit the student synced.
class ExamItem {
  final List<String> codes;
  final List<String> units;
  final String title;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isPractical;

  /// "odel" for the separate paper ODEL and part-time students sit.
  final String sitting;
  final String department;
  final List<ExamRoom> rooms;

  /// True when the room shown is the student's own; false when the paper's
  /// rooms are listed because theirs can't be told (check the notice board).
  final bool roomConfirmed;

  ExamItem({
    required this.codes,
    required this.units,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isPractical,
    this.sitting = 'regular',
    this.department = '',
    this.rooms = const [],
    this.roomConfirmed = false,
  });

  String get codesLabel => codes.join(' / ');

  factory ExamItem.fromJson(Map<String, dynamic> json, {required bool isPractical}) => ExamItem(
        codes: (json['codes'] as List? ?? []).map((c) => c.toString()).toList(),
        units: (json['units'] as List? ?? []).map((c) => c.toString()).toList(),
        title: json['title']?.toString() ?? '',
        date: DateTime.parse(json['date'].toString()),
        startTime: json['start_time']?.toString() ?? '',
        endTime: json['end_time']?.toString() ?? '',
        isPractical: isPractical,
        sitting: json['sitting']?.toString() ?? 'regular',
        department: json['department']?.toString() ?? '',
        rooms: (json['rooms'] as List? ?? [])
            .map((r) => ExamRoom.fromJson(r as Map<String, dynamic>))
            .toList(),
        roomConfirmed: json['room_confirmed'] == true,
      );
}

/// Result of GET /schedule/exams/me/: the papers and practicals of the units
/// the student synced, from the current term's latest exam timetable.
class MyExamsResult {
  final String? termLabel;
  final int? version;
  final List<ExamItem> items;
  final String? message;
  final bool isFromCache;

  MyExamsResult({
    this.termLabel,
    this.version,
    required this.items,
    this.message,
    this.isFromCache = false,
  });
}

class ExamsRepository {
  static const String _cachedExamsKey = 'cached_my_exams';

  MyExamsResult _parse(Map<String, dynamic> data, {bool isFromCache = false}) {
    final items = <ExamItem>[
      for (final p in data['papers'] as List? ?? [])
        ExamItem.fromJson(p as Map<String, dynamic>, isPractical: false),
      for (final p in data['practicals'] as List? ?? [])
        ExamItem.fromJson(p as Map<String, dynamic>, isPractical: true),
    ];
    items.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.startTime.compareTo(b.startTime);
    });
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final message = summary['message']?.toString();
    return MyExamsResult(
      termLabel: data['term']?.toString(),
      version: data['version'] is int ? data['version'] as int : null,
      items: items,
      message: (message == null || message.isEmpty) ? null : message,
      isFromCache: isFromCache,
    );
  }

  Future<MyExamsResult?> getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedExamsKey);
      if (raw == null) return null;
      return _parse(jsonDecode(raw) as Map<String, dynamic>, isFromCache: true);
    } catch (e) {
      dev.log('Failed to decode cached exams', error: e, name: 'ExamsRepository');
      return null;
    }
  }

  /// GET /schedule/exams/me/. Offline, falls back to the last copy fetched.
  Future<MyExamsResult> fetchMyExams() async {
    try {
      final response = await apiClient.dio.get('schedule/exams/me/');
      final data = response.data as Map<String, dynamic>;
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedExamsKey, jsonEncode(data));
      } catch (cacheErr) {
        dev.log('Error caching exams', error: cacheErr, name: 'ExamsRepository');
      }
      return _parse(data);
    } catch (e, stack) {
      dev.log('Network error fetching exams, checking local cache...', error: e, stackTrace: stack, name: 'ExamsRepository');
      final cached = await getCached();
      if (cached != null) return cached;
      rethrow;
    }
  }
}
