import 'dart:developer' as dev;
import '../../../core/network/api_client.dart';
import '../domain/models/academic_term_model.dart';
import '../domain/models/timetable_session_model.dart';

const List<String> _dayKeys = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];

/// Result of GET /schedule/me/ — already personalised and grouped server-side.
class PersonalScheduleResult {
  final String? termLabel;
  final List<TimetableSessionModel> sessions;
  final List<Map<String, dynamic>> conflicts;
  final int unitCount;
  final String? message;

  PersonalScheduleResult({
    this.termLabel,
    required this.sessions,
    required this.conflicts,
    required this.unitCount,
    this.message,
  });
}

class TimetableRepository {
  /// GET /timetable/terms/ — used to show available terms (e.g. for a term picker).
  Future<List<AcademicTermModel>> fetchTerms() async {
    try {
      final response = await apiClient.dio.get('timetable/terms/');
      final dynamic data = response.data;
      final List<dynamic> results = data is Map && data['results'] is List
          ? data['results'] as List
          : (data is List ? data : []);
      return results
          .map((json) => AcademicTermModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stack) {
      dev.log('Error fetching terms', error: e, stackTrace: stack, name: 'TimetableRepository');
      rethrow;
    }
  }

  /// GET /schedule/me/ — the personalised, already-matched-and-grouped timetable.
  /// Backend response shape:
  /// {
  ///   "term": "2025/2026 Sem 1" | null,
  ///   "units": [{id, code, name}, ...],
  ///   "timetable": {"MON": [...], "TUE": [...], ...},
  ///   "conflicts": [...],
  ///   "summary": {"unit_count": n, "session_count": n, "has_conflicts": bool, "message"?: str}
  /// }
  Future<PersonalScheduleResult> fetchMySchedule() async {
    try {
      dev.log('Fetching personalised schedule...', name: 'TimetableRepository');
      final response = await apiClient.dio.get('schedule/me/');
      final data = response.data as Map<String, dynamic>;

      final timetable = data['timetable'] as Map<String, dynamic>? ?? {};
      final sessions = <TimetableSessionModel>[];
      for (final day in _dayKeys) {
        final daySlots = timetable[day];
        if (daySlots is List) {
          for (final slot in daySlots) {
            sessions.add(
              TimetableSessionModel.fromJson(slot as Map<String, dynamic>, day: day),
            );
          }
        }
      }

      final summary = data['summary'] as Map<String, dynamic>? ?? {};
      final conflictsRaw = data['conflicts'] as List? ?? [];

      return PersonalScheduleResult(
        termLabel: data['term']?.toString(),
        sessions: sessions,
        conflicts: conflictsRaw.cast<Map<String, dynamic>>(),
        unitCount: summary['unit_count'] is int ? summary['unit_count'] as int : 0,
        message: summary['message']?.toString(),
      );
    } catch (e, stack) {
      dev.log('Error fetching personalised schedule', error: e, stackTrace: stack, name: 'TimetableRepository');
      rethrow;
    }
  }

  /// POST /courses/sync/portal/ — student provides portal credentials ONCE.
  /// Backend scrapes the portal, matches units, saves StudentUnit records,
  /// and discards the password immediately. Nothing is persisted client-side
  /// beyond what the user typed for this single request.
  Future<Map<String, dynamic>> syncFromPortal({
    required String portalUsername,
    required String portalPassword,
  }) async {
    try {
      dev.log('Syncing units from portal...', name: 'TimetableRepository');
      final response = await apiClient.dio.post(
        'courses/sync/portal/',
        data: {
          'portal_username': portalUsername,
          'portal_password': portalPassword,
        },
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e, stack) {
      dev.log('Error syncing from portal', error: e, stackTrace: stack, name: 'TimetableRepository');
      rethrow;
    }
  }

  /// POST /courses/sync/manual/ — fallback when portal scraping isn't available.
  Future<Map<String, dynamic>> syncManually(List<String> unitCodes) async {
    try {
      dev.log('Syncing registered units manually: $unitCodes', name: 'TimetableRepository');
      final response = await apiClient.dio.post(
        'courses/sync/manual/',
        data: {'unit_codes': unitCodes},
      );
      return Map<String, dynamic>.from(response.data as Map);
    } catch (e, stack) {
      dev.log('Error syncing units manually', error: e, stackTrace: stack, name: 'TimetableRepository');
      rethrow;
    }
  }

  /// GET /courses/my-courses/ — list of the student's currently synced units.
  Future<List<Map<String, dynamic>>> fetchMyCourses() async {
    try {
      final response = await apiClient.dio.get('courses/my-courses/');
      final dynamic data = response.data;
      final List<dynamic> results = data is Map && data['results'] is List
          ? data['results'] as List
          : (data is List ? data : []);
      return results.cast<Map<String, dynamic>>();
    } catch (e, stack) {
      dev.log('Error fetching my courses', error: e, stackTrace: stack, name: 'TimetableRepository');
      rethrow;
    }
  }
}
