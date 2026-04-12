import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class UIHelpers {
  static void showSuccessDialog(BuildContext context, {required String title, required String message}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.checkCircle,
      iconColor: Colors.green,
      buttonText: "Tuyệt vời",
    );
  }

  static void showErrorDialog(BuildContext context, {required String title, required String message}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.exclamationCircle,
      iconColor: Colors.red,
      buttonText: "Đóng",
    );
  }

  static void showWarningDialog(BuildContext context, {required String title, required String message, String? buttonText}) {
    _showCustomDialog(
      context,
      title: title,
      message: message,
      icon: HeroiconsOutline.exclamationTriangle,
      iconColor: Colors.orange,
      buttonText: buttonText ?? "Đã hiểu",
    );
  }

  static void _showCustomDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String buttonText,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [iconColor.withOpacity(0.12), iconColor.withOpacity(0.02)],
                ),
              ),
              child: Icon(icon, color: iconColor, size: 48),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF18181B)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
          ],
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
    Color confirmColor = Colors.blue,
    IconData icon = HeroiconsOutline.questionMarkCircle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: confirmColor, size: 48),
              const SizedBox(height: 20),
              Text(title, style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF18181B))),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center, style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600], height: 1.5)),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(cancelText, style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
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
    _showSnackBar(context, message, Colors.green, HeroiconsOutline.checkCircle);
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    _showSnackBar(context, message, const Color(0xFFFB7C7F), HeroiconsOutline.exclamationCircle);
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
