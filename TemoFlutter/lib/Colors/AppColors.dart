import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (Vibrant Orange Theme)
  static const Color primary = Color(0xFFFB9A40); 
  static const Color primaryLight = Color(0xFFFFB86A);
  static const Color primaryDark = Color(0xFFE07C2A);
  
  static const Gradient primaryGradient = LinearGradient(
    colors: [
      Color(0xFFFFB86A),
      Color(0xFFFB9A40),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Secondary colors
  static const Color secondary = Color(0xFFE2E2E2);
  static const Color accent = Color(0xFFFF8A65); // Softer destructive red-orange

  // Neutral colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF333333);
  static const Color textLight = Color(0xFF666666);

  // Custom colors với opacity
  static const Color E2Color = Color(0x80E2E2E2); // #E2E2E280 = 50% opacity
  static const Color F6Color = Color(0xFFF6F6F6); // #E2E2E280 = 50% opacity
  static const Color overlayLight = Color(0x4DE2E2E2); // 30% opacity
  static const Color overlayDark = Color(0xB3E2E2E2); // 70% opacity
  static const Color ButtonBlackColor = primary;
  static const Color ColorFCEEEB = Color(0xFFFCEEEB);
  static const Color ColorCCCC = Color(0xFFCCCCCC);

  // Functional colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);
}