import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/components/ModernLoader.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const String kIllustrationUrl = 'assets/images/backgroundauthen.jpg';
  static const String kGoogleAsset = 'lib/images/logogg.png';

  final _authService = AuthService();
  bool _isGoogleLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      SocketService().connect();
      _showSuccess('Đăng nhập Google thành công!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _showError(
        e.toString()
            .replaceAll('Exception: ', '')
            .replaceAll('Đăng nhập Google thất bại: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Layer 1: Ảnh gốc (blur sẽ áp lên layer này) ─────────────────
          Image.asset(
            kIllustrationUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
          ),

          // ── Layer 2: Blur TOÀN MÀN HÌNH ──────────────────────────────────
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.10)),
            ),
          ),

          // ── Layer 3: Ảnh gốc đè lên phần trên, fade dần xuống dưới ──────
          // Đây là kỹ thuật then chốt:
          // - Phần trên: ảnh rõ nét (che blur)
          // - Phần dưới: ảnh fade out (để blur lộ ra)
          // → Tạo cảm giác blur tăng dần từ trên xuống, không gợn sóng
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.34, 0.65, 1.0],
                colors: [
                  Colors.white,                      // trên: ảnh hiện 100%
                  Colors.white,                      // giữ rõ đến 28%
                  Colors.white.withOpacity(0.0),     // fade bắt đầu
                  Colors.white.withOpacity(0.0),     // dưới: ảnh ẩn → blur lộ
                ],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn, // gradient làm alpha của ảnh
              child: Image.asset(
                kIllustrationUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[900]),
              ),
            ),
          ),

          // ── Layer 4: Dark overlay chung (áp sau khi fade) ────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.30),
                  Colors.black.withOpacity(0.45),
                ],
              ),
            ),
          ),

          // ── Layer 5: UI Content ───────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Top Bar ────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Temo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                      const Text(
                        'Eng/Vi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Center Slogan ──────────────────────────────────────────
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your shopping\njourney starts here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          fontFamily: 'Rokkitt',
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom Buttons ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Login with Google ────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed:
                          _isGoogleLoading ? null : _handleGoogleSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          icon: _isGoogleLoading
                              ? const ModernLoader(
                            size: 20,
                            color: Colors.white,
                          )
                              : Image.asset(
                            kGoogleAsset,
                            height: 20,
                            width: 20,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.g_mobiledata),
                          ),
                          label: Text(
                            _isGoogleLoading
                                ? 'Signing in...'
                                : 'Login with Google',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Register New ─────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signup'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.15),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Register new',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Divider ───────────────────────────────────────────
                      Container(
                        width: 20,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Login (Outlined) ──────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/signin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(
                              color: Colors.white,
                              width: 1.5,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}