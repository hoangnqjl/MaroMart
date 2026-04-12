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
          // 1. Cụm các tab chức năng (Co rút động)
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    offset: const Offset(0, 10),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
                  child: Container(
                    height: 58,
                    padding: const EdgeInsets.symmetric(horizontal: 4), 
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                    ),
                    child: Row(
                      children: [
                        _buildNavItem('assets/images/HomeIcon.svg', 0, 'Home'),
                        const SizedBox(width: 4),
                        _buildNavItem('assets/images/ItemIcon.svg', 1, 'Items', solidIconPath: 'assets/images/ItemIconSolid.png'),
                        const SizedBox(width: 4),
                        _buildNavItem('assets/images/MessageIcon.svg', 2, 'Message',
                            solidIconPath: 'assets/images/MessageIconSolid.png',
                            badgeCount: widget.notificationCount),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 2. Nút ADD bên phải
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
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                offset: const Offset(0, 10),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
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
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Thanh ngang
                    Container(
                      width: 22,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    // Thanh dọc
                    Container(
                      width: 3.5,
                      height: 22,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
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
    String? solidIconPath,
    int badgeCount = 0,
  }) {
    bool isSelected = widget.selectedIndex == index;
    bool isTapped = _tappedIndex == index;

    // Màu sắc: Kem (#FFF7ED) khi chọn trong bubble cam, Xám đậm (#888888) khi không chọn
    Color currentColor =
        isSelected ? const Color(0xFFFFF7ED) : const Color(0xFF888888);

    return Expanded(
      child: GestureDetector(
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
            // Đã xóa width: 85 để co giãn động
            margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            padding: const EdgeInsets.symmetric(vertical: 4), 
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    isSelected && solidIconPath != null
                        ? Image.asset(
                            solidIconPath,
                            width: 20,
                            height: 20,
                            color: currentColor,
                          )
                        : (isSelected && index == 0) // Case cho Home (Solid)
                            ? Icon(
                                HeroiconsSolid.home,
                                size: 22, // Size icon Solid thường to hơn
                                color: currentColor,
                              )
                            : SvgPicture.asset(
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
      ),
    );
  }
}