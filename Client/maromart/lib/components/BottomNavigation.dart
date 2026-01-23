import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class BottomNavigation extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(HeroiconsSolid.home, HeroiconsOutline.home, 0),

          _buildNavItem(HeroiconsSolid.chatBubbleOvalLeft, HeroiconsOutline.chatBubbleOvalLeft, 2),

          GestureDetector(
            onTap: onAddPressed,
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                shape: BoxShape.circle,
              ),
              child: const Icon(HeroiconsOutline.plus, color: Colors.white, size: 20),
            ),
          ),

          _buildNavItem(HeroiconsSolid.bell, HeroiconsOutline.bell, 1, badgeCount: notificationCount),

          _buildNavItem(HeroiconsSolid.cube, HeroiconsOutline.cube, 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData solidIcon, IconData outlineIcon, int index, {int badgeCount = 0}) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isSelected ? solidIcon : outlineIcon,
              color: Colors.black,
              size: 26,
            ),
            if (badgeCount > 0)
              Positioned(
                top: 15,
                right: 15,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}