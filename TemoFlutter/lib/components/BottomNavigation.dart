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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 60 + MediaQuery.of(context).padding.bottom, // Extend height
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ), // Push content up
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            border: const Border(
              top: BorderSide(
                color: Colors.white,
                width: 0.5,
              ), // Lighter border
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                HeroiconsSolid.home,
                HeroiconsOutline.home,
                0,
                'Trang chủ',
              ),

              _buildNavItem(
                HeroiconsSolid.chatBubbleOvalLeft,
                HeroiconsOutline.chatBubbleOvalLeft,
                2,
                'Tin nhắn',
              ),

              _buildAddButton(),

              _buildNavItem(
                HeroiconsSolid.cube,
                HeroiconsOutline.cube,
                1,
                'Sản phẩm',
              ),

              _buildNavItem(
                HeroiconsOutline.bars3,
                HeroiconsOutline.bars3,
                3,
                'Menu',
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
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
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
    IconData solidIcon,
    IconData outlineIcon,
    int index,
    String label, {
    int badgeCount = 0,
  }) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    isSelected ? solidIcon : outlineIcon,
                    color: isSelected ? AppColors.primary : Colors.black,
                    size: 24,
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
                  color: isSelected ? AppColors.primary : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
