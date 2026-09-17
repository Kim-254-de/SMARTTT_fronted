import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/error_message.dart';
import '../../data/timetable_repository.dart';
import '../../domain/models/registered_unit_model.dart';
import '../../domain/models/timetable_session_model.dart';

class TimetableState {
  final bool isLoading;
  final String? error;
  final String? termLabel;
  final List<TimetableSessionModel> sessions;
  final List<Map<String, dynamic>> conflicts;
  final int unitCount;
  final bool isFromCache;
  final List<RegisteredUnitModel> registeredUnits;

  TimetableState({
    this.isLoading = false,
    this.error,
    this.termLabel,
    this.sessions = const [],
    this.conflicts = const [],
    this.unitCount = 0,
    this.isFromCache = false,
    this.registeredUnits = const [],
  });

  /// Units split into elective/practical groups the student hasn't picked
  /// theirs for yet — the schedule shows every group's sessions for these
  /// until they do. Drives the "pick your groups" prompt/banner.
  List<RegisteredUnitModel> get unitsNeedingGroupSelection =>
      registeredUnits.where((u) => u.needsGroupSelection).toList();

  TimetableState copyWith({
    bool? isLoading,
    String? error,
    String? termLabel,
    List<TimetableSessionModel>? sessions,
    List<Map<String, dynamic>>? conflicts,
    int? unitCount,
    bool? isFromCache,
    List<RegisteredUnitModel>? registeredUnits,
  }) {
    return TimetableState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      termLabel: termLabel ?? this.termLabel,
      sessions: sessions ?? this.sessions,
      conflicts: conflicts ?? this.conflicts,
      unitCount: unitCount ?? this.unitCount,
      isFromCache: isFromCache ?? this.isFromCache,
      registeredUnits: registeredUnits ?? this.registeredUnits,
    );
  }
}

final timetableRepositoryProvider = Provider((ref) => TimetableRepository());

class TimetableNotifier extends Notifier<TimetableState> {
  late final TimetableRepository _repository;

  @override
  TimetableState build() {
    _repository = ref.watch(timetableRepositoryProvider);
    // Eagerly restore cached schedule on initialization
    Future.microtask(() async {
      final cached = await _repository.getCachedSchedule();
      if (cached != null && state.sessions.isEmpty) {
        state = TimetableState(
          isLoading: false,
          termLabel: cached.termLabel,
          sessions: cached.sessions,
          conflicts: cached.conflicts,
          unitCount: cached.unitCount,
          isFromCache: true,
        );
      }
    });
    return TimetableState();
  }

  String _formatError(dynamic e, {String? fallback}) {
    if (e is DioException) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return 'Your session has expired. Please log in again.';
      } else if (statusCode == 403) {
        return 'You do not have permission to view this timetable.';
      } else if (statusCode == 404) {
        return fallback ?? 'No schedule found for the current term.';
      } else if (statusCode != null && statusCode >= 500) {
        return 'Server is temporarily unavailable. Please try again shortly.';
      } else if (e.type == DioExceptionType.connectionError ||
                 e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.sendTimeout) {
        return 'Unable to connect. Please check your internet connection.';
      }
    }
    return parseErrorMessage(
      e,
      fallbackMessage: fallback ?? 'Unable to load schedule. Please try again.',
    );
  }

  /// Fetches the student's personalised, already-matched timetable.
  /// Backend handles term resolution, unit matching, and grouping.
  /// Seamlessly displays cached schedule if offline.
  Future<void> fetchMySchedule() async {
    // Only show full loading spinner if we don't have cached sessions
    if (state.sessions.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
      final cached = await _repository.getCachedSchedule();
      if (cached != null) {
        state = TimetableState(
          isLoading: false,
          termLabel: cached.termLabel,
          sessions: cached.sessions,
          conflicts: cached.conflicts,
          unitCount: cached.unitCount,
          isFromCache: true,
        );
      }
    }

    try {
      final result = await _repository.fetchMySchedule();
      state = TimetableState(
        isLoading: false,
        termLabel: result.termLabel,
        sessions: result.sessions,
        conflicts: result.conflicts,
        unitCount: result.unitCount,
        error: result.message,
        isFromCache: result.isFromCache,
        registeredUnits: state.registeredUnits,
      );
    } catch (e) {
      // If we already have cached sessions, preserve them!
      if (state.sessions.isNotEmpty) {
        state = state.copyWith(isLoading: false, isFromCache: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: _formatError(
            e,
            fallback: 'No registered units found. Use Sync to update your schedule.',
          ),
        );
      }
    }

    // Refresh which registered units still need a group pick. Best-effort:
    // a failure here shouldn't take down the schedule the fetch above just
    // loaded successfully.
    try {
      state = state.copyWith(registeredUnits: await _repository.fetchMyCourses());
    } catch (_) {
      // Keep whatever registeredUnits state already had.
    }
  }

  /// Records which elective/practical group the student is in for one
  /// registered unit, then refreshes both the unit list and the schedule so
  /// the newly-narrowed sessions show immediately.
  Future<bool> setUnitGroup({
    required String studentUnitId,
    required String classGroup,
  }) async {
    try {
      final updated = await _repository.setUnitGroup(
        studentUnitId: studentUnitId,
        classGroup: classGroup,
      );
      state = state.copyWith(
        registeredUnits: [
          for (final u in state.registeredUnits)
            if (u.id == updated.id) updated else u,
        ],
      );
      await fetchMySchedule();
      return true;
    } catch (e) {
      state = state.copyWith(error: _formatError(e, fallback: 'Could not save your group. Please try again.'));
      return false;
    }
  }

  /// Syncs the student's registered units from the portal, then refreshes
  /// the schedule. Credentials are sent once and never stored client-side.
  Future<bool> syncFromPortal({
    required String portalUsername,
    required String portalPassword,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.syncFromPortal(
        portalUsername: portalUsername,
        portalPassword: portalPassword,
      );
      await fetchMySchedule();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatError(
          e,
          fallback: 'Sync failed. Please try again.',
        ),
      );
      return false;
    }
  }

  /// Manual fallback if portal scraping is unavailable.
  Future<bool> syncManually(List<String> unitCodes) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.syncManually(unitCodes);
      await fetchMySchedule();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatError(
          e,
          fallback: 'Failed to sync units manually. Please check your unit codes.',
        ),
      );
      return false;
    }
  }
}

final timetableProvider = NotifierProvider<TimetableNotifier, TimetableState>(
  TimetableNotifier.new,
);
