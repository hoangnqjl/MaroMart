import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maromart/components/ModalInAvt.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/auth_service.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/services/location_service.dart';
import 'package:maromart/Colors/AppColors.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final User? user;

  const TopBar({Key? key, this.user}) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final GlobalKey<ModalInAvtState> _modalKey = GlobalKey<ModalInAvtState>();
  final UserService _userService = UserService();
  final AuthService _authService = AuthService();
  final LocationService _locationService = LocationService();

  String? _detectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    final location = await _locationService.getCurrentAddress();
    if (mounted && location != null) {
      setState(() => _detectedLocation = location);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: _userService.userNotifier,
      builder: (context, currentUser, _) {
        final user = currentUser ?? widget.user;
        final avatarUrl = user?.avatarUrl ?? '';
        final displayName = user?.fullName ?? 'Khách';
        final fallbackAddress = user?.address ?? 'Quảng Bình';
        final location = _detectedLocation ?? fallbackAddress;

        return Container(
          padding: const EdgeInsets.only(
            left: 18,
            right: 8,
            top: 10,
            bottom: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  /// LEFT
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _modalKey.currentState?.show(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            width: 44,
                            height: 44,
                            color: Colors.grey.shade200,
                            child: _buildSafeAvatar(
                              avatarUrl,
                              displayName,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                // color: Colors.grey[400],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Location',
                                style: TextStyle(
                                  // color: Colors.grey[400],
                                  fontSize: 12,
                                  fontFamily: 'QuickSand',
                                ),
                              ),
                            ],
                          ),
                          Text(
                            location,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'QuickSand',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  /// RIGHT: MENU ICON
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.menu, size: 26),
                    onPressed: () => _openMainMenu(context),
                  ),
                ],
              ),

              ModalInAvt(key: _modalKey),
            ],
          ),
        );
      },
    );
  }

  void _openMainMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 12),

            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Thay đổi ngôn ngữ'),
              onTap: () {
                Navigator.pop(context);
                _openLanguageSelector(context);
              },
            ),

            const Divider(),

            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _logout(context);
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSafeAvatar(String url, String name) {
    if (url.isEmpty) {
      final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      return Container(
        alignment: Alignment.center,
        color: AppColors.primary,
        child: Text(
          firstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.person, color: Colors.grey),
    );
  }

  void _openLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          const Text(
            'Language',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.flag),
            title: const Text('Vietnamese'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('English'),
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _authService.logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
    );
  }
}
