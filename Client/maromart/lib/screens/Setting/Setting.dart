import 'dart:io'; // Để check platform nếu cần
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Để check kIsWeb
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:image_picker/image_picker.dart'; // <--- Import Image Picker
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/components/UserAvatar.dart';
import 'package:maromart/services/user_service.dart';
import 'package:provider/provider.dart';
import 'package:maromart/providers/settings_provider.dart';
import 'package:maromart/l10n/app_localizations.dart';

class Setting extends StatefulWidget {
  const Setting({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Setting();
}

class _Setting extends State<Setting> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();

  String _fullName = '';
  String _email = '';
  String _avatarUrl = '';
  // String _email = '';
  // String _avatarUrl = '';
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      setState(() {
        _isUploading = true;
      });

      final updatedUser = await _userService.changeAvatar(image);

      setState(() {
        _avatarUrl = updatedUser.avatarUrl!;
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật ảnh đại diện thành công!"), backgroundColor: Colors.green),
      );

    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: TopBarSecond(title: l10n.settings),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
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

              const SizedBox(height: 24),

              _buildSectionTitle(l10n.preferences),
              const SizedBox(height: 12),
              _buildMenuItem(
                icon: HeroiconsOutline.language,
                label: l10n.language,
                onTap: () => _showLanguageSheet(context),
              ),
              const SizedBox(height: 8),
              _buildMenuItem(
                icon: HeroiconsOutline.informationCircle,
                label: l10n.aboutUs,
                onTap: () {
                  Navigator.pushNamed(context, '/about');
                },
              ),
              const SizedBox(height: 8),
              _buildDarkModeToggle(l10n.darkMode, settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              UserAvatar(
                avatarUrl: _avatarUrl,
                fullName: _fullName,
                size: 40,
                fontSize: 24,
              ),
              if (_isUploading)
                const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'QuickSand',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7) ?? Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isUploading ? null : _handleAvatarChange, // Gọi hàm upload
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                color: AppColors.E2Color,
              ),
              child: Icon(
                HeroiconsOutline.camera,
                size: 20,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.selectLanguage, // "Select Language"
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Text("🇺🇸", style: TextStyle(fontSize: 24)),
                title: const Text("English"),
                trailing: settings.locale.languageCode == 'en'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  settings.setLocale(const Locale('en'));
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Text("🇻🇳", style: TextStyle(fontSize: 24)),
                title: const Text("Tiếng Việt"),
                trailing: settings.locale.languageCode == 'vi'
                    ? const Icon(Icons.check, color: Colors.blue)
                    : null,
                onTap: () {
                  settings.setLocale(const Locale('vi'));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}