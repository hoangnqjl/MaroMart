import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/screens/Setting/Setting.dart';
import 'package:temo/screens/Setting/FeedbackScreen.dart';
import 'package:temo/screens/Product/SavedProductsScreen.dart';
import 'package:temo/screens/Coin/CoinManagerScreen.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/screens/Setting/ChangeInfomation.dart';
import 'package:google_fonts/google_fonts.dart';

class SideMenu extends StatelessWidget {
  final User? user;
  final Function(Widget) onNavigate;

  const SideMenu({
    super.key, 
    this.user,
    required this.onNavigate,
  });

  void _handleLogout(BuildContext context) async {
    await AuthService().logout();
    if (context.mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Removed solid white for a more integrated feel
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 24, top: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Info
              _buildHeader(context),
              const SizedBox(height: 40),
              
              // Menu Items
              _buildMenuItem(
                icon: HeroiconsOutline.user, 
                label: "Chỉnh sửa cá nhân", 
                onTap: () => onNavigate(const ChangeInformationScreen()),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: HeroiconsOutline.bookmark, 
                label: "Danh sách đã lưu", 
                onTap: () => onNavigate(const SavedProductsScreen()),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: HeroiconsOutline.currencyDollar, 
                label: "Coins", 
                onTap: () => onNavigate(const CoinManagerScreen()),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: HeroiconsOutline.language, 
                label: "Ngôn ngữ", 
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text("Tính năng ngôn ngữ đang phát triển", style: TextStyle(fontFamily: 'QuickSand')),
                      backgroundColor: Colors.grey[800],
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: HeroiconsOutline.chatBubbleLeftRight, 
                label: "Feedback", 
                onTap: () => onNavigate(const FeedbackScreen()),
              ),
              const SizedBox(height: 20),
              _buildMenuItem(
                icon: HeroiconsOutline.arrowRightOnRectangle, 
                label: "Đăng xuất", 
                onTap: () => _handleLogout(context),
              ),
              
              const Spacer(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: (user?.avatarUrl?.isNotEmpty ?? false)
                ? Image.network(user!.avatarUrl!, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(HeroiconsOutline.user, color: Colors.grey),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user?.fullName ?? "User Name",
          style: GoogleFonts.quicksand(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1F2937),
          ),
        ),
        Text(
          "@${user?.fullName.replaceAll(' ', '').toLowerCase() ?? 'user'}",
          style: GoogleFonts.quicksand(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1F2937), size: 22),
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
