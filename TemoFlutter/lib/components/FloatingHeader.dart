import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class FloatingHeader extends StatelessWidget {
  final String title;
  final Widget? titleWidget;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool isMenu;
  final AlignmentGeometry contentAlignment;
  final bool hasBackground;

  const FloatingHeader({
    super.key,
    required this.title,
    this.titleWidget,
    this.onBack,
    this.onMenuTap,
    this.actions,
    this.showBackButton = true,
    this.isMenu = false,
    this.contentAlignment = Alignment.center,
    this.hasBackground = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  });

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isMenu)
              _buildRoundIconButton(
                context, 
                HeroiconsOutline.bars3BottomLeft, 
                onMenuTap ?? () {},
              )
            else if (showBackButton)
              _buildRoundIconButton(
                context, 
                HeroiconsSolid.chevronLeft, 
                onBack ?? () => Navigator.pop(context),
              )
            else
              const SizedBox(width: 48), // Maintain spacing

            Expanded(
              child: Align(
                alignment: contentAlignment,
                child: Container(
                  padding: hasBackground ? const EdgeInsets.symmetric(horizontal: 24, vertical: 10) : EdgeInsets.zero,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: hasBackground ? BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ) : null,
                  child: titleWidget ?? Text(
                    title,
                    style: GoogleFonts.roboto(
                      fontSize: hasBackground ? 15 : 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF111827),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),

            if (actions != null && actions!.isNotEmpty)
              Row(children: actions!)
            else
              const SizedBox(width: 40), // Maintain spacing
          ],
        ),
      );
  }

  Widget _buildRoundIconButton(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Icon(icon, color: const Color(0xFF3F3F46), size: 20),
      ),
    );
  }

  static Widget buildActionBubble({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        margin: const EdgeInsets.only(left: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Icon(icon, color: color ?? const Color(0xFF3F3F46), size: 20),
      ),
    );
  }
}
