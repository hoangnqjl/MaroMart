import 'package:flutter/material.dart';
import 'package:temo/models/Notification/Notification.dart';
import 'package:temo/services/api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();
  
  // Toàn cục để lắng nghe số lượng thông báo chưa đọc
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
      // Giảm số lượng sau khi đọc
      if (unreadCountNotifier.value > 0) {
        unreadCountNotifier.value--;
      }
    } catch (e) {
      print('Lỗi markAsRead: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.put(
        endpoint: '/notifications/mark-all-read',
        body: {},
        needAuth: true,
      );
      unreadCountNotifier.value = 0;
    } catch (e) {
      print('Lỗi markAllAsRead: $e');
      throw Exception('Không thể đánh dấu tất cả đã đọc');
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _apiService.delete(
        endpoint: '/notifications',
        needAuth: true,
      );
      unreadCountNotifier.value = 0;
    } catch (e) {
      print('Lỗi deleteAllNotifications: $e');
      throw Exception('Không thể xóa thông báo');
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      final response = await _apiService.get(
        endpoint: '/notifications/unread-count',
        needAuth: true,
      );
      if (response['count'] != null) {
        unreadCountNotifier.value = response['count'];
      }
    } catch (e) {
      print('Lỗi fetchUnreadCount: $e');
    }
  }
}