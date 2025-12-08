import 'package:maromart/models/Notification/Notification.dart';
import 'package:maromart/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _apiService.get(
        endpoint: '/notifications',
        needAuth: true,
      );

      if (response['notifications'] is List) {
        return (response['notifications'] as List)
            .map((json) => NotificationModel.fromJson(json))
            .toList();
      }
      return [];
    } catch (e) {
      print('Lỗi lấy thông báo: $e');
      throw Exception('Không thể tải thông báo');
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _apiService.put(
        endpoint: '/notifications/$notificationId',
        body: {},
        needAuth: true,
      );
    } catch (e) {
      print('Lỗi markAsRead: $e');
    }
  }
}