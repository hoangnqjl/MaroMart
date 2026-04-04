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
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(
        left: 15,
        right: 15,
        bottom: MediaQuery.of(context).padding.bottom + 15,
        top: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Các tab bên trái
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                child: Container(
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildNavItem('assets/images/HomeIcon.svg', 0, 'Home'),
                      ),
                      Expanded(
                        child: _buildNavItem('assets/images/ItemIcon.svg', 1, 'Items'),
                      ),
                      Expanded(
                        child: _buildNavItem('assets/images/MessageIcon.svg', 2, 'Message',
                            badgeCount: widget.notificationCount),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Nút ADD bên phải
          _buildAddButton(),
        ],
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                HeroiconsOutline.plus,
                color: AppColors.primaryLight,
                size: 26,
              ),
            ),
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

    // Màu sắc chuyển đổi: Cam nhạt khi chọn, Xám nhạt khi không chọn
    Color currentColor =
        isSelected ? AppColors.primaryLight : const Color(0xFFCCCCCC);

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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  SvgPicture.asset(
                    iconPath,
                    width: 20,
                    height: 20,
                    colorFilter:
                        ColorFilter.mode(currentColor, BlendMode.srcIn),
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
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: currentColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}