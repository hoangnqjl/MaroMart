import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';

class BottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabSelected;
  final int notificationCount;
  final VoidCallback? onAddPressed; // New callback for Add button

  const BottomNavigation({
    Key? key,
    required this.selectedIndex,
    required this.onTabSelected,
    this.notificationCount = 0,
    this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, left: 24, right: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 4,vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9), // Higher opacity for contrast
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 5))
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildAnimatedNavItem(
                        icon: HeroiconsOutline.home,
                        label: "Home",
                        index: 0,
                        isSelected: selectedIndex == 0,
                      ),
                      _buildAnimatedNavItem(
                        icon: HeroiconsOutline.bellAlert,
                        label: "Noti",
                        index: 1,
                        isSelected: selectedIndex == 1,
                        badgeCount: notificationCount,
                      ),
                      _buildAnimatedNavItem(
                        icon: HeroiconsOutline.chatBubbleLeftRight, // Updated icon
                        label: "Chat",
                        index: 2,
                        isSelected: selectedIndex == 2,
                      ),
                       _buildAnimatedNavItem(
                        icon: HeroiconsOutline.cube, // Updated to Cube
                        label: "Manager",
                        index: 3,
                        isSelected: selectedIndex == 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),

          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 4))
                ]
              ),
              child: const Icon(Icons.add, color: Colors.black, size: 26),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAnimatedNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutQuart,
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 10 : 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3F4045) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            // Icon Stack with Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black,
                  size: 26,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    ),
                  )
              ],
            ),
            
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 10),
                alignment: Alignment.centerLeft,
                widthFactor: isSelected ? 1.0 : 0.0,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
