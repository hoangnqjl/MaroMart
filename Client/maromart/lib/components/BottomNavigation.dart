import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final int notificationCount; // <--- 1. THÊM BIẾN NÀY

  const BottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.notificationCount = 0, // Mặc định là 0
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 50),
      width: MediaQuery.of(context).size.width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black12)
                ),
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: HeroiconsOutline.home,
                      index: 0,
                      isSelected: selectedIndex == 0,
                    ),
                    const SizedBox(width: 8),

                    // --- ICON THÔNG BÁO (Index 1) ---
                    _buildNavItem(
                      icon: HeroiconsOutline.bellAlert,
                      index: 1,
                      isSelected: selectedIndex == 1,
                      badgeCount: notificationCount, // Truyền số lượng vào
                    ),
                    // --------------------------------

                    const SizedBox(width: 8),
                    _buildNavItem(
                      icon: HeroiconsOutline.paperAirplane,
                      index: 2,
                      isSelected: selectedIndex == 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.black12)
                ),
                child: _buildNavItemSearch(
                  icon: HeroiconsOutline.magnifyingGlass,
                  index: 3,
                  isSelected: selectedIndex == 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required bool isSelected,
    int badgeCount = 0, // Tham số badge
  }) {
    return GestureDetector(
      onTap: () {
        onTabSelected(index);
      },
      child: Stack(
        clipBehavior: Clip.none, // Cho phép badge tràn ra ngoài
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black.withOpacity(0.8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.ButtonBlackColor,
              size: 26,
            ),
          ),

          // --- VẼ BADGE ĐỎ NẾU CÓ THÔNG BÁO ---
          if (badgeCount > 0)
            Positioned(
              top: 0,
              right: 0,
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
                  badgeCount > 99 ? '99+' : '$badgeCount',
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
    );
  }

  Widget _buildNavItemSearch({
    required IconData icon,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        onTabSelected(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.black.withOpacity(0.8)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.ButtonBlackColor,
          size: 26,
        ),
      ),
    );
  }
}