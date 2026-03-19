import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpStep2PasswordScreen extends StatefulWidget {
  const SignUpStep2PasswordScreen({super.key});

  @override
  State<SignUpStep2PasswordScreen> createState() =>
      _SignUpStep2PasswordScreenState();
}

class _SignUpStep2PasswordScreenState
    extends State<SignUpStep2PasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _showPw = false;
  bool _showCf = false;

  static const String kBg = 'assets/images/backgroundauthen.png';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    Navigator.pushNamed(context, '/signup/address', arguments: {
      ...args,
      'password': _passwordController.text,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(kBg, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.grey[800])),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.22)),
          ),
          SafeArea(
            child: Column(
              children: [
                // ── Nút back ─────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BackBtn(onTap: () => Navigator.maybePop(context)),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  'Create password',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                const _StepBar(current: 2),

                const SizedBox(height: 32),

                // ── Form ─────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _Field(
                            controller: _passwordController,
                            hint: 'New password....',
                            obscure: !_showPw,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showPw
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black38,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _showPw = !_showPw),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password is required';
                              if (v.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _Field(
                            controller: _confirmController,
                            hint: 'Confirm password...',
                            obscure: !_showCf,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _showCf
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.black38,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setState(() => _showCf = !_showCf),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Please confirm password';
                              if (v != _passwordController.text)
                                return 'Passwords do not match';
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),
                          _NextBtn(label: 'Next', onTap: _next),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
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

// ── Shared Widgets (copy từ step 1) ──────────────────────────────────────────

class _StepBar extends StatelessWidget {
  final int current;
  const _StepBar({required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final step = i + 1;
        final done = step < current;
        final active = step == current;
        final circle = Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (active || done)
                ? Colors.white.withOpacity(0.85)
                : Colors.white.withOpacity(0.70),
          ),
          child: Center(
            child: done
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                : Text(
              '$step',
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF3F3F46),
              ),
            ),
          ),
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            i > 0
                ? Transform.translate(
              offset: const Offset(-0.5, 0),
              child: circle,
            )
                : circle,
            if (i < 2)
              Container(
                width: 60,
                height: 11,
                color: done
                    ? Colors.white.withOpacity(0.80)
                    : Colors.white.withOpacity(0.70),
              ),
          ],
        );
      }),
    );
  }
}

class _BackBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _BackBtn({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.20),
        ),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;

  const _Field({
    this.controller,
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.validator,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.roboto(
          color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
            color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w600),
        filled: true,
        fillColor: const Color(0xFFF3F5F5).withOpacity(0.70),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _NextBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NextBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.85),
          foregroundColor: const Color(0xFF3F3F46),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          textStyle:
          GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text('Next'),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}