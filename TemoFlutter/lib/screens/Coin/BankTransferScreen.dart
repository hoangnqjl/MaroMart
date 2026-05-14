import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/PremiumImage.dart';

class BankTransferScreen extends StatefulWidget {
  final Map<String, dynamic> bank;
  final int coins;
  final int bonus;
  final String priceText;
  final double amount;

  const BankTransferScreen({
    super.key,
    required this.bank,
    required this.coins,
    required this.bonus,
    required this.priceText,
    required this.amount,
  });

  @override
  State<BankTransferScreen> createState() => _BankTransferScreenState();
}

class _BankTransferScreenState extends State<BankTransferScreen> {
  final UserService _userService = UserService();
  bool _isConfirming = false;
  late String _transferNote;

  @override
  void initState() {
    super.initState();
    final userId = StorageHelper.getUserId() ?? 'USER';
    final shortId = userId.length > 8 ? userId.substring(userId.length - 6).toUpperCase() : userId;
    _transferNote = "TEMO TOPUP $shortId ${widget.coins}";
  }

  String get _qrUrl {
    final accountNo = widget.bank['accountNo'].toString().replaceAll(' ', '');
    final bankId = widget.bank['bin']; // VietQR uses BIN or ShortName
    return "https://img.vietqr.io/image/$bankId-$accountNo-compact.png?amount=${widget.amount.toInt()}&addInfo=${Uri.encodeComponent(_transferNote)}&accountName=${Uri.encodeComponent(widget.bank['accountHolder'])}";
  }

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);
    try {
      // Simulate verification delay
      await Future.delayed(const Duration(seconds: 2));
      
      final totalCoins = widget.coins + widget.bonus;
      await _userService.depositCoins(totalCoins);
      
      if (mounted) {
        UIHelpers.showSuccessSnackBar(context, "Thanh toán thành công! Đã thêm $totalCoins xu vào ví của bạn.");
        Navigator.pop(context, true); // Return success
      }
    } catch (e) {
      if (mounted) UIHelpers.showErrorSnackBar(context, "Xác minh thất bại: $e");
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Thông tin thanh toán", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Bank Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Image.asset(widget.bank['logo'], errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.bank['name'], style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(widget.bank['accountHolder'], style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Column(
                children: [
                   PremiumImage(
                    imageUrl: _qrUrl,
                    width: 250,
                    height: 250,
                    placeholder: const SizedBox(height: 250, child: Center(child: ModernLoader())),
                    errorWidget: const Icon(Icons.error),
                  ),
                  const SizedBox(height: 16),
                  Text("Quét mã QR để thanh toán", style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Details Table
            _buildDetailRow("Số tiền", widget.priceText, isBold: true),
            const Divider(height: 32),
            _buildDetailRow("Số tài khoản", widget.bank['accountNo'], canCopy: true),
            const Divider(height: 32),
            _buildDetailRow("Nội dung chuyển khoản", _transferNote, canCopy: true, isNote: true),
            
            const SizedBox(height: 48),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConfirming ? null : _handleConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isConfirming 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Tôi đã chuyển khoản", style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Chỉ nhấn sau khi bạn đã hoàn tất chuyển khoản",
              style: GoogleFonts.roboto(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false, bool canCopy = false, bool isNote = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.roboto(color: Colors.grey[600], fontSize: 14)),
        Row(
          children: [
            Text(
              value,
              style: GoogleFonts.roboto(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: isBold ? 18 : 15,
                color: isNote ? AppColors.primary : Colors.black,
              ),
            ),
            if (canCopy) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // Simulate copy
                  UIHelpers.showSuccessSnackBar(context, "Đã sao chép vào bộ nhớ tạm!");
                },
                child: const Icon(HeroiconsOutline.documentDuplicate, size: 16, color: Colors.blue),
              )
            ]
          ],
        ),
      ],
    );
  }
}
