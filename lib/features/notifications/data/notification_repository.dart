import '../../../core/network/api_client.dart';
import '../domain/notification_model.dart';
 
class NotificationRepository {
  Future<List<NotificationModel>> fetchMyNotifications() async {
    final response = await apiClient.dio.get('notifications/mine/');
    final dynamic data = response.data;
    final List<dynamic> results = data is Map && data['results'] is List
        ? data['results'] as List
        : (data is List ? data : []);
    return results
        .map((json) => NotificationModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
 
  Future<int> fetchUnreadCount() async {
    final response = await apiClient.dio.get('notifications/unread-count/');
    return (response.data['unread_count'] as int?) ?? 0;
  }
 
  Future<void> markAsRead(String notificationId) async {
    await apiClient.dio.post('notifications/$notificationId/read/');
  }
 
  Future<void> registerFCMToken(String token, String platform) async {
    await apiClient.dio.post('notifications/register-token/', data: {
      'token': token,
      'platform': platform,
    });
  }
}
