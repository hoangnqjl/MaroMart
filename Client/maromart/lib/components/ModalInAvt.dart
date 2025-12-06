import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/ButtonWithIcon.dart';
import 'package:maromart/components/UserAvatar.dart'; // Import component mới
import 'package:maromart/services/user_service.dart';
import 'package:maromart/services/auth_service.dart';

class ModalInAvt extends StatefulWidget {
  const ModalInAvt({Key? key}) : super(key: key);

  @override
  State<ModalInAvt> createState() => ModalInAvtState();
}

class ModalInAvtState extends State<ModalInAvt> {
  OverlayEntry? _overlayEntry;
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();

  String _fullName = '';
  String _email = '';
  String _avatarUrl = '';

  void _refreshUserData() {
    final user = _userService.getCurrentUserFromStorage();
    setState(() {
      _fullName = user?.fullName ?? 'Khách';
      _email = user?.email ?? '';
      _avatarUrl = user?.avatarUrl ?? '';
    });
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    _refreshUserData();

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _hideOverlay,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
                  child: Container(
                    width: double.infinity,
                    height: 350,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  _hideOverlay();
                                  Navigator.pushNamed(context, '/profile');
                                },
                                child: Row(
                                  children: [
                                    // SỬ DỤNG UserAvatar component
                                    UserAvatar(
                                      avatarUrl: _avatarUrl,
                                      fullName: _fullName,
                                      size: 50,
                                      fontSize: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _fullName,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                              fontFamily: 'QuickSand',
                                              decoration: TextDecoration.none,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _email,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              decoration: TextDecoration.none,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ButtonWithIcon(
                              icon: HeroiconsOutline.xMark,
                              onPressed: _hideOverlay,
                              backgroundColor: Colors.white,
                              iconColor: Colors.black,
                              size: 30,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildMenuItem(
                          icon: HeroiconsOutline.squares2x2,
                          label: 'Product management',
                          onTap: () {
                            _hideOverlay();
                            Navigator.pushNamed(context, '/product-manager');
                          },
                        ),
                        _buildMenuItem(
                          icon: HeroiconsOutline.cog6Tooth,
                          label: 'Settings',
                          onTap: () {
                            _hideOverlay();
                            Navigator.pushNamed(context, '/settings');
                          },
                        ),
                        _buildMenuItem(
                          icon: HeroiconsOutline.megaphone,
                          label: 'Feedback',
                          onTap: () {
                            _hideOverlay();
                            Navigator.pushNamed(context, '/feedback');
                          },
                        ),
                        _buildMenuItem(
                          icon: HeroiconsOutline.arrowLeftStartOnRectangle,
                          label: 'Logout',
                          backgroundColor: AppColors.ColorFCEEEB,
                          iconColor: Colors.red,
                          onTap: () => _handleLogout(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? backgroundColor,
    Color? iconColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
              color: backgroundColor ?? Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.black, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    _hideOverlay();

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _authService.logout();

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/signin', (route) => false);
        }
      } catch (e) {
        print("Lỗi logout: $e");
        // Có thể hiện SnackBar thông báo lỗi
      }
    }
  }

  void show(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}