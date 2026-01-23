import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maromart/components/ModalInAvt.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/services/location_service.dart';

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
  final LocationService _locationService = LocationService();
  String? _detectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  Future<void> _fetchLocation() async {
    String? location = await _locationService.getCurrentAddress();
    if (mounted && location != null) {
      setState(() {
        _detectedLocation = location;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: _userService.userNotifier,
      builder: (context, currentUser, child) {
        final userToDisplay = currentUser ?? widget.user;
        final String avatarUrl = userToDisplay?.avatarUrl ?? '';
        final String displayName = userToDisplay?.fullName ?? 'Khách';

        // Lấy địa chỉ từ Model User (Fallback) - Only Address, No Country
        final String address = userToDisplay?.address ?? 'Quảng Bình';
        final String fallbackLocation = address;
        
        // Prioritize detected location
        final String fullLocation = _detectedLocation ?? fallbackLocation;

        return Container(
          color: Colors.white.withOpacity(0.9),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Stack(
            children: [
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
                        child: _buildSafeAvatar(avatarUrl, displayName),
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
                          Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            'Location',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                              fontFamily: 'QuickSand',
                            ),
                          ),
                        ],
                      ),
                      Text(
                        fullLocation, // Hiển thị địa chỉ động (Detected or Fallback)
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'QuickSand',
                          color: Colors.black,
                        ),
                      ),
                    ],
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

  Widget _buildSafeAvatar(String url, String name) {
    if (url.isEmpty) {
      String firstLetter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      return Container(
        color: const Color(0xFF3F4045),
        alignment: Alignment.center,
        child: Text(
          firstLetter,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Icon(Icons.person),
    );
  }
}