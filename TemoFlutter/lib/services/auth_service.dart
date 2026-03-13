
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:maromart/models/Login/login_request.dart';
import 'package:maromart/models/Login/login_response.dart';
import 'package:maromart/models/User/User.dart';
import 'package:maromart/utils/constants.dart';
import 'package:maromart/utils/storage.dart';

import 'api_service.dart';

class AuthService {
  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final request = LoginRequest(email: email, password: password);

      final response = await _apiService.post(
        endpoint: ApiConstants.loginEndpoint,
        body: request.toJson(),
        needAuth: false,
      );

      final String token = response['token'] as String;

      await StorageHelper.saveToken(token);

      final userInfo = _parseJWT(token);

      String finalUserId = '';
      String finalRole = 'user';

      if (userInfo.containsKey('userId')) {
        final userIdData = userInfo['userId'];

        if (userIdData is String && userIdData.contains('{')) {
          try {
            final nestedMap = jsonDecode(userIdData);
            finalUserId = nestedMap['userId']?.toString() ?? '';
            finalRole = nestedMap['role']?.toString() ?? 'user';
          } catch (e) {
            print('Lỗi parse JSON lồng: $e');
          }
        } else {
          finalUserId = userIdData.toString();
          if (userInfo.containsKey('role')) {
            finalRole = userInfo['role'].toString();
          }
        }
      }


      if (finalUserId.isEmpty) {
        throw Exception('Token không chứa userId hợp lệ');
      }

      await StorageHelper.saveUserInfo(
        userId: finalUserId,
        role: finalRole,
      );

      final loginResponse = LoginResponse.fromJson(response);
      return loginResponse;

    } catch (e) {
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }


  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception('Đăng nhập Google bị hủy');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (googleAuth.idToken == null) {
        throw Exception('Không lấy được ID Token từ Google');
      }

      print('Google ID Token: ${googleAuth.idToken}');
      print('Google Email: ${googleUser.email}');
      print('Google Name: ${googleUser.displayName}');

      // 3. Gửi idToken lên server
      final response = await _apiService.post(
        endpoint: '/auth/login/google',
        body: {
          'idToken': googleAuth.idToken,
        },
        needAuth: false,
      );

      print('Response from server: $response');

      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'];

        if (userData['token'] != null) {
          await StorageHelper.saveToken(userData['token']);
        }

        await StorageHelper.saveUserInfo(
          userId: userData['userId']?.toString() ?? '',
          role: userData['role']?.toString() ?? 'user',
          fullName: userData['fullName']?.toString(),
          email: userData['email']?.toString(),
        );

        final user = User.fromJson(userData);
        await StorageHelper.saveUser(user);

        return response;
      }

      throw Exception('Đăng nhập thất bại');

    } catch (e) {
      print('Google Sign In Error: $e');

      await _googleSignIn.signOut();

      throw Exception('Đăng nhập Google thất bại: ${e.toString()}');
    }
  }

  // Đăng xuất Google
  Future<void> signOutGoogle() async {
    try {
      await signOutGoogle();
      await _googleSignIn.signOut();
    } catch (e) {
      print('Lỗi đăng xuất Google: $e');
    }
  }
  // Đăng ký
  Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    int? phoneNumber,
    required String password,
  }) async {
    try {
      final body = <String, dynamic>{
        'fullName': fullName,
        'email': email,
        'password': password,
      };

      if (phoneNumber != null && phoneNumber != 0) {
        body['phoneNumber'] = phoneNumber;
      }

      final response = await _apiService.post(
        endpoint: ApiConstants.registerEndpoint,
        body: body,
        needAuth: false,
      );

      print('Response: $response');

      return response;
    } catch (e) {
      print('Register Error: $e');
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    try {
      await StorageHelper.clearAll();
    } catch (e) {
      await StorageHelper.clearAll();
    }
  }

  // Refresh token
  Future<String> refreshToken() async {
    try {
      final currentToken = StorageHelper.getToken();
      if (currentToken == null) {
        throw Exception('Không có token');
      }

      final response = await _apiService.post(
        endpoint: '/auth/refresh',
        body: {'token': currentToken},
        needAuth: false,
      );

      final newToken = response['token'] ?? response['accessToken'];
      if (newToken != null) {
        await StorageHelper.saveToken(newToken);
        return newToken;
      }

      throw Exception('Không nhận được token mới');
    } catch (e) {
      throw Exception('Refresh token thất bại: ${e.toString()}');
    }
  }

  // Đổi mật khẩu
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        endpoint: '/auth/change-password',
        body: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
        needAuth: true,
      );
    } catch (e) {
      throw Exception('Đổi mật khẩu thất bại: ${e.toString()}');
    }
  }

  // Quên mật khẩu
  Future<void> forgotPassword(String email) async {
    try {
      await _apiService.post(
        endpoint: '/auth/forgot-password',
        body: {'email': email},
        needAuth: false,
      );
    } catch (e) {
      throw Exception('Gửi email thất bại: ${e.toString()}');
    }
  }

  // Reset mật khẩu với token
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    try {
      await _apiService.post(
        endpoint: '/auth/reset-password',
        body: {
          'token': token,
          'newPassword': newPassword,
        },
        needAuth: false,
      );
    } catch (e) {
      throw Exception('Reset mật khẩu thất bại: ${e.toString()}');
    }
  }

  bool isTokenValid() {
    final token = StorageHelper.getToken();
    if (token == null) return false;

    try {
      final payload = _parseJWT(token);
      final exp = payload['exp'];

      if (exp == null) return true;

      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return DateTime.now().isBefore(expiryDate);
    } catch (e) {
      return false;
    }
  }

  Map<String, dynamic> _parseJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Invalid token format');
      }

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);

      return payloadMap;
    } catch (e) {
      return {};
    }
  }

}