import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/error_message.dart';
import '../../data/timetable_repository.dart';
import '../../domain/models/timetable_session_model.dart';

class TimetableState {
  final bool isLoading;
  final String? error;
  final String? termLabel;
  final List<TimetableSessionModel> sessions;
  final List<Map<String, dynamic>> conflicts;
  final int unitCount;
  final bool isFromCache;

  TimetableState({
    this.isLoading = false,
    this.error,
    this.termLabel,
    this.sessions = const [],
    this.conflicts = const [],
    this.unitCount = 0,
    this.isFromCache = false,
  });

  TimetableState copyWith({
    bool? isLoading,
    String? error,
    String? termLabel,
    List<TimetableSessionModel>? sessions,
    List<Map<String, dynamic>>? conflicts,
    int? unitCount,
    bool? isFromCache,
  }) {
    return TimetableState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      termLabel: termLabel ?? this.termLabel,
      sessions: sessions ?? this.sessions,
      conflicts: conflicts ?? this.conflicts,
      unitCount: unitCount ?? this.unitCount,
      isFromCache: isFromCache ?? this.isFromCache,
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
      );
    } catch (e) {
      // If we already have cached sessions, preserve them!
      if (state.sessions.isNotEmpty) {
        state = state.copyWith(isLoading: false, isFromCache: true);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: parseErrorMessage(
            e,
            fallbackMessage:
                'No registered units found. Use Sync to update your schedule.',
          ),
        );
      }
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
        error: parseErrorMessage(
          e,
          fallbackMessage: 'Sync failed. Please try again.',
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
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final timetableProvider = NotifierProvider<TimetableNotifier, TimetableState>(
  TimetableNotifier.new,
);
