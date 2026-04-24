import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';

import 'package:temo/screens/Common/BugReportScreen.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onSearch;
  final bool showBackButton;

  final List<Widget>? actions;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.onSearch,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false, // Title on Left
      automaticallyImplyLeading: false, // No default back button
      leading: showBackButton 
        ? IconButton(
            icon: const Icon(HeroiconsOutline.arrowLeft, color: Colors.black, size: 24),
            onPressed: () => Navigator.of(context).pop(),
          )
        : null,
      title: Text(
        title,
        style: GoogleFonts.roboto(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.black,
        ),
      ),
      actions: actions ?? [
        // Search Icon
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[100],
          ),
          child: IconButton(
            icon: const Icon(HeroiconsOutline.magnifyingGlass, color: Colors.black, size: 20),
            onPressed: onSearch ?? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tính năng tìm kiếm đang phát triển")),
              );
            },
          ),
        ),
        // 3-Dot Menu
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.1),
              ),
              child: const Icon(HeroiconsOutline.ellipsisVertical, color: Colors.black, size: 22),
            ),
            offset: const Offset(0, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onSelected: (value) {
              if (value == 'bug') {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const BugReportScreen()));
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'bug',
                child: Row(
                  children: [
                    const Icon(HeroiconsOutline.exclamationTriangle, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Text("Báo cáo lỗi", style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'feedback',
                child: Row(
                  children: [
                    const Icon(HeroiconsOutline.chatBubbleLeftRight, color: Colors.blue, size: 20),
                    const SizedBox(width: 12),
                    Text("Góp ý", style: GoogleFonts.roboto(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
