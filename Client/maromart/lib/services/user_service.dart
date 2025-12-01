
import 'package:maromart/models/User/User.dart';
import 'package:maromart/utils/storage.dart';
import 'package:image_picker/image_picker.dart';

import 'api_service.dart';

class UserService {
  final ApiService _apiService = ApiService();

  Future<User> getUserById(String userId) async {
    try {
      final response = await _apiService.get(
        endpoint: '/users/$userId',
        needAuth: true,
      );

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Không thể lấy thông tin user: ${e.toString()}');
    }
  }

  Future<User> getCurrentUser() async {
    try {
      final userId = StorageHelper.getUserId();
      if (userId == null || userId.isEmpty) {
        throw Exception('Chưa đăng nhập');
      }

      return await getUserById(userId);
    } catch (e) {
      throw Exception('Không thể lấy thông tin user: ${e.toString()}');
    }
  }

  Future<User> updateUser({
    required String userId,
    String? fullName,
    int? phoneNumber,
    String? country,
    String? address,
    String? password,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (fullName != null && fullName.isNotEmpty) body['fullName'] = fullName;
      if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
      if (country != null) body['country'] = country;
      if (address != null) body['address'] = address;
      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await _apiService.put(
        endpoint: '/users/$userId',
        body: body,
        needAuth: true,
      );

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Cập nhật thất bại: ${e.toString()}');
    }
  }

  Future<User> changeAvatar(XFile imageFile) async {
    try {
      final userId = StorageHelper.getUserId();
      if (userId == null) throw Exception("Chưa đăng nhập");

      Map<String, String> fields = {
        'userId': userId,
      };

      final response = await _apiService.postMultipart(
        endpoint: '/upload/avatar',
        fields: fields,
        files: [imageFile],
        fileKey: 'avatar',
        needAuth: true,
      );

      final userData = response['data'] ?? response;
      final updatedUser = User.fromJson(userData);

      await StorageHelper.saveUser(updatedUser);

      return updatedUser;
    } catch (e) {
      throw Exception('Đổi avatar thất bại: ${e.toString()}');
    }
  }


  Future<List<User>> getAllUsers({
    int? page,
    int? limit,
    String? search,
  }) async {
    try {
      final queryParams = <String, String>{};

      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final response = await _apiService.get(
        endpoint: '/users',
        queryParameters: queryParams,
        needAuth: true,
      );

      final List<dynamic> usersJson = response['users'] ?? response['data'] ?? [];

      return usersJson.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Không thể lấy danh sách users: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _apiService.delete(
        endpoint: '/users/$userId',
        needAuth: true,
      );
    } catch (e) {
      throw Exception('Xóa user thất bại: ${e.toString()}');
    }
  }

  Future<User> toggleActiveStatus(String userId, bool isActive) async {
    try {
      final response = await _apiService.put(
        endpoint: '/users/$userId',
        body: {'isActive': isActive},
        needAuth: true,
      );

      return User.fromJson(response);
    } catch (e) {
      throw Exception('Cập nhật trạng thái thất bại: ${e.toString()}');
    }
  }

  User? getCurrentUserFromStorage() {
    return StorageHelper.getUser();
  }

  String? getCurrentUserId() {
    return StorageHelper.getUserId();
  }

  bool isAdmin() {
    final role = StorageHelper.getUserRole();
    return role?.toLowerCase() == 'admin';
  }

  bool isUser() {
    final role = StorageHelper.getUserRole();
    return role?.toLowerCase() == 'user';
  }
}