import 'dart:convert';
import 'package:maromart/models/User/User.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageHelper {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      print("Error initializing SharedPreferences: $e");
      // Handle error accordingly, maybe set _prefs to null or retry
    }
  }

  static Future<bool> saveToken(String token) async {
    return await _prefs?.setString('auth_token', token) ?? false;
  }

  static String? getToken() {
    return _prefs?.getString('auth_token');
  }

  static Future<bool> clearToken() async {
    return await _prefs?.remove('auth_token') ?? false;
  }

  static Future<bool> saveUserInfo({
    required String userId,
    required String role,
    String? fullName,
    String? email,
  }) async {
    final results = await Future.wait([
      _prefs?.setString('user_id', userId) ?? Future.value(false),
      _prefs?.setString('user_role', role) ?? Future.value(false),
      if (fullName != null)
        _prefs?.setString('user_fullname', fullName) ?? Future.value(false),
      if (email != null)
        _prefs?.setString('user_email', email) ?? Future.value(false),
    ]);
    return results.every((result) => result == true);
  }

  static String? getUserId() => _prefs?.getString('user_id');
  static String? getUserRole() => _prefs?.getString('user_role');
  static String? getUserFullName() => _prefs?.getString('user_fullname');
  static String? getUserEmail() => _prefs?.getString('user_email');

  // --- FULL USER OBJECT (JSON) ---
  static Future<bool> saveUser(User user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await _prefs?.setString('user_data', userJson);

      if (user.userId.isNotEmpty) {
        await _prefs?.setString('user_id', user.userId);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  static User? getUser() {
    try {
      final userJson = _prefs?.getString('user_data');
      if (userJson == null) return null;
      final userMap = jsonDecode(userJson);
      return User.fromJson(userMap);
    } catch (e) {
      return null;
    }
  }

  // --- CHECK LOGIN ---
  static bool isLoggedIn() {
    final token = getToken();
    final userId = getUserId();
    // Phải có cả token và userId mới tính là đã login
    return token != null && token.isNotEmpty && userId != null && userId.isNotEmpty;
  }

  // --- CLEAR DATA (LOGOUT) ---
  static Future<bool> clearAll() async {
    return await _prefs?.clear() ?? false;
  }
}