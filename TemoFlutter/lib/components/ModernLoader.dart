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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoadingAnimationWidget.fourRotatingDots(
            color: color ?? AppColors.primary,
            size: size,
          ),
          if (showText) ...[
            const SizedBox(height: 16),
            Flexible(
              child: Text(
                "Vui lòng chờ chút nhé...",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'QuickSand',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? const Color(0xFF3F3F46),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
