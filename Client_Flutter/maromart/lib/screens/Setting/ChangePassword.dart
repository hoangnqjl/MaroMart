import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/storage.dart';

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
      appBar: const TopBarSecond(title: 'Change Password'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPasswordTextField(
                controller: _oldPasswordController,
                hint: 'Current Password...',
                obscure: _ob1,
                toggleObscure: () => setState(() => _ob1 = !_ob1),
                validator: (v) => (v?.isEmpty ?? true) ? 'Please enter current password' : null,
              ),
              const SizedBox(height: 16),
              _buildPasswordTextField(
                controller: _newPasswordController,
                hint: 'New Password...',
                obscure: _ob2,
                toggleObscure: () => setState(() => _ob2 = !_ob2),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.length < 6) return 'Password must be at least 6 characters';
                  if (val == _oldPasswordController.text.trim()) return 'New password cannot be the same as old password';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildPasswordTextField(
                controller: _confirmPasswordController,
                hint: 'Confirm New Password...',
                obscure: _ob3,
                toggleObscure: () => setState(() => _ob3 = !_ob3),
                validator: (v) {
                  if (v != _newPasswordController.text) return 'Password confirmation does not match';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Nút Change
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _handleChangePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.ButtonBlackColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    minimumSize: const Size(double.infinity, 56),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  child: _isProcessing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Change'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordTextField({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey[500],
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: AppColors.E2Color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: _border(),
        enabledBorder: _border(),
        focusedBorder: _border(color: Colors.black),
        errorBorder: _border(color: Colors.red),
        focusedErrorBorder: _border(color: Colors.red),
        suffixIcon: IconButton(
          onPressed: toggleObscure,
          icon: Icon(obscure ? HeroiconsOutline.eyeSlash : HeroiconsOutline.eye, color: Colors.grey[600]),
        ),
      ),
    );
  }

  OutlineInputBorder _border({Color color = Colors.transparent}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(30),
      borderSide: BorderSide(color: color, width: 1.5),
    );
  }
}