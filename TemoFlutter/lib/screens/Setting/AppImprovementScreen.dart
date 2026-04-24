import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/services/api_service.dart';

class AppImprovementScreen extends StatefulWidget {
  const AppImprovementScreen({super.key});

  @override
  State<AppImprovementScreen> createState() => _AppImprovementScreenState();
}

class _AppImprovementScreenState extends State<AppImprovementScreen> {
  final TextEditingController _contentController = TextEditingController();
  String _selectedCategory = 'Đề xuất mới';
  bool _isSubmitting = false;
  List<File> _images = [];
  String _selectedBugType = 'Giao diện';

  final List<String> _bugTypes = ['Giao diện', 'Tính năng', 'Hiệu năng', 'Khác'];
  int _rating = 5;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Đề xuất mới', 'icon': HeroiconsOutline.lightBulb},
    {'label': 'Phản hồi ứng dụng', 'icon': HeroiconsOutline.chatBubbleLeftRight},
    {'label': 'Báo lỗi', 'icon': HeroiconsOutline.bugAnt},
  ];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();
    if (pickedFiles != null) {
      if (_images.length + pickedFiles.length > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tối đa 5 ảnh')));
        return;
      }
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  void _submitImprovement() async {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng mô tả nội dung bạn muốn gửi")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final formData = {
        'category': _selectedCategory,
        'content': _contentController.text,
      };

      // Reuse postMultipart if available, or simulate
      await Future.delayed(const Duration(milliseconds: 1500));
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(45)),
            title: const Center(child: Text("Thành công")),
            content: const Text(
              "Cảm ơn đóng góp của bạn! Chúng tôi sẽ xem xét để cải thiện ứng dụng tốt hơn.",
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text("Đóng", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 120),
                Center(
                  child: Text(
                    "Cải tiến ứng dụng",
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Cùng MaroMart xây dựng trải nghiệm tốt hơn",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildLabel("Bạn muốn gửi gì cho chúng tôi?"),
                const SizedBox(height: 10),
                Column(
                  children: _categories.map((cat) => _buildCategoryItem(cat)).toList(),
                ),

                // Rating (Shown only when Phản hồi ứng dụng is selected)
                if (_selectedCategory == 'Phản hồi ứng dụng') ...[
                  const SizedBox(height: 20),
                  _buildLabel("Đánh giá ứng dụng"),
                  const SizedBox(height: 10),
                  _buildRatingStars(),
                ],
                
                // Bug Types (Shown only when Báo lỗi is selected)
                if (_selectedCategory == 'Báo lỗi') ...[
                  const SizedBox(height: 20),
                  _buildLabel("Loại lỗi cụ thể"),
                  const SizedBox(height: 10),
                  _buildSelectField(
                    value: _selectedBugType,
                    icon: HeroiconsOutline.tag,
                    onTap: () => _showBugTypePicker(),
                  ),
                ],
                const SizedBox(height: 24),

                _buildLabel("Mô tả nội dung"),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(35),
                  ),
                  child: TextField(
                    controller: _contentController,
                    maxLines: 6,
                    style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: "Hãy cho chúng tôi biết ý kiến hoặc vấn đề của bạn...",
                      hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(24),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel("Ảnh minh họa (Tùy chọn)"),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 85, height: 85,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(45),
                          ),
                          child: Icon(HeroiconsOutline.camera, color: Colors.grey[500], size: 30),
                        ),
                      ),
                      ..._images.asMap().entries.map((entry) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 85, height: 85,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(45),
                                image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                              ),
                            ),
                            Positioned(
                              top: -8, right: 4,
                              child: GestureDetector(
                                onTap: () => setState(() => _images.removeAt(entry.key)),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.close, color: Colors.red, size: 14),
                                ),
                              ),
                            )
                          ],
                        );
                      }).toList()
                    ],
                  ),
                ),
                const SizedBox(height: 150),
              ],
            ),
          ),

          // Sticky Bottom Button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitImprovement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: _isSubmitting 
                      ? const ModernLoader(color: Colors.white, size: 20)
                      : const Text("Gửi thông tin", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),

          // Floating Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: FloatingHeader(
                title: "",
                hasBackground: false,
                actions: [
                  FloatingHeader.buildActionBubble(
                    icon: HeroiconsSolid.ellipsisVertical,
                    onTap: () => UIHelper.showOptionsMenu(context, screenName: "Cải tiến"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF1F2937)),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> cat) {
    bool isSelected = _selectedCategory == cat['label'];
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat['label']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                cat['icon'],
                color: isSelected ? Colors.white : Colors.grey[500],
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              cat['label'],
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? AppColors.primary : const Color(0xFF4B5563),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(HeroiconsSolid.checkCircle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectField({required String value, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.grey[400], size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF111827),
              ),
            ),
            const Spacer(),
            Icon(HeroiconsOutline.chevronDown, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }

  void _showBugTypePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(45)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Chọn loại lỗi cụ thể",
                style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ..._bugTypes.map((type) => ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Icon(
                  _selectedBugType == type ? HeroiconsSolid.checkCircle : Icons.radio_button_unchecked,
                  color: _selectedBugType == type ? AppColors.primary : Colors.grey[300],
                ),
                title: Text(
                  type,
                  style: GoogleFonts.roboto(
                    fontWeight: _selectedBugType == type ? FontWeight.bold : FontWeight.w500,
                    color: _selectedBugType == type ? AppColors.primary : Colors.black87,
                  ),
                ),
                onTap: () {
                  setState(() => _selectedBugType = type);
                  Navigator.pop(context);
                },
              )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingStars() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      children: List.generate(5, (index) {
        int starValue = index + 1;
        bool isFull = _rating >= starValue;
        return GestureDetector(
          onTap: () => setState(() => _rating = starValue),
          child: Icon(
            isFull ? HeroiconsSolid.star : HeroiconsOutline.star,
            color: isFull ? Colors.amber[400] : Colors.grey[300],
            size: 32,
          ),
        );
      }),
    );
  }
}
