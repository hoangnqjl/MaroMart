import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/components/ModernLoader.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  static const String kIllustrationUrl = 'assets/images/backgroundauthen.png';
  static const String kGoogleAsset = 'assets/images/icongoogle.png';

  final _authService = AuthService();
  bool _isGoogleLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    UIHelpers.showSuccessSnackBar(context, message);
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
          Image.asset(
            kIllustrationUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[900]),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(color: Colors.black.withOpacity(0.10)),
            ),
          ),


          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.34, 0.65, 1.0],
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withOpacity(0.0),
                  Colors.white.withOpacity(0.0),
                ],
              ).createShader(bounds),
              blendMode: BlendMode.dstIn,
              child: Image.asset(
                kIllustrationUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[900]),
              ),
            ),
          ),

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

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Image.asset(
                            'assets/images/logotemoauthen.png',
                            height: 20,
                            width: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
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

                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Hành trình mua sắm\ncủa bạn bắt đầu tại đây.',
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
                              ? ModernLoader(
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
                                ? 'Đang đăng nhập...'
                                : 'Đăng nhập với Google',
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
                            'Đăng ký mới',
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
                            'Đăng nhập',
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