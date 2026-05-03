import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/screens/Setting/AppImprovementScreen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:temo/utils/ui_helpers.dart';

class UIHelper {
  static void showOptionsMenu(BuildContext context, {String? screenName}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(45),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  _buildOptionButton(
                    context,
                    icon: HeroiconsOutline.sparkles,
                    label: 'Cải tiến ứng dụng',
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppImprovementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static void showImageSourceSheet(BuildContext context, {
    required Function(XFile?) onPicked, 
    bool isVideo = false
  }) {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      isScrollControlled: true,
      useSafeArea: true,
      builder: (BuildContext ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(45),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    isVideo ? "Thêm Video" : "Thêm Ảnh",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildOptionButton(
                    context,
                    icon: HeroiconsOutline.camera,
                    label: isVideo ? "Quay Video" : "Chụp ảnh mới",
                    iconColor: AppColors.primary,
                    bgColor: AppColors.primary.withOpacity(0.1),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final status = await Permission.camera.request();
                      if (status.isGranted) {
                        try {
                          final XFile? media = isVideo 
                            ? await picker.pickVideo(source: ImageSource.camera)
                            : await picker.pickImage(source: ImageSource.camera, maxWidth: 1920, maxHeight: 1080);
                          onPicked(media);
                        } catch (e) {
                          UIHelpers.showErrorDialog(context, title: "Lỗi Camera", message: e.toString());
                        }
                      } else {
                        UIHelpers.showModernDialog(
                          context,
                          icon: HeroiconsOutline.lockClosed,
                          iconColor: AppColors.primary,
                          bgColor: AppColors.primary.withOpacity(0.1),
                          title: "Yêu cầu quyền truy cập",
                          description: "Vui lòng cấp quyền truy cập máy ảnh trong Cài đặt để sử dụng tính năng này.",
                          primaryButtonText: "Mở Cài đặt",
                          onPrimaryPressed: () {
                            Navigator.pop(context);
                            openAppSettings();
                          },
                          secondaryButtonText: "Hủy",
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildOptionButton(
                    context,
                    icon: HeroiconsOutline.photo,
                    label: isVideo ? "Chọn Video từ thư viện" : "Chọn Ảnh từ thư viện",
                    iconColor: AppColors.warning,
                    bgColor: AppColors.warning.withOpacity(0.1),
                    onTap: () async {
                      Navigator.pop(ctx);
                      try {
                        final XFile? media = isVideo 
                          ? await picker.pickVideo(source: ImageSource.gallery)
                          : await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1080);
                        onPicked(media);
                      } catch (e) {
                        UIHelpers.showErrorDialog(context, title: "Lỗi thư viện", message: e.toString());
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(45),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            Icon(HeroiconsOutline.chevronRight, color: Colors.black, size: 16),
          ],
        ),
      ),
    );
  }
}
