import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpStep1Screen extends StatefulWidget {
  const SignUpStep1Screen({super.key});

  @override
  State<SignUpStep1Screen> createState() => _SignUpStep1ScreenState();
}

class _SignUpStep1ScreenState extends State<SignUpStep1Screen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  static const String kBg = 'assets/images/backgroundauthen.png';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.pushNamed(context, '/signup/password', arguments: {
      'fullName': _fullNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background ảnh
          Image.asset(
            kBg,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[800]),
          ),

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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _BackBtn(onTap: () => Navigator.maybePop(context)),
                  ),
                ),

                const SizedBox(height: 32),

                Text(
                  "Let's get started",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                const _StepBar(current: 1),

                const SizedBox(height: 32),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _Field(
                            controller: _fullNameController,
                            hint: 'Full name...',
                            validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _Field(
                            controller: _emailController,
                            hint: 'Email...',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                          ),
                          const SizedBox(height: 20),
                          _Field(
                            controller: _phoneController,
                            hint: 'Phone number...',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          // Gender dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F5F5).withOpacity(0.85),
                              borderRadius: BorderRadius.circular(28),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGender,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                hint: Text(
                                  'Gender',
                                  style: GoogleFonts.roboto(
                                      color: Colors.black45, fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: Colors.black45),
                                items: _genders
                                    .map((g) => DropdownMenuItem(
                                    value: g, child: Text(g)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedGender = v),
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),
                          _NextBtn(label: 'Next', onTap: _next),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),

                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/signin'),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.roboto(
                          color: Colors.white.withOpacity(0.65), fontSize: 14),
                      children: [
                        const TextSpan(text: 'Have an account / '),
                        TextSpan(
                          text: 'Login',
                          style: GoogleFonts.roboto(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

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
      style: GoogleFonts.roboto(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w600),
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
          children: [
            Text(label),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}