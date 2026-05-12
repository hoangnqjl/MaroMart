import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/services/auth_service.dart';
import 'package:temo/services/location_service.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/utils/ui_helpers.dart';

class SignUpStep3AddressScreen extends StatefulWidget {
  const SignUpStep3AddressScreen({super.key});

  @override
  State<SignUpStep3AddressScreen> createState() =>
      _SignUpStep3AddressScreenState();
}

class _SignUpStep3AddressScreenState
    extends State<SignUpStep3AddressScreen> {
  final LocationService _locationService = LocationService();

  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _wards = [];

  Map<String, dynamic>? _selectedProvince;
  Map<String, dynamic>? _selectedWard;
  
  final _streetController = TextEditingController();
  bool _isLoadingData = true;
  bool _isLoadingFinish = false;

  static const String kBg = 'assets/images/backgroundauthen.png';

  @override
  void initState() {
    super.initState();
    _loadProvinces();
  }

  Future<void> _loadProvinces() async {
    setState(() => _isLoadingData = true);
    final data = await _locationService.getProvinces();
    if (mounted) {
      setState(() {
        _provinces = data;
        _isLoadingData = false;
      });
    }
  }

  Future<void> _onProvinceChanged(Map<String, dynamic>? province) async {
    if (province == null) return;
    setState(() {
      _selectedProvince = province;
      _selectedWard = null;
      _wards = [];
      _isLoadingData = true;
    });
    final data = await _locationService.getWards(province['province_code'].toString());
    if (mounted) {
      setState(() {
        _wards = data;
        _isLoadingData = false;
      });
    }
  }

  @override
  void dispose() {
    _streetController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_selectedProvince == null || _selectedWard == null || _streetController.text.isEmpty) {
      UIHelpers.showErrorSnackBar(context, 'Vui lòng điền đầy đủ thông tin địa chỉ');
      return;
    }

    setState(() => _isLoadingFinish = true);
    final args = ModalRoute.of(context)?.settings.arguments as Map? ?? {};
    final phoneStr = args['phoneNumber']?.toString().trim() ?? '';
    final phoneInt = phoneStr.isNotEmpty ? int.tryParse(phoneStr) : null;

    final fullAddress = "${_streetController.text}, ${_selectedWard!['ward_name']}, ${_selectedProvince!['name']}, Việt Nam";

    try {
      final fullName = args['fullName'] ?? '';
      final email = args['email'] ?? '';
      final password = args['password'] ?? '';

      await AuthService().register(
        fullName: fullName,
        email: email,
        password: password,
        phoneNumber: phoneInt,
        address: fullAddress,
      );
      
      // Auto Login
      await AuthService().login(email: email, password: password);

      if (!mounted) return;
      UIHelpers.showSuccessSnackBar(context, 'Đăng ký thành công! Đang vào trang chủ...');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (!mounted) return;
      UIHelpers.showErrorSnackBar(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoadingFinish = false);
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
                  "Thêm địa chỉ của bạn",
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Province Dropdown
                        _DropdownField(
                          value: _selectedProvince,
                          hint: 'Tỉnh / Thành phố',
                          items: _provinces,
                          labelKey: 'name',
                          onChanged: _onProvinceChanged,
                        ),
                        const SizedBox(height: 20),

                        // Ward Dropdown (Combined)
                        _DropdownField(
                          value: _selectedWard,
                          hint: 'Phường / Xã',
                          items: _wards,
                          labelKey: 'ward_name',
                          onChanged: (v) => setState(() => _selectedWard = v),
                        ),
                        const SizedBox(height: 20),

                        // Street Address (Text field)
                        _Field(
                          controller: _streetController,
                          hint: 'Số nhà, kiệt, hẻm, tên đường...',
                        ),

                        if (_isLoadingData) ...[
                          const SizedBox(height: 20),
                          ModernLoader(size: 24, color: Colors.white),
                        ],

                        const SizedBox(height: 40),
                        _FinishBtn(isLoading: _isLoadingFinish, onTap: _finish),
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

// ── Shared Widgets ──────────────────────────────────────────

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
        fillColor: const Color(0xFFF3F5F5).withOpacity(0.85),
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

class _DropdownField extends StatelessWidget {
  final Map<String, dynamic>? value;
  final String hint;
  final List<Map<String, dynamic>> items;
  final String labelKey;
  final ValueChanged<Map<String, dynamic>?> onChanged;

  const _DropdownField({
    required this.value,
    required this.hint,
    required this.items,
    required this.labelKey,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F5).withOpacity(0.85),
        borderRadius: BorderRadius.circular(28),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: value,
          isExpanded: true,
          dropdownColor: Colors.white,
          hint: Text(
            hint,
            style: GoogleFonts.roboto(
                color: Colors.black38, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black45),
          items: items
              .map((item) => DropdownMenuItem<Map<String, dynamic>>(
              value: item, child: Text(item[labelKey] ?? '', style: GoogleFonts.roboto(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600))))
              .toList(),
          onChanged: onChanged,
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
            : const Text('Hoàn tất'),
      ),
    );
  }
}