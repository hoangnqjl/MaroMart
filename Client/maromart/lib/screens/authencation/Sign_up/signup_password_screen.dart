import 'package:flutter/material.dart';
import 'package:maromart/services/auth_service.dart';
import 'package:maromart/components/ModernLoader.dart';

class SignUpPasswordScreen extends StatefulWidget {
  const SignUpPasswordScreen({super.key});

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
  String _gender = ''; // Nhận gender nhưng có thể không dùng trong API tùy backend

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
    }
  }

  @override
  void dispose() {
    _pw.dispose();
    _pw2.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
          SnackBar(content: Text(response['message'] ?? 'Đăng ký thành công!'), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/signin');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Đăng ký thất bại'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Background Gradient giống SignInScreen
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
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
                            backgroundColor: Colors.white.withOpacity(.9),
                            child: const Icon(Icons.security, color: Colors.black),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(.9),
                              child: const Icon(Icons.arrow_back, size: 18, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Secure Account',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set a strong password for $_email',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7A7A7A),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _RoundedPasswordField(
                        controller: _pw,
                        hint: 'Password...',
                        obscure: _ob1,
                        onToggle: () => setState(() => _ob1 = !_ob1),
                        validator: (v) {
                          if ((v?.trim().length ?? 0) < 6) return 'At least 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      _RoundedPasswordField(
                        controller: _pw2,
                        hint: 'Confirm Password...',
                        obscure: _ob2,
                        onToggle: () => setState(() => _ob2 = !_ob2),
                        validator: (v) {
                          if (v != _pw.text) return 'Passwords do not match';
                          return null;
                        },
                      ),

                      const SizedBox(height: 24),

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
                              ? const ModernLoader(
                            size: 20,
                            color: Colors.white,
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
    );
  }
}

// Widget riêng cho Password có nút ẩn hiện
class _RoundedPasswordField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?)? validator;

  const _RoundedPasswordField({
    this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white.withOpacity(.92),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: _border(),
        focusedBorder: _border(),
        errorBorder: _border(color: Colors.red),
        focusedErrorBorder: _border(color: Colors.red),
        prefixIcon: const Icon(Icons.lock_outline, size: 20, color: Colors.black54),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, size: 18, color: Colors.black54),
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(28),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}