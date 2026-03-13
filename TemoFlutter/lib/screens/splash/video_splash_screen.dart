import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:maromart/Home.dart';
import 'package:maromart/screens/authencation/get_started_screen.dart';
import 'package:maromart/utils/storage.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    // Assuming the user followed instructions and renamed the file to splash_intro.mp4
    _controller = VideoPlayerController.asset('assets/videos/splash_intro.mp4')
      ..initialize()
          .then((_) {
            setState(() {
              _initialized = true;
            });
            _controller.play();
            _controller.setLooping(false);

            // Listen for video end
            _controller.addListener(_checkVideoEnd);
          })
          .catchError((error) {
            debugPrint("Video Splash Error: $error");
            // Fallback or navigate immediately if video fails
            _navigateNext();
          });
  }

  void _checkVideoEnd() {
    if (_controller.value.position >= _controller.value.duration) {
      _navigateNext();
    }
  }

  void _navigateNext() {
    _controller.removeListener(_checkVideoEnd); // Prevent multiple calls

    // Determine where to go
    Widget nextScreen = StorageHelper.isLoggedIn()
        ? Home()
        : const GetStartedScreen();

    // Use replacement to remove splash from back stack
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Or black, depending on video bg
      body: Center(
        child: _initialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const SizedBox.shrink(), // Show nothing while initializing
      ),
    );
  }
}
