class RegisterRequest {
  final String fullName;
  final String email;
  final int? phoneNumber;
  final String password;

  RegisterRequest({
    required this.fullName,
    required this.email,
    this.phoneNumber,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fullName': fullName,
      'email': email,
      'password': password,
    };

    // Chỉ thêm phoneNumber nếu không null
    if (phoneNumber != null) {
      data['phoneNumber'] = phoneNumber;
    }

    return data;
  }
}