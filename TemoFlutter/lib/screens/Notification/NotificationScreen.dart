import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:intl/intl.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/Notification/Notification.dart';
import 'package:temo/services/notification_service.dart';
import 'package:temo/services/socket_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/screens/Notification/NotificationDetailScreen.dart';
import 'package:temo/screens/Message/ChatScreen.dart';
import 'package:temo/models/User/ChatPartner.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/PremiumTabSwitcher.dart';
import 'package:google_fonts/google_fonts.dart';


import '../Order/OrderListScreen.dart';

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

    if (noti.relatedUrl != null && noti.relatedUrl!.isNotEmpty) {
      if (noti.relatedUrl!.contains('/order-list')) {
        int initialTab = noti.relatedUrl!.contains('tab=buy') ? 0 : 1;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderListScreen(initialTab: initialTab),
          ),
        );
        return;
      }
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

      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 130), // Space for floating header
          Expanded(
            child: _isLoading
                ? Center(child: ModernLoader(color: primaryThemeColor))
                : _displayNotifications.isEmpty
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(HeroiconsOutline.bellSlash, size: 64, color: Colors.grey[200]),
                      const SizedBox(height: 16),
                      Text(
                        "Không có thông báo nào",
                        style: GoogleFonts.roboto(
                          color: Colors.grey[400],
                          fontSize: 15,
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                )
                : _buildGroupedList(),
          ),
            ],
          ),
          Positioned(
            top: 0, left: 0, right: 0,
            child: FloatingHeader(
              title: "Thông báo",
              actions: [
                _buildHeaderMenu(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderMenu() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 70),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      elevation: 8,
      icon: Container(
        width: 44, height: 44,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
          ],
        ),
        child: const Icon(HeroiconsOutline.ellipsisHorizontal, color: Colors.black, size: 22),
      ),
      color: Colors.white,
      surfaceTintColor: Colors.white,
      onSelected: (value) {
        if (value == 'delete_all') {
          _deleteAll();
        } else if (value.startsWith('filter_')) {
          final idx = int.parse(value.split('_')[1]);
          setState(() => _selectedTab = idx);
        } else if (value == 'mark_read') {
          // Logic for marking all as read
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'filter_0',
          height: 56,
          child: _buildPopupItem(
            icon: HeroiconsOutline.rectangleGroup,
            label: "Tất cả",
            color: Colors.green,
            isSelected: _selectedTab == 0,
          ),
        ),
        PopupMenuItem(
          value: 'filter_1',
          height: 56,
          child: _buildPopupItem(
            icon: HeroiconsOutline.bell,
            label: "Chưa đọc",
            color: AppColors.primary,
            isSelected: _selectedTab == 1,
          ),
        ),
        PopupMenuItem(
          value: 'filter_2',
          height: 56,
          child: _buildPopupItem(
            icon: HeroiconsOutline.checkCircle,
            label: "Đã đọc",
            color: Colors.blue,
            isSelected: _selectedTab == 2,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'mark_read',
          height: 56,
          child: _buildPopupItem(
            icon: HeroiconsOutline.checkCircle,
            label: "Đánh dấu tất cả đã đọc",
            color: Colors.grey,
          ),
        ),
        PopupMenuItem(
          value: 'delete_all',
          height: 56,
          child: _buildPopupItem(
            icon: HeroiconsOutline.trash,
            label: "Xóa toàn bộ thông báo",
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  Widget _buildPopupItem({
    required IconData icon,
    required String label,
    required Color color,
    bool isSelected = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: color, width: 2) : null,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
              color: isSelected ? color : const Color(0xFF374151),
            ),
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
          bool showHeader = false; // Luôn ẩn tiêu đề ngày theo yêu cầu của người dùng

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
    final diff = DateTime.now().difference(item.createdAt).abs();
    final timeStr = diff.inMinutes < 60
        ? "${diff.inMinutes} phút trước"
        : diff.inHours < 24
            ? "${diff.inHours} giờ trước"
            : DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt);

    return GestureDetector(
      onTap: () => _onTapNotification(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: const Color(0x26000000), width: 0.4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: style.bgColor,
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: TextStyle(color: Colors.grey[500], fontSize: 10),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8),
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