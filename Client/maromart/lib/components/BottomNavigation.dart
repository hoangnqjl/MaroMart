import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'dart:ui'; // Required for ImageFilter
import 'package:maromart/Colors/AppColors.dart';

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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 70,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(HeroiconsSolid.home, HeroiconsOutline.home, 0),

              _buildNavItem(HeroiconsSolid.chatBubbleOvalLeft, HeroiconsOutline.chatBubbleOvalLeft, 2),

              _buildAddButton(),

              _buildNavItem(HeroiconsSolid.bell, HeroiconsOutline.bell, 1, badgeCount: widget.notificationCount),

              _buildNavItem(HeroiconsSolid.cube, HeroiconsOutline.cube, 3),
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
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(HeroiconsOutline.plus, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData solidIcon, IconData outlineIcon, int index, {int badgeCount = 0}) {
    bool isSelected = widget.selectedIndex == index;
    bool isTapped = _tappedIndex == index;

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
        child: AnimatedOpacity(
          opacity: isTapped ? 0.6 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: SizedBox(
            width: 60,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  isSelected ? solidIcon : outlineIcon,
                  color: isSelected ? AppColors.primary : Colors.black,
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
        ),
      ),
    );
  }
}
