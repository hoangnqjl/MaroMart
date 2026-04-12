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
      UIHelpers.showErrorSnackBar(context, "Please select a rating");
      return;
    }

    if (_commentController.text.trim().isEmpty) {
      UIHelpers.showErrorSnackBar(context, "Please write a short comment");
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
            title: "Review Rejected",
            message: "Content not valid: ${moderation['reason']}",
            buttonText: "Edit",
          );
        } else {
          UIHelpers.showSuccessSnackBar(context, "Thank you for your feedback!");
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Rate Seller", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Text("How was your experience?", 
                    style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text("Your feedback helps the community grow stronger.", 
                    style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final isActive = index < _rating;
                      return GestureDetector(
                        onTap: () => setState(() => _rating = index + 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            isActive ? Icons.star_rate_rounded : Icons.star_outline_rounded,
                            color: isActive ? Colors.amber : Colors.grey[300],
                            size: 52,
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15)],
              ),
              child: TextField(
                controller: _commentController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: "Share more details about your transaction...",
                  hintStyle: GoogleFonts.quicksand(color: Colors.grey[400]),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  fillColor: Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.all(20),
                ),
                style: GoogleFonts.quicksand(fontSize: 15),
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                  ? const ModernLoader(color: Colors.white, size: 24)
                  : Text("Submit Review", style: GoogleFonts.quicksand(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
