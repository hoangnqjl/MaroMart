import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/services/auth_service.dart';

class SignUpStep3AddressScreen extends StatefulWidget {
  const SignUpStep3AddressScreen({super.key});

  @override
  State<SignUpStep3AddressScreen> createState() =>
      _SignUpStep3AddressScreenState();
}

class _SignUpStep3AddressScreenState
    extends State<SignUpStep3AddressScreen> {
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardController = TextEditingController();
  final _streetController = TextEditingController();
  bool _isLoading = false;

  static const String kBg = 'assets/images/backgroundauthen.png';

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _wardController.dispose();
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final phoneStr = args['phoneNumber']?.toString().trim() ?? '';
    final phoneInt = phoneStr.isNotEmpty ? int.tryParse(phoneStr) : null;

    try {
      await AuthService().register(
        fullName: args['fullName'] ?? '',
        email: args['email'] ?? '',
        password: args['password'] ?? '',
        phoneNumber: phoneInt,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/signin');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                  "Let's add your address",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.roboto(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                const _StepBar(current: 3),

                const SizedBox(height: 32),

                // ── Form ─────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _Field(
                          controller: _countryController,
                          hint: 'Country...',
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          controller: _cityController,
                          hint: 'Province/City',
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          controller: _wardController,
                          hint: 'Ward',
                        ),
                        const SizedBox(height: 20),
                        _Field(
                          controller: _streetController,
                          hint: 'Street address',
                        ),

                        const SizedBox(height: 40),
                        _FinishBtn(isLoading: _isLoading, onTap: _finish),
                        const SizedBox(height: 20),
                      ],
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
  final TextInputType? keyboardType;

  const _Field({this.controller, required this.hint, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

class _FinishBtn extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onTap;
  const _FinishBtn({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.85),
          foregroundColor: const Color(0xFF3F3F46),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28)),
          textStyle:
          GoogleFonts.roboto(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Color(0xFF3F3F46)),
        )
            : const Text('Finish'),
      ),
    );
  }
}