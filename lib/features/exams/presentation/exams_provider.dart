import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exams_repository.dart';

final examsRepositoryProvider = Provider((ref) => ExamsRepository());

/// The student's exams: re-fetched each time the Exams tab opens or is pulled
/// down, so a unit synced since shows its exam straight away.
final myExamsProvider = FutureProvider.autoDispose<MyExamsResult>(
  (ref) => ref.watch(examsRepositoryProvider).fetchMyExams(),
);
