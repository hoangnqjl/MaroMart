import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/services/socket_service.dart';
import 'package:temo/utils/ui_helpers.dart';
import 'package:temo/utils/storage.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:temo/components/ModernLoader.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const String kGoogleAsset = 'assets/images/icongoogle.png';
  static const String kBg = 'assets/images/backgroundauthen.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _showPassword = false;

  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Vui lòng điền đầy đủ thông tin');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final loginResponse = await _authService.login(email: email, password: password);
      if (!mounted) return;
      SocketService().connect();
      _showSuccess('Đăng nhập thành công!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      if (loginResponse.mustChangePassword) {
        await StorageHelper.saveMustChangePassword(true);
        Navigator.pushReplacementNamed(context, '/force-change-password');
      } else {
        await StorageHelper.saveMustChangePassword(false);
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Thông tin đăng nhập không đúng!');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      SocketService().connect();
      _showSuccess('Đăng nhập thành công!');
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Đăng nhập Google thất bại: ', ''));
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    UIHelpers.showErrorSnackBar(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    UIHelpers.showSuccessSnackBar(context, message);
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Quên mật khẩu', style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nhập email của bạn để nhận mật khẩu tạm thời.', style: GoogleFonts.roboto(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: 'Email',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Hủy', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) return;
              Navigator.pop(context);
              try {
                await _authService.forgotPassword(email);
                _showSuccess('Mật khẩu tạm thời đã được gửi!');
              } catch (e) {
                _showError(e.toString().replaceAll('Exception: ', ''));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Gửi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(kBg, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[800])),

          // Premium Dark Blur Overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.25),
                    Colors.black.withOpacity(0.55),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 40),

                    // ── Title + Google icon ───────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title + subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Đăng nhập ngay!',
                              style: GoogleFonts.roboto(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/signup'),
                              child: RichText(
                                text: TextSpan(
                                  style: GoogleFonts.roboto(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                  children: [
                                    const TextSpan(text: "Chưa có tài khoản? / "),
                                    TextSpan(
                                      text: 'Đăng ký',
                                      style: GoogleFonts.roboto(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Google icon button
                        GestureDetector(
                          onTap: (_isLoading || _isGoogleLoading)
                              ? null
                              : _handleGoogleSignIn,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF3F5F5).withOpacity(0.70),
                            ),
                            child: _isGoogleLoading
                                ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: ModernLoader(
                                  size: 20, color: Colors.black54),
                            )
                                : Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                kGoogleAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata,
                                    color: Colors.black54),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // ── Email field ───────────────────────────────────────
                    _Field(
                      controller: _emailController,
                      hint: 'Email...',
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 20),

                    // ── Password field ────────────────────────────────────
                    _Field(
                      controller: _passwordController,
                      hint: 'Mật khẩu...',
                      obscure: !_showPassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.black38,
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ── Forgot password ───────────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _showForgotPasswordDialog,
                        child: Text(
                          'Quên mật khẩu?',
                          style: GoogleFonts.roboto(
                            color: Colors.white.withOpacity(0.80),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Login button ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isGoogleLoading)
                            ? null
                            : _handleSignIn,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.85),
                          foregroundColor: const Color(0xFF3F3F46),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28)),
                          textStyle: GoogleFonts.roboto(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF3F3F46)),
                        )
                            : const Text('Đăng nhập'),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field widget ──────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _Field({
    this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.roboto(
          color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
            color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFFF3F5F5).withOpacity(0.85),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide:
          BorderSide(color: Colors.white.withOpacity(0.6), width: 1.5),
        ),
      ),
    );
  }
}