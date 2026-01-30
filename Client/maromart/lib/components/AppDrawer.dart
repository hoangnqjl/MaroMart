import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/screens/Setting/Setting.dart';
import 'package:maromart/services/auth_service.dart';
import 'package:maromart/utils/storage.dart';
import 'package:maromart/app_router.dart';

class AppDrawer extends StatefulWidget {
  final User? user;
  const AppDrawer({super.key, this.user});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user ?? StorageHelper.getUser();
  }

  void _showTestingFeature() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Tính năng đang thử nghiệm", style: TextStyle(fontFamily: 'QuickSand')),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _handleLogout() async {
    await AuthService().logout();
    if (mounted) {
       Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
    }
  }

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If user is null, try to reload if Storage was slow initially
    final user = _currentUser ?? StorageHelper.getUser();

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 250,
        margin: const EdgeInsets.only(right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 30),
                    // Profile Info
                     if (user != null)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.primary, width: 2)),
                            child: CircleAvatar(
                              radius: 35,
                              backgroundImage: (user.avatarUrl ?? "").isNotEmpty
                                  ? NetworkImage(user.avatarUrl!)
                                  : null,
                              child: (user.avatarUrl ?? "").isEmpty
                                  ? Text(user.fullName.isNotEmpty == true ? user.fullName[0].toUpperCase() : "U",
                                      style: const TextStyle(fontSize: 24, color: AppColors.primary))
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Menu Items
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _buildDrawerItem(HeroiconsOutline.home, "Trang chủ", () => Navigator.pop(context)),
                          _buildDrawerItem(HeroiconsOutline.heart, "Yêu thích", _showTestingFeature),
                          _buildDrawerItem(HeroiconsOutline.clock, "Lịch sử", _showTestingFeature),
                          _buildDrawerItem(HeroiconsOutline.user, "Tài khoản", _showTestingFeature),
                          _buildDrawerItem(HeroiconsOutline.cog6Tooth, "Cài đặt", () {
                              Navigator.pop(context); 
                              smoothPush(context, Setting());
                          }),
                        ],
                      ),
                    ),

                    _buildDrawerItem(HeroiconsOutline.arrowRightOnRectangle, "Đăng xuất", _handleLogout, isDestructive: true),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
