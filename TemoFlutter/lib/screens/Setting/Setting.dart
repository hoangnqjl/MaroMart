import 'dart:io'; 
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Để check kIsWeb
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/components/FloatingHeader.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/UserAvatar.dart';
import 'package:temo/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:temo/providers/settings_provider.dart';
import 'package:temo/l10n/app_localizations.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:temo/utils/ui_helpers.dart';

class Setting extends StatefulWidget {
  final VoidCallback? onMenuTap;
  const Setting({Key? key, this.onMenuTap}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Setting();
}

class _Setting extends State<Setting> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  late ScrollController _scrollController;

  String _fullName = '';
  String _email = '';
  String _avatarUrl = '';
  bool _isUploading = false;
  double _titleOpacity = 1.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    double offset = _scrollController.offset;
    // Fade out over the first 100 pixels of scroll
    double newOpacity = 1.0 - (offset / 100).clamp(0.0, 1.0);
    if (newOpacity != _titleOpacity) {
      setState(() {
        _titleOpacity = newOpacity;
      });
    }
  }

  void _loadUserData() {
    final user = _userService.getCurrentUserFromStorage();
    setState(() {
      _fullName = user?.fullName ?? 'Khách';
      _email = user?.email ?? '';
      _avatarUrl = user?.avatarUrl ?? '';
    });
  }

  Future<void> _handleAvatarChange() async {
    UIHelper.showImageSourceSheet(context, onPicked: (image) async {
      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      try {
        final updatedUser = await _userService.changeAvatar(image);

        setState(() {
          _avatarUrl = updatedUser.avatarUrl!;
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text("Cập nhật ảnh đại diện thành công!"), backgroundColor: AppColors.success),
        );
      } catch (e) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: AppColors.error),
        );
      }
    });
  }


  void _showPermissionDialog() {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 110), // Space for floating header
                  _buildProfileCard(),

              const SizedBox(height: 24),

              _buildSectionTitle(l10n.account),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: HeroiconsOutline.pencil,
                label: l10n.changeProfile,
                onTap: () {
                  Navigator.pushNamed(context, '/change-infomation');
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: HeroiconsOutline.lockClosed,
                label: l10n.changePassword,
                onTap: () {
                  Navigator.pushNamed(context, '/change-password');
                },
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: HeroiconsOutline.creditCard,
                label: 'Ví Temo (Xu)',
                onTap: () {
                  Navigator.pushNamed(context, '/coin_manager');
                },
              ),

              const SizedBox(height: 24),

              _buildSectionTitle(l10n.preferences),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: HeroiconsOutline.language,
                label: l10n.language,
                onTap: () => _showLanguageSheet(context),
              ),
              const SizedBox(height: 8),
              _buildDarkModeToggle(l10n.darkMode, settings),
              const SizedBox(height: 8),
               _buildMenuItem(
                icon: HeroiconsOutline.arrowPath,
                label: "Kiểm tra cập nhật",
                onTap: _checkForUpdates,
              ),

               const SizedBox(height: 24),

              _buildSectionTitle("Thông tin chung"),
              const SizedBox(height: 12),
               _buildMenuItem(
                icon: HeroiconsOutline.informationCircle,
                label: l10n.aboutUs,
                onTap: () {
                  Navigator.pushNamed(context, '/about');
                },
              ),
              
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Phiên bản $_appVersion",
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    ),
      Positioned(
        top: 0, left: 0, right: 0,
        child: SafeArea(
          bottom: false,
          child: FloatingHeader(
            title: l10n.settings,
            isMenu: true,
            hasBackground: false,
            titleOpacity: _titleOpacity,
            onMenuTap: widget.onMenuTap,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            actions: [
              FloatingHeader.buildActionBubble(
                icon: HeroiconsSolid.ellipsisVertical,
                onTap: () => UIHelper.showOptionsMenu(context, screenName: "Cài đặt"),
              ),
            ],
          ),
        ),
      ),
    ],
  ),
);
}

  String _appVersion = "2.0";

  Future<void> _checkForUpdates() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(child: ModernLoader()),
    );

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    Navigator.pop(context); // Close loader

    UIHelpers.showSuccessDialog(
      context,
      title: "Cập nhật ứng dụng",
      message: "Bạn đang sử dụng phiên bản mới nhất.",
    );
  }

  Widget _buildProfileCard() {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary.withOpacity(0.1), width: 2),
              ),
              child: UserAvatar(
                avatarUrl: _avatarUrl,
                fullName: _fullName,
                size: 100, // Increased size for a premium look
                fontSize: 40,
              ),
            ),
            if (_isUploading)
               Positioned.fill(child: Center(child: ModernLoader(size: 30, color: AppColors.primary))),
            Positioned(
              bottom: 5,
              right: 5,
              child: GestureDetector(
                onTap: _isUploading ? null : _handleAvatarChange,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 4))
                    ],
                  ),
                  child: const Icon(
                    HeroiconsSolid.camera,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          _fullName,
          style: GoogleFonts.quicksand(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _email,
          style: GoogleFonts.quicksand(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  // ... (Giữ nguyên các widget _buildSectionTitle, _buildMenuItem, _buildDarkModeToggle) ...
  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey[600],
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : AppColors.F6Color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).iconTheme.color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            Icon(
              HeroiconsOutline.chevronRight,
              size: 20,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDarkModeToggle(String label, SettingsProvider settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : AppColors.F6Color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Icon(HeroiconsOutline.moon, size: 20, color: Theme.of(context).iconTheme.color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ),
          CupertinoSwitch(
            value: settings.themeMode == ThemeMode.dark,
            activeColor: Theme.of(context).primaryColor,
            onChanged: (value) {
              settings.toggleTheme(value);
            },
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text(
                  l10n.selectLanguage,
                  style: GoogleFonts.roboto(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                _buildLanguageItem(
                  context, "🇺🇸", "English", 
                  settings.locale.languageCode == 'en',
                  () => settings.setLocale(const Locale('en'))
                ),
                const SizedBox(height: 12),
                _buildLanguageItem(
                  context, "🇻🇳", "Tiếng Việt", 
                  settings.locale.languageCode == 'vi',
                  () => settings.setLocale(const Locale('vi'))
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, String flag, String name, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        onTap();
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.05) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Text(name, style: GoogleFonts.roboto(fontWeight: FontWeight.w600, fontSize: 16)),
            const Spacer(),
            if (isSelected) const Icon(HeroiconsSolid.checkCircle, color: AppColors.primary, size: 24),
          ],
        ),
      ),
    );
  }
}