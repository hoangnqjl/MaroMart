import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class SignUpInfoScreen extends StatefulWidget {
  const SignUpInfoScreen({super.key});

  static const String kBackgroundAsset = 'lib/images/signup1.png';

  @override
  State<SignUpInfoScreen> createState() => _SignUpInfoScreenState();
}

class _SignUpInfoScreenState extends State<SignUpInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Trạng thái cho Gender Selection
  String? _selectedGender;
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your gender'), backgroundColor: Colors.red),
        );
        return;
      }

      // Thu thập dữ liệu và điều hướng
      final fullName = _fullNameController.text.trim();
      final email = _emailController.text.trim();
      final phoneNumber = _phoneController.text.trim();
      final gender = _selectedGender!;

      Navigator.pushNamed(
        context,
        '/signup/password',
        arguments: {
          'fullName': fullName,
          'email': email,
          'phoneNumber': phoneNumber.isNotEmpty ? phoneNumber : null,
          'gender': gender,
        },
      );
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
          Image.asset(SignUpInfoScreen.kBackgroundAsset, fit: BoxFit.cover),
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
                                child: const Icon(Icons.rocket_launch_outlined,
                                    color: Colors.black),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  child:
                                  const Icon(Icons.close, color: Colors.black, size: 18),
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
                            'MaroMart, the easy way for people to buy, sell, and connect with each other.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.85),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 24),

                          _GlassField(
                            controller: _fullNameController,
                            hint: 'Fullname...',
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Fullname is required' : null,
                          ),
                          const SizedBox(height: 14),
                          _GlassField(
                            controller: _emailController,
                            hint: 'Email...',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.trim().isEmpty ?? true) return 'Email is required';
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _GlassField(
                            controller: _phoneController,
                            hint: 'Phone...',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 14),

                          _GenderSelectionField(
                            value: _selectedGender,
                            items: _genders,
                            onChanged: (newValue) {
                              setState(() {
                                _selectedGender = newValue;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit, // Gọi hàm submit
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
                              child: const Text('Next →'),
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
  final TextInputType? keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  const _GlassField({
    required this.hint,
    this.obscure = false,
    this.keyboardType,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField( // Dùng TextFormField để có validation
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.25),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: _border(),
        focusedBorder: _border(),
        errorBorder: _border(isError: true), // Thêm error border
        focusedErrorBorder: _border(isError: true),
      ),
    );
  }

  OutlineInputBorder _border({bool isError = false}) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(28),
    borderSide: isError
        ? const BorderSide(color: Colors.red, width: 1.5)
        : BorderSide.none,
  );
}



class _GenderSelectionField extends StatelessWidget {
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _GenderSelectionField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểu dáng container tương tự _GlassField
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(28),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(
            'Gender...',
            style: TextStyle(color: Colors.white.withOpacity(0.75)),
          ),
          icon: const Icon(HeroiconsOutline.chevronDown, color: Colors.white, size: 18),
          dropdownColor: Colors.black.withOpacity(0.7), // Màu nền dropdown
          style: const TextStyle(color: Colors.white, fontSize: 16),
          isExpanded: true,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}