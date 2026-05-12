class ApiConstants {
  // static const String baseUrl = 'https://temo-server.onrender.com';

  // static const String baseUrl = 'https://andrew.zapto.org/temo';

  static const String baseUrl = 'http://192.168.16.7:5100';

  // auth
  static const String loginEndpoint = '/auth/v1/login';
  static const String registerEndpoint = '/auth/v1/register';
  static const String forgotPasswordEndpoint = '/auth/v1/forgot-password';
  static const String changePasswordEndpoint = '/auth/v1/change-password';

  // product
  static const String productsBaseEndpoint = '/products';
  static String productsByIdEndpoint(String id) => '/products/$id';
  static const String productsFilterEndpoint = '/products/filter-product';

  // Timeout - Tăng lên 5 phút để AI có đủ thời gian xử lý ảnh và thuộc tính phức tạp
  static const Duration connectTimeout = Duration(seconds: 300);
  static const Duration receiveTimeout = Duration(seconds: 300);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String roleKey = 'user_role';
}
