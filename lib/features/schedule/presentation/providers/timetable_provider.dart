import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/timetable_repository.dart';
import '../../domain/models/timetable_session_model.dart';

class TimetableState {
  final bool isLoading;
  final String? error;
  final String? termLabel;
  final List<TimetableSessionModel> sessions;
  final List<Map<String, dynamic>> conflicts;
  final int unitCount;

  TimetableState({
    this.isLoading = false,
    this.error,
    this.termLabel,
    this.sessions = const [],
    this.conflicts = const [],
    this.unitCount = 0,
  });

  TimetableState copyWith({
    bool? isLoading,
    String? error,
    String? termLabel,
    List<TimetableSessionModel>? sessions,
    List<Map<String, dynamic>>? conflicts,
    int? unitCount,
  }) {
    return TimetableState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      termLabel: termLabel ?? this.termLabel,
      sessions: sessions ?? this.sessions,
      conflicts: conflicts ?? this.conflicts,
      unitCount: unitCount ?? this.unitCount,
    );
  }
}

final timetableRepositoryProvider = Provider((ref) => TimetableRepository());

class TimetableNotifier extends Notifier<TimetableState> {
  late final TimetableRepository _repository;

  @override
  TimetableState build() {
    _repository = ref.watch(timetableRepositoryProvider);
    return TimetableState();
  }

  /// Fetches the student's personalised, already-matched timetable.
  /// Backend handles term resolution, unit matching, and grouping —
  /// no client-side term lookup needed.
  Future<void> fetchMySchedule() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _repository.fetchMySchedule();
      state = TimetableState(
        isLoading: false,
        termLabel: result.termLabel,
        sessions: result.sessions,
        conflicts: result.conflicts,
        unitCount: result.unitCount,
        error: result.message,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
      state = state.copyWith(isLoading: false, error: e.toString());
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
