import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/lecturer_repository.dart';
import '../../domain/models/lecturer_dashboard_model.dart';

class LecturerDashboardState {
  final bool isLoading;
  final String? error;
  final LecturerDashboardModel? dashboard;

  LecturerDashboardState({this.isLoading = false, this.error, this.dashboard});

  LecturerDashboardState copyWith({
    bool? isLoading,
    String? error,
    LecturerDashboardModel? dashboard,
    bool clearError = false,
  }) {
    return LecturerDashboardState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      dashboard: dashboard ?? this.dashboard,
    );
  }
}

final lecturerRepositoryProvider = Provider((ref) => LecturerRepository());

class LecturerDashboardNotifier extends Notifier<LecturerDashboardState> {
  late final LecturerRepository _repository;

  @override
  LecturerDashboardState build() {
    _repository = ref.watch(lecturerRepositoryProvider);
    return LecturerDashboardState();
  }

  Future<void> fetchDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dashboard = await _repository.fetchDashboard();
      state = LecturerDashboardState(isLoading: false, dashboard: dashboard);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
    }
  }
}

final lecturerDashboardProvider =
    NotifierProvider<LecturerDashboardNotifier, LecturerDashboardState>(LecturerDashboardNotifier.new);
