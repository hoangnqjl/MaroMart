import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/services/review_service.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:google_fonts/google_fonts.dart';

class RatingScreen extends StatefulWidget {
  final String orderId;
  final String revieweeId;

  const RatingScreen({super.key, required this.orderId, required this.revieweeId});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final ReviewService _reviewService = ReviewService();
  int _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_rating == 0) {
      UIHelpers.showErrorSnackBar(context, "Vui lòng chọn mức đánh giá");
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      UIHelpers.showErrorSnackBar(context, "Vui lòng viết một vài nhận xét");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await _reviewService.submitReview(
        orderId: widget.orderId,
        revieweeId: widget.revieweeId,
        rating: _rating,
        comment: _commentController.text,
      );

      final moderation = result['moderationResult'];
      final bool isSafe = moderation != null ? moderation['isSafe'] : true;

      if (mounted) {
        if (!isSafe) {
          UIHelpers.showWarningDialog(
            context,
            title: "Nhận xét bị từ chối",
            message: "Nội dung không phù hợp: ${moderation['reason']}",
          );
        } else {
          UIHelpers.showSuccessSnackBar(context, "Cảm ơn bạn đã phản hồi!");
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) UIHelpers.showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(HeroiconsOutline.chevronLeft, color: Colors.black, size: 20),
            ),
          ),
        ),
        title: Text(
          "Đánh giá người bán",
          style: GoogleFonts.roboto(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Stars Rating Box
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final isActive = index < _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = index + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isActive ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: isActive ? Colors.amber : Colors.grey[300],
                        size: 52,
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24),
            // Comment Box
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(color: const Color(0xFFF3F4F6)),
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Hãy chia sẻ thêm chi tiết về giao dịch của bạn...",
                  hintStyle: GoogleFonts.roboto(color: Colors.grey[400], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(24),
                ),
                style: GoogleFonts.roboto(fontSize: 15, color: const Color(0xFF1F2937)),
              ),
            ),
            const SizedBox(height: 40),
            // Submit Button
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(35),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                ),
                child: _isSubmitting 
                  ? const ModernLoader(color: Colors.white, size: 24)
                  : Text("Gửi đánh giá", style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
