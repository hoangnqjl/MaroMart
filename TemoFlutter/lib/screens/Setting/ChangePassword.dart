import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:flutter/material.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/TopBarSecond.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/storage.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  // 2. Khởi tạo UserService
  final UserService _userService = UserService();

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isProcessing = false;
  bool _ob1 = true;
  bool _ob2 = true;
  bool _ob3 = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final userId = StorageHelper.getUserId();
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not found. Please login again.')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _userService.updateUser(
        userId: userId,
        password: _newPasswordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password successfully changed!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password change failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Text(
                      "Bảo mật tài khoản",
                      style: GoogleFonts.roboto(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      "Thiết lập mật khẩu mới để bảo vệ tài khoản của bạn",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildPasswordTextField(
                    controller: _oldPasswordController,
                    hint: 'Mật khẩu hiện tại...',
                    icon: HeroiconsOutline.lockClosed,
                    obscure: _ob1,
                    toggleObscure: () => setState(() => _ob1 = !_ob1),
                    validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập mật khẩu hiện tại' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                    controller: _newPasswordController,
                    hint: 'Mật khẩu mới...',
                    icon: HeroiconsOutline.key,
                    obscure: _ob2,
                    toggleObscure: () => setState(() => _ob2 = !_ob2),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự';
                      if (val == _oldPasswordController.text.trim()) return 'Mật khẩu mới không được trùng mật khẩu cũ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPasswordTextField(
                    controller: _confirmPasswordController,
                    hint: 'Xác nhận mật khẩu mới...',
                    icon: HeroiconsOutline.shieldCheck,
                    obscure: _ob3,
                    toggleObscure: () => setState(() => _ob3 = !_ob3),
                    validator: (v) {
                      if (v != _newPasswordController.text) return 'Mật khẩu xác nhận không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 150),
                ],
              ),
            ),
          ),
          
          // Sticky Bottom Button
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.8),
                      Colors.white,
                    ],
                    stops: const [0, 0.4, 1],
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _handleChangePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: _isProcessing
                        ? const ModernLoader(size: 20, color: Colors.white)
                        : const Text('Cập nhật mật khẩu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),

          // Floating Header
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: FloatingHeader(
                  title: "",
                  hasBackground: false,
                  actions: [
                    FloatingHeader.buildActionBubble(
                      icon: HeroiconsSolid.ellipsisVertical,
                      onTap: () => UIHelper.showOptionsMenu(context, screenName: "Bảo mật"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.roboto(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111827)),
      decoration: InputDecoration(
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 24, right: 12),
          child: Icon(icon, color: Colors.grey[400], size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          fontSize: 15,
          color: Colors.grey[400],
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: AppColors.primary.withOpacity(0.5)),
        errorBorder: _border(color: Colors.red.withOpacity(0.5)),
        focusedErrorBorder: _border(color: Colors.red),
        suffixIcon: IconButton(
          onPressed: toggleObscure,
          icon: Icon(obscure ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye, color: Colors.grey[400], size: 20),
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(100),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}