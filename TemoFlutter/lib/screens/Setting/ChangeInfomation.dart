import 'package:flutter/material.dart';
import 'package:maromart/components/ModernLoader.dart';
import 'package:maromart/Colors/AppColors.dart';
import 'package:maromart/components/TopBarSecond.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/services/user_service.dart';
import 'package:maromart/utils/storage.dart';

class ChangeInformationScreen extends StatefulWidget {
  const ChangeInformationScreen({super.key});

  @override
  State<ChangeInformationScreen> createState() => _ChangeInformationScreenState();
}

class _ChangeInformationScreenState extends State<ChangeInformationScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserService _userService = UserService();

  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _countryController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isUpdating = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _countryController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadCurrentUserInfo() {
    final user = _userService.getCurrentUserFromStorage();
    if (user != null) {
      _currentUser = user;
      _fullNameController.text = user.fullName;
      _phoneNumberController.text = (user.phoneNumber != null && user.phoneNumber != 0)
          ? user.phoneNumber.toString()
          : '';

      _countryController.text = user.country ?? '';
      _addressController.text = user.address ?? '';
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() => _isUpdating = true);

    try {
      final String userId = _currentUser!.userId;
      final String newFullName = _fullNameController.text.trim();
      final String rawPhoneNumber = _phoneNumberController.text.trim();

      final String newCountry = _countryController.text.trim();
      final String newAddress = _addressController.text.trim();

      final int? newPhoneNumber = rawPhoneNumber.isNotEmpty ? int.tryParse(rawPhoneNumber) : null;

      if (rawPhoneNumber.isNotEmpty && newPhoneNumber == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number must be valid digits!'), backgroundColor: Colors.red),
          );
        }
        setState(() => _isUpdating = false);
        return;
      }

      final updatedUser = await _userService.updateUser(
        userId: userId,
        fullName: newFullName,
        phoneNumber: newPhoneNumber,
        country: newCountry,
        address: newAddress,
      );

      await StorageHelper.saveUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Information successfully updated!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: ${e.toString().replaceAll('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const TopBarSecond(title: 'Change Information'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: ModernLoader())
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                controller: _fullNameController,
                hint: 'Full Name...',
                validator: (v) => (v?.isEmpty ?? true) ? 'Full Name is required' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _phoneNumberController,
                hint: 'Phone Number...',
                keyboardType: TextInputType.phone,
                validator: (v) {
                  if (v?.isEmpty ?? true) return null;
                  if (int.tryParse(v!) == null) return 'Must be a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _countryController,
                hint: 'Country (Optional)...',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _addressController,
                hint: 'Address (Optional)...',
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _handleUpdate,
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
                  child: _isUpdating
                      ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: const ModernLoader(color: Colors.white, size: 20)
                  )
                      : const Text('Change'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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