import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:temo/Colors/AppColors.dart';

class ModernLoader extends StatelessWidget {
  final Color? color;
  final double size;
  final bool showText;

  const ModernLoader({super.key, this.color, this.size = 40.0, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final bool effectiveShowText = showText && size >= 35;

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoadingAnimationWidget.fourRotatingDots(
              color: color ?? AppColors.primary,
              size: size,
            ),
            if (effectiveShowText) ...[
              const SizedBox(height: 12),
              Flexible(
                child: Text(
                  "Vui lòng chờ...",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'QuickSand',
                    fontSize: size * 0.3,
                    fontWeight: FontWeight.w700,
                    color: color ?? const Color(0xFF3F3F46),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
