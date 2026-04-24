import 'package:temo/components/FloatingHeader.dart';
import 'package:temo/utils/UIHelper.dart';
import 'package:heroicons_flutter/heroicons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:temo/components/ModernLoader.dart';
import 'package:temo/Colors/AppColors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:temo/components/TopBarSecond.dart';
import 'package:temo/models/User/User.dart';
import 'package:temo/services/user_service.dart';
import 'package:temo/utils/storage.dart';

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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _isLoading
                ? const SizedBox(
                    height: 300,
                    child: Center(child: ModernLoader()),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 120),
                  Center(
                    child: Text(
                      "Cập nhật thông tin",
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
                      "Vui lòng kiểm tra và cập nhật các thông tin bên dưới",
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                        _buildTextField(
                          controller: _fullNameController,
                          hint: 'Họ và tên...',
                          icon: HeroiconsOutline.user,
                          validator: (v) => (v?.isEmpty ?? true) ? 'Vui lòng nhập họ tên' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _phoneNumberController,
                          hint: 'Số điện thoại...',
                          icon: HeroiconsOutline.phone,
                          keyboardType: TextInputType.phone,
                          validator: (v) {
                            if (v?.isEmpty ?? true) return null;
                            if (int.tryParse(v!) == null) return 'Số điện thoại không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _countryController,
                          icon: HeroiconsOutline.globeAlt,
                          hint: 'Quốc gia...',
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          controller: _addressController,
                          icon: HeroiconsOutline.mapPin,
                          hint: 'Địa chỉ...',
                        ),
                        const SizedBox(height: 150),
                      ],
                    ),
                  ),
          ),
          
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
                    onPressed: _isUpdating ? null : _handleUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 8,
                      shadowColor: AppColors.primary.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: _isUpdating
                        ? const SizedBox(width: 20, height: 20, child: ModernLoader(color: Colors.white, size: 20))
                        : const Text('Cập nhật thông tin', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
            ),
          ),

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
                      onTap: () => UIHelper.showOptionsMenu(context, screenName: "Thông tin cá nhân"),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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