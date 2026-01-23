import 'package:flutter/material.dart';
import 'package:maromart/services/auth_service.dart';
import 'package:maromart/services/socket_service.dart';
import 'package:maromart/components/ModernLoader.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  static const String kLogoAsset = '';
  static const String kGoogleAsset = 'lib/images/logogg.png';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

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
      _showError('Vui lòng nhập đầy đủ thông tin');
      return;
    }

    if (!_isValidEmail(email)) {
      _showError('Email không hợp lệ');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.login(email: email, password: password);

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
          .replaceAll('Đăng nhập thất bại: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isGoogleLoading = true);

    try {
      print('Bắt đầu Google Sign In...');

      final response = await _authService.signInWithGoogle();

      print('Google Sign In thành công: $response');

      if (!mounted) return;

      // Kết nối socket sau khi đăng nhập thành công
      SocketService().connect();

      _showSuccess('Đăng nhập Google thành công!');

      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      print('Google Sign In Error: $e');

      if (!mounted) return;

      _showError(e.toString()
          .replaceAll('Exception: ', '')
          .replaceAll('Đăng nhập Google thất bại: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 212, 187, 249),
              Color.fromARGB(255, 242, 204, 196),
              Color.fromARGB(255, 195, 219, 245),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(.9),
                                child: _maybeAsset(
                                  kLogoAsset,
                                  const Icon(Icons.local_mall_sharp, color: Colors.black),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.maybePop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withOpacity(.9),
                                  child: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'MaroMart',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'MaroMart, the easy way for people to buy, sell, and connect with each other.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF7A7A7A),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 18),

                          _RoundedField(
                            controller: _emailController,
                            hint: 'Email...',
                            keyboardType: TextInputType.emailAddress,
                            enabled: !_isLoading && !_isGoogleLoading,
                          ),
                          const SizedBox(height: 14),

                          _RoundedField(
                            controller: _passwordController,
                            hint: 'Password...',
                            obscure: true,
                            enabled: !_isLoading && !_isGoogleLoading,
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isLoading || _isGoogleLoading) ? null : _handleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: const StadiumBorder(),
                                minimumSize: const Size(double.infinity, 56),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              child: _isLoading
                                  ? const ModernLoader(
                                size: 20,
                                color: Colors.white,
                              )
                                  : const Text('Sign in'),
                            ),
                          ),
                          const SizedBox(height: 28),

                          Center(
                            child: ElevatedButton.icon(
                              onPressed: (_isLoading || _isGoogleLoading)
                                  ? null
                                  : _handleGoogleSignIn,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 14,
                                ),
                              ),
                              icon: _isGoogleLoading
                                  ? const ModernLoader(
                                size: 20,
                                color: Colors.black,
                              )
                                  : SizedBox(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                  kGoogleAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.g_mobiledata,
                                    size: 24,
                                  ),
                                ),
                              ),
                              label: Text(
                                _isGoogleLoading
                                    ? 'Signing in...'
                                    : 'Sign in with Google',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _maybeAsset(String assetPath, Widget fallback) {
    if (assetPath.isEmpty) return fallback;
    return Image.asset(assetPath, fit: BoxFit.contain);
  }
}

class _RoundedField extends StatefulWidget {
  final TextEditingController? controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool enabled;

  const _RoundedField({
    this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.enabled = true,
  });

  @override
  State<_RoundedField> createState() => _RoundedFieldState();
}

class _RoundedFieldState extends State<_RoundedField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      enabled: widget.enabled,
      decoration: InputDecoration(
        hintText: widget.hint,
        filled: true,
        fillColor: Colors.white.withOpacity(.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: _border(),
        focusedBorder: _border(),
        disabledBorder: _border(),
        prefixIcon: widget.obscure
            ? const Icon(Icons.lock_outline, size: 20)
            : const Icon(Icons.email_outlined, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
        )
            : null,
      ),
    );
  }

  OutlineInputBorder _border() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide.none,
    );
  }
}