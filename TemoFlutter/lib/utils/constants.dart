class ApiConstants {
  // static const String baseUrl = 'https://temo-server.onrender.com';

  static const String baseUrl = 'http://192.168.16.12:5000';

  // auth
  static const String loginEndpoint = '/auth/v1/login';
  static const String registerEndpoint = '/auth/v1/register';

  // product
  static const String productsBaseEndpoint = '/products';
  static String productsByIdEndpoint(String id) => '/products/$id';
  static const String productsFilterEndpoint = '/products/filter-product';

  // Timeout
  // Timeout - Tăng lên để AI có đủ thời gian xử lý ảnh
  static const Duration connectTimeout = Duration(seconds: 120);
  static const Duration receiveTimeout = Duration(seconds: 120);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String roleKey = 'user_role';
}
