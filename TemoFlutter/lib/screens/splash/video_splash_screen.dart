import 'dart:async';
import 'package:flutter/material.dart';
import 'package:temo/Home.dart';
import 'package:temo/screens/authencation/get_started_screen.dart';
import 'package:temo/utils/storage.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  bool _isNavigated = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    // Chuyển màn hình sau 2 giây thay vì dùng video
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() {
    if (_isNavigated) return;
    _isNavigated = true;

    Widget nextScreen;
    if (StorageHelper.isLoggedIn()) {
      if (StorageHelper.getMustChangePassword()) {
        Navigator.pushReplacementNamed(context, '/force-change-password');
        return;
      }
      nextScreen = Home();
    } else {
      nextScreen = const GetStartedScreen();
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hiển thị logo tĩnh thay vì video
            Image.asset(
              'assets/images/LogoTemo.png',
              width: 150,
              height: 150,
              errorBuilder: (context, error, stackTrace) => const FlutterLogo(size: 100),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFFB86A)),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
