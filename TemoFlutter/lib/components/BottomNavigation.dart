import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'dart:ui';
import 'package:temo/Colors/AppColors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class BottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final int notificationCount;
  final VoidCallback onAddPressed;

  const BottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.notificationCount,
    required this.onAddPressed,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  int? _tappedIndex;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          // Chiều cao cố định 60 + phần padding dưới của iPhone (nếu có)
          height: 60 + MediaQuery.of(context).padding.bottom,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: const Border(
              top: BorderSide(
                color: Colors.white,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              // 2 Tab bên trái
              Expanded(
                child: _buildNavItem('assets/images/HomeIcon.svg', 0, 'Home'),
              ),
              Expanded(
                child: _buildNavItem('assets/images/ItemIcon.svg', 1, 'Items'),
              ),

              // Nút ADD nằm chính giữa tuyệt đối
              _buildAddButton(),

              // 2 Tab bên phải
              Expanded(
                child: _buildNavItem(
                    'assets/images/MessageIcon.svg',
                    2,
                    'Message',
                    badgeCount: widget.notificationCount
                ),
              ),
              Expanded(
                child: _buildNavItem('assets/images/ProfileIcon.svg', 3, 'Profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTapDown: (_) => setState(() => _tappedIndex = -1),
      onTapUp: (_) {
        setState(() => _tappedIndex = null);
        widget.onAddPressed();
      },
      onTapCancel: () => setState(() => _tappedIndex = null),
      child: AnimatedScale(
        scale: _tappedIndex == -1 ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          width: 44,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            HeroiconsOutline.plus,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      String iconPath,
      int index,
      String label, {
        int badgeCount = 0,
      }) {
    bool isSelected = widget.selectedIndex == index;
    bool isTapped = _tappedIndex == index;

    // Màu sắc chuyển đổi: Cam nhạt khi chọn, Xám khi không chọn
    Color currentColor = isSelected ? AppColors.primaryLight : Colors.grey;

    return GestureDetector(
      onTapDown: (_) => setState(() => _tappedIndex = index),
      onTapUp: (_) {
        setState(() => _tappedIndex = null);
        widget.onTabSelected(index);
      },
      onTapCancel: () => setState(() => _tappedIndex = null),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isTapped ? 0.85 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(
                      currentColor,
                      BlendMode.srcIn
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: currentColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontFamily: 'Roboto', // Roboto cho thanh điều hướng
              ),
            ),
          ],
        ),
      ),
    );
  }
}