import 'package:flutter/material.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';

class SignUpInfoScreen extends StatefulWidget {
  const SignUpInfoScreen({super.key});

  static const String kLogoAsset = ''; // Có thể thêm logo nếu cần

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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
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
                            child: const Icon(Icons.person_add_alt, color: Colors.black),
                          ),
                          InkWell(
                            onTap: () => Navigator.maybePop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(.9),
                              child: const Icon(Icons.close, size: 18, color: Colors.black),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Join MaroMart',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create an account to start buying and selling today.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF7A7A7A),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),

                      _RoundedField(
                        controller: _fullNameController,
                        hint: 'Full Name...',
                        icon: Icons.person_outline,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Fullname is required' : null,
                      ),
                      const SizedBox(height: 14),

                      _RoundedField(
                        controller: _emailController,
                        hint: 'Email...',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v?.trim().isEmpty ?? true) ? 'Email is required' : null,
                      ),
                      const SizedBox(height: 14),

                      _RoundedField(
                        controller: _phoneController,
                        hint: 'Phone (Optional)...',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),

                      // Gender Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.92),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            hint: const Row(
                              children: [
                                Icon(Icons.wc, size: 20, color: Colors.black54),
                                SizedBox(width: 12),
                                Text('Select Gender...', style: TextStyle(color: Colors.black54, fontSize: 16)),
                              ],
                            ),
                            icon: const Icon(Icons.arrow_drop_down, color: Colors.black54),
                            items: _genders.map((String item) {
                              return DropdownMenuItem<String>(
                                value: item,
                                child: Text(item),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedGender = val),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
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
    );
  }
}

// Widget Field tái sử dụng giống SignInScreen
class _RoundedField extends StatelessWidget {
  final TextEditingController? controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _RoundedField({
    this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
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
        prefixIcon: Icon(icon, size: 20, color: Colors.black54),
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