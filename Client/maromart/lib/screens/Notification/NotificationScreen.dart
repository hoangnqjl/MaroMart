import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/Notification/Notification.dart';
import 'package:maromart/services/notification_service.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();
  final SocketService _socketService = SocketService();

  List<NotificationModel> _allNotifications = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: All, 1: New, 2: Read

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
      print("Lỗi tải thông báo: $e");
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
        // Update local state
        final index = _allNotifications.indexWhere((element) => element.id == noti.id);
        if (index != -1) {
          _loadNotifications();
        }
      });
    }
  }

  // LỌC DANH SÁCH THEO TAB
  List<NotificationModel> get _displayNotifications {
    if (_selectedTab == 1) {
      return _allNotifications.where((n) => !n.isRead).toList(); // New
    } else if (_selectedTab == 2) {
      return _allNotifications.where((n) => n.isRead).toList(); // Read
    }
    return _allNotifications; // All
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: const Icon(HeroiconsOutline.trash, color: Colors.black, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _displayNotifications.isEmpty
                  ? Center(child: Text("No notifications", style: TextStyle(color: Colors.grey[400])))
                  : _buildGroupedList(),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET XÂY DỰNG DANH SÁCH NHÓM THEO NGÀY ---
  Widget _buildGroupedList() {
    final list = _displayNotifications;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final noti = list[index];

        bool showHeader = true;
        if (index > 0) {
          final prevNoti = list[index - 1];
          if (_isSameDay(prevNoti.createdAt, noti.createdAt)) {
            showHeader = false;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  _getDateHeader(noti.createdAt),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'QuickSand'),
                ),
              ),
            _buildNotificationItem(noti),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(NotificationModel item) {
    final style = _getStyleByType(item.type);

    final timeStr = item.createdAt.difference(DateTime.now()).inMinutes.abs() < 60
        ? "${item.createdAt.difference(DateTime.now()).inMinutes.abs()} phút trước" // Nếu dưới 1 giờ
        : DateFormat('HH:mm').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: style.bgColor,
        borderRadius: BorderRadius.circular(30),
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
            child: Icon(
              style.icon,
              color: style.iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),

          // Nội dung
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.black87,
                    fontFamily: 'QuickSand',
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  timeStr,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- TAB BUTTON ---
  Widget _buildTabButton(int index, String text, {bool hasDot = false}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.transparent, // Đen khi chọn
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
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

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  String _getDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return "Today";
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) return "Yesterday";
    return DateFormat('dd/MM/yyyy').format(date);
  }

  _NotiStyle _getStyleByType(String type) {
    final safeType = type.toLowerCase();

    switch (safeType) {
      case 'success':
        return _NotiStyle(
            bgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF4CAF50),
            icon: HeroiconsOutline.check
        );

      case 'warning':
      case 'product_refusal':
        return _NotiStyle(
            bgColor: const Color(0xFFFFEBEE),
            iconColor: const Color(0xFFF44336),
            icon: HeroiconsOutline.xMark
        );

      case 'new':
      case 'message':
        return _NotiStyle(
            bgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF2196F3),
            icon: HeroiconsOutline.bell
        );

      case 'info':
      case 'report':
        return _NotiStyle(
            bgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFF9800),
            icon: HeroiconsOutline.exclamationTriangle
        );

      default:
        return _NotiStyle(
            bgColor: const Color(0xFFF5F5F5), // Grey 100
            iconColor: Colors.grey,
            icon: HeroiconsOutline.informationCircle
        );
    }
  }
}

class _NotiStyle {
  final Color bgColor;
  final Color iconColor;
  final IconData icon;
  _NotiStyle({required this.bgColor, required this.iconColor, required this.icon});
}