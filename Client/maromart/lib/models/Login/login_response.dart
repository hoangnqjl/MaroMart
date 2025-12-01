import 'package:maromart/models/User/User.dart';


class LoginResponse {
  final String message;
  final String token;
  final User? user;

  LoginResponse({
    required this.message,
    required this.token,
    this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      token: json['token'] ?? '',
      user: json['user'] != null
          ? User.fromJson(json['user'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'token': token,
      'user': user?.toJson(),
    };
  }
}