import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/error_message.dart';
import '../domain/exam_models.dart';

class ExamRepository {
  /// GET /exams/my/ — the signed-in student's papers, each with their room.
  Future<StudentExams> fetchMyExams() async {
    try {
      final response = await apiClient.dio.get('exams/my/');
      return StudentExams.fromJson(Map<String, dynamic>.from(response.data as Map));
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /exams/my-duties/ — the signed-in lecturer's papers and invigilation duties.
  Future<LecturerExams> fetchMyDuties() async {
    try {
      final response = await apiClient.dio.get('exams/my-duties/');
      return LecturerExams.fromJson(Map<String, dynamic>.from(response.data as Map));
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(Object e) {
    // A 403 from my/ says who the timetable is for; show SMARTTT's own words.
    if (e is DioException && e.response?.statusCode == 403 && e.response?.data is Map) {
      final detail = (e.response!.data as Map)['detail'];
      if (detail != null) return Exception(detail.toString());
    }
    return Exception(friendlyErrorMessage(e, fallbackMessage: 'Could not load the exam timetable. Pull down to try again.'));
  }
}
