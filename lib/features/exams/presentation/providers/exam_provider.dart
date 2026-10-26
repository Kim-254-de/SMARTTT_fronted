import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/exam_repository.dart';
import '../../domain/exam_models.dart';

final examRepositoryProvider = Provider((ref) => ExamRepository());

/// The student's exam timetable. Refresh with `ref.invalidate(studentExamsProvider)`.
final studentExamsProvider = FutureProvider<StudentExams>((ref) {
  return ref.watch(examRepositoryProvider).fetchMyExams();
});

/// The lecturer's exam papers and invigilation duties.
final lecturerExamsProvider = FutureProvider<LecturerExams>((ref) {
  return ref.watch(examRepositoryProvider).fetchMyDuties();
});
