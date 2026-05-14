import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/PremiumImage.dart';
import 'package:temo/utils/string_utils.dart';

class ChatTopBar extends StatelessWidget implements PreferredSizeWidget {
  final String name;
  final String? email;
  final String? avatarUrl;

  const ChatTopBar({
    Key? key,
    required this.name,
     this.email,
     this.avatarUrl,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // BACK BUTTON
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(HeroiconsOutline.chevronLeft, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          const SizedBox(width: 12),

          // AVATAR
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade200,
              child: _buildSafeAvatar(avatarUrl ?? '', name),
            ),
          ),

          const SizedBox(width: 12),

          // NAME & EMAIL
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    fontFamily: 'QuickSand',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email ?? 'No email',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // MORE BUTTON
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(HeroiconsOutline.ellipsisVertical, size: 20),
              onPressed: () {
                // TODO: Show options menu
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafeAvatar(String url, String name) {
    final normalizedUrl = StringUtils.normalizeUrl(url);
    if (normalizedUrl.isEmpty || normalizedUrl.contains("default_avatar")) {
      return _buildLetterAvatar(name);
    }
    return PremiumImage(
      imageUrl: normalizedUrl,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      borderRadius: 20,
      errorWidget: _buildLetterAvatar(name),
    );
  }

  Widget _buildLetterAvatar(String name) {
    final initials = StringUtils.getInitials(name);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFB86A).withOpacity(0.1),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFFFFB86A),
          fontSize: 16,
          fontWeight: FontWeight.bold,
          fontFamily: 'QuickSand',
        ),
      ),
    );
  }
}