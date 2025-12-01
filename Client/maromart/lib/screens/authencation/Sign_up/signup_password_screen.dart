import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:maromart/services/auth_service.dart';

class SignUpPasswordScreen extends StatefulWidget {
  const SignUpPasswordScreen({super.key});

  static const String kBackgroundAsset = 'lib/images/signup1.png';

  @override
  State<SignUpPasswordScreen> createState() => _SignUpPasswordScreenState();
}

class _SignUpPasswordScreenState extends State<SignUpPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final _pw = TextEditingController();
  final _pw2 = TextEditingController();

  bool _ob1 = true;
  bool _ob2 = true;
  bool _isProcessing = false;

  String _fullName = '';
  String _email = '';
  int? _phoneNumber;
  String _gender = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is Map<String, dynamic>) {
      _fullName = args['fullName'] ?? '';
      _email = args['email'] ?? '';
      final phone = args['phoneNumber'];
      if (phone != null) {
        if (phone is int) {
          _phoneNumber = phone;
        } else if (phone is String && phone.isNotEmpty) {
          _phoneNumber = int.tryParse(phone);
        }
      }
      _gender = args['gender'] ?? '';

      setState(() {});
    } else {
      print('⚠WARNING: No arguments received!');
    }
  }

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name is missing! Please go back and enter your name.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email is missing! Please go back and enter your email.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final response = await _authService.register(
        fullName: _fullName,
        email: _email,
        phoneNumber: _phoneNumber,
        password: _pw.text.trim(),
      );

      if (!mounted) return;

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đăng ký thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate về sign in
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Đăng ký thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString()
                .replaceAll('Exception: ', '')
                .replaceAll('Đăng ký thất bại: ', ''),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            SignUpPasswordScreen.kBackgroundAsset,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.blue.shade900,
            ),
          ),
          Container(color: Colors.black.withOpacity(0.35)),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: size.width > 480 ? 420 : size.width * 0.9,
                    padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: Colors.white.withOpacity(0.9),
                                child: const Icon(
                                  Icons.rocket_launch_outlined,
                                  color: Colors.black,
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.maybePop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.black,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text(
                            'MaroMart',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your password for $_fullName',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          _GlassField(
                            controller: _pw,
                            hint: 'Password...',
                            obscure: _ob1,
                            enabled: !_isProcessing,
                            prefix: const Icon(
                              Icons.lock_outline,
                              size: 20,
                              color: Colors.white,
                            ),
                            suffix: IconButton(
                              onPressed: () => setState(() => _ob1 = !_ob1),
                              icon: Icon(
                                _ob1 ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Please enter a password';
                              if (val.length < 6) return 'At least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),

                          // Re-type password
                          _GlassField(
                            controller: _pw2,
                            hint: 'Re-type password...',
                            obscure: _ob2,
                            enabled: !_isProcessing,
                            prefix: const Icon(
                              Icons.lock_reset,
                              size: 20,
                              color: Colors.white,
                            ),
                            suffix: IconButton(
                              onPressed: () => setState(() => _ob2 = !_ob2),
                              icon: Icon(
                                _ob2 ? Icons.visibility_off : Icons.visibility,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Please re-enter password';
                              if (val != _pw.text.trim()) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Create button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isProcessing ? null : _submit,
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
                              child: _isProcessing
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                                  : const Text('Create Account'),
                            ),
                          ),
                        ],
                      ),
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
}

class _GlassField extends StatelessWidget {
  final String hint;
  final bool obscure;
  final bool enabled;
  final Widget? prefix;
  final Widget? suffix;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.hint,
    this.obscure = false,
    this.enabled = true,
    this.prefix,
    this.suffix,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: _border(),
        focusedBorder: _border(),
        errorBorder: _border(),
        focusedErrorBorder: _border(),
        disabledBorder: _border(),
        prefixIcon: prefix == null
            ? null
            : Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 6),
          child: prefix,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffix,
        errorStyle: const TextStyle(
          color: Colors.yellowAccent,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  OutlineInputBorder _border() => OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: BorderSide.none,
  );
}