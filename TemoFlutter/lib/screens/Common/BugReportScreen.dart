import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/utils/UIHelper.dart';

class BugReportScreen extends StatefulWidget {
  final String? preFilledError;
  const BugReportScreen({super.key, this.preFilledError});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedCategory = 'Giao diện';
  bool _isSubmitting = false;

  final List<String> _categories = ['Giao diện', 'Tính năng', 'Hiệu năng', 'Khác'];

  @override
  void initState() {
    super.initState();
    if (widget.preFilledError != null) {
      _descriptionController.text = widget.preFilledError!;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitReport() async {
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    if (mounted) {
      setState(() => _isSubmitting = false);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          title: const Text("Thành công"),
          content: const Text("Cảm ơn bạn đã phản hồi. Chúng tôi sẽ xử lý sớm nhất có thể!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("Đóng"),
            ),
          ],
        ),
      );
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
                    "Báo cáo lỗi",
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
                    "Chúng tôi có thể giúp gì cho bạn?",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                _buildLabel("Loại vấn đề"),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _categories.map((cat) => _buildCategoryChip(cat)).toList(),
                ),
                const SizedBox(height: 32),

                _buildLabel("Tiêu đề lỗi"),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _titleController,
                  hint: "Ví dụ: Lỗi không hiển thị avatar...",
                  icon: HeroiconsOutline.pencil,
                ),
                const SizedBox(height: 24),

                _buildLabel("Mô tả chi tiết"),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _descriptionController,
                  hint: "Hãy cho chúng tôi biết điều gì đã xảy ra...",
                  icon: HeroiconsOutline.chatBubbleLeftEllipsis,
                  maxLines: 5,
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
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
                    onPressed: _isSubmitting ? null : _submitReport,
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
                      : const Text("Gửi phản hồi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    onTap: () => UIHelper.showOptionsMenu(context, screenName: "Báo cáo lỗi"),
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
      style: GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w800, color: const Color(0xFF1F2937)),
    );
  }

  Widget _buildCategoryChip(String label) {
    bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(45),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF4B5563),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: EdgeInsets.fromLTRB(24, maxLines == 1 ? 0 : 20, 12, maxLines == 1 ? 0 : 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: maxLines == 1 ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey[400], size: 22),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          fontSize: 15,
          color: Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: _border(maxLines: maxLines),
        enabledBorder: _border(maxLines: maxLines),
        focusedBorder: _border(color: AppColors.primary.withOpacity(0.5), maxLines: maxLines),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.transparent, int maxLines = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(maxLines == 1 ? 100 : 35),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}
