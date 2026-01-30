import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearch;

  const CommonAppBar({
    super.key,
    required this.title,
    this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false, // Title on Left
      automaticallyImplyLeading: false, // No back button unless manual
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
      actions: [
        // Search Icon
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
          ),
          child: IconButton(
            icon: const Icon(HeroiconsOutline.magnifyingGlass, color: Colors.black, size: 22),
            onPressed: onSearch ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tính năng tìm kiếm đang phát triển")),
              );
            },
          ),
        ),
        // Menu Icon
        Container(
          margin: const EdgeInsets.only(right: 16),
           decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: IconButton(
            icon: const Icon(HeroiconsOutline.bars3BottomRight, color: Colors.white, size: 22),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
