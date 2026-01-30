import 'package:flutter/material.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Notification/Notification.dart';
import 'package:maromart/services/notification_service.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/screens/Notification/NotificationDetailScreen.dart';
import 'package:maromart/screens/Message/ChatScreen.dart';
import 'package:maromart/models/User/ChatPartner.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:maromart/components/ModernLoader.dart';
import 'package:maromart/components/CommonAppBar.dart';
import 'package:maromart/components/AppDrawer.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService = SocketService();
  final Color primaryThemeColor = AppColors.primary;

  List<NotificationModel> _allNotifications = [];
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _listenToSocket();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _allNotifications = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _listenToSocket() {
    _socketService.onNewNotification = (data) {
      if (data['notification'] != null) {
        final newNoti = NotificationModel.fromJson(data['notification']);
        if (mounted) {
          setState(() {
            _allNotifications.insert(0, newNoti);
          });
        }
      }
    };
  }

  Future<void> _onTapNotification(NotificationModel noti) async {
    if (!noti.isRead) {
      _notificationService.markAsRead(noti.id);
      setState(() {
        final index = _allNotifications.indexWhere((element) => element.id == noti.id);
        if (index != -1) {
          _allNotifications[index] = NotificationModel(
              id: noti.id,
              title: noti.title,
              content: noti.content,
              type: noti.type,
              isRead: true,
              relatedUrl: noti.relatedUrl,
              relatedId: noti.relatedId,
              data: noti.data,
              createdAt: noti.createdAt
          );
        }
      });
    }

    if (noti.type == 'message' || noti.type == 'new_message') {
      try {
        final data = noti.data ?? {};
        final String conversationId = noti.relatedId ?? data['conversationId'] ?? "";

        if (conversationId.isNotEmpty && data.containsKey('sender')) {
          final senderData = data['sender'];
          final partner = ChatPartner(
            userId: senderData['_id'] ?? senderData['id'] ?? "",
            fullName: senderData['fullName'] ?? senderData['name'] ?? "User",
            avatarUrl: senderData['avatarUrl'] ?? senderData['avatar'] ?? "",
            email: senderData['email'],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatScreen(
                conversationId: conversationId,
                partnerUser: partner,
              ),
            ),
          );
          return;
        }
      } catch (e) {}
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailScreen(notification: noti),
      ),
    );
  }

  List<NotificationModel> get _displayNotifications {
    if (_selectedTab == 1) return _allNotifications.where((n) => !n.isRead).toList();
    if (_selectedTab == 2) return _allNotifications.where((n) => n.isRead).toList();
    return _allNotifications;
  }

  void _deleteAll() {
    setState(() {
      _allNotifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(title: "Thông báo"),
      endDrawer: const AppDrawer(),
      body: Column(
        children: [
          // const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.E2Color,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(0, "All"),
                      _buildTabButton(1, "New", hasDot: true),
                      _buildTabButton(2, "Read"),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: _deleteAll,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(
                      color: AppColors.E2Color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(HeroiconsOutline.trash, color: primaryThemeColor, size: 20),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: ModernLoader(color: primaryThemeColor))
                : _displayNotifications.isEmpty
                ? Center(child: Text("No notifications", style: TextStyle(color: Colors.grey[400])))
                : _buildGroupedList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList() {
    final list = _displayNotifications;
    return AnimationLimiter(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final noti = list[index];
          bool showHeader = true;
          if (index > 0) {
            final prevNoti = list[index - 1];
            if (_isSameDay(prevNoti.createdAt, noti.createdAt)) showHeader = false;
          }

          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 8),
                        child: Text(
                          _getDateHeader(noti.createdAt),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryThemeColor),
                        ),
                      ),
                    _buildNotificationItem(noti),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    final style = _getStyleByType(item.type);
    final timeStr = item.createdAt.difference(DateTime.now()).inMinutes.abs() < 60
        ? "${item.createdAt.difference(DateTime.now()).inMinutes.abs()}m ago"
        : DateFormat('HH:mm').format(item.createdAt);

    return GestureDetector(
      onTap: () => _onTapNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: style.bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(style.icon, color: style.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timeStr,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8, height: 8,
                decoration: BoxDecoration(color: primaryThemeColor, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String text, {bool hasDot = false}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryThemeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(50),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (hasDot && !isSelected && _hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 4),
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }

  bool get _hasUnread => _allNotifications.any((n) => !n.isRead);
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return "Today";
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return "Yesterday";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  _NotiStyle _getStyleByType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return _NotiStyle(bgColor: const Color(0xFFF1F8E9), iconColor: const Color(0xFF4CAF50), icon: HeroiconsOutline.check);
      case 'warning':
      case 'product_refusal':
        return _NotiStyle(bgColor: const Color(0xFFFFF1F0), iconColor: const Color(0xFFF44336), icon: HeroiconsOutline.xMark);
      case 'new':
      case 'message':
        return _NotiStyle(bgColor: const Color(0xFFE3F2FD), iconColor: const Color(0xFF2196F3), icon: HeroiconsOutline.chatBubbleLeft);
      default:
        return _NotiStyle(bgColor: const Color(0xFFF5F5F5), iconColor: primaryThemeColor, icon: HeroiconsOutline.bell);
    }
  }
}

class _NotiStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  _NotiStyle({required this.bgColor, required this.iconColor, required this.icon});
}