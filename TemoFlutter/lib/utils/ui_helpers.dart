import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';

class UIHelpers {
  static void showSuccessDialog(BuildContext context, {required String title, required String message, VoidCallback? onConfirm}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.checkCircle,
      iconColor: AppColors.success,
      buttonText: "Tuyệt vời",
      onConfirm: onConfirm,
    );
  }

  static void showErrorDialog(BuildContext context, {required String title, required String message, VoidCallback? onConfirm}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.exclamationCircle,
      iconColor: AppColors.error,
      buttonText: "Đóng",
      onConfirm: onConfirm,
    );
  }

  static void showWarningDialog(BuildContext context, {required String title, required String message, String? buttonText, VoidCallback? onConfirm}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.exclamationTriangle,
      iconColor: AppColors.warning,
      buttonText: buttonText ?? "Đã hiểu",
      onConfirm: onConfirm,
    );
  }

  static void _showCustomDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
    VoidCallback? onConfirm,
  }) {
    showModernDialog(
      context,
      icon: icon,
      iconColor: iconColor,
      bgColor: iconColor.withOpacity(0.1),
      title: title,
      description: message,
      primaryButtonText: buttonText,
      onPrimaryPressed: onConfirm,
    );
  }

  static void showModernDialog(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String description,
    Widget? content,
    String? primaryButtonText,
    VoidCallback? onPrimaryPressed,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF3F3F46)),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              if (content != null) ...[
                const SizedBox(height: 24),
                content,
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  if (secondaryButtonText != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4F4F5),
                          foregroundColor: const Color(0xFF3F3F46),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        onPressed: onSecondaryPressed ?? () => Navigator.pop(context),
                        child: Text(secondaryButtonText, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: onPrimaryPressed ?? () => Navigator.pop(context),
                      child: Text(primaryButtonText ?? "Đã hiểu", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> confirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = "Xác nhận",
    String cancelText = "Hủy bỏ",
    Color confirmColor = AppColors.primary,
    IconData icon = HeroiconsOutline.questionMarkCircle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context, false),
                    child: const Icon(Icons.close, color: Colors.grey, size: 20),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: confirmColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: confirmColor, size: 30),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF3F3F46)),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4F4F5),
                        foregroundColor: const Color(0xFF3F3F46),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(cancelText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.success, HeroiconsOutline.checkCircle);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    _showSnackBar(context, message, AppColors.error, HeroiconsOutline.exclamationCircle);
  }

  static void _showSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 14, color: const Color(0xFF18181B)),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withOpacity(0.1), width: 1),
        ),
        elevation: 10,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
