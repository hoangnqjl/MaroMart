class ApiConstants {
  // static const String baseUrl = 'https://maromart-server-version-01.onrender.com';
  static const String baseUrl = 'http://172.20.10.3:5000';

  // auth
  static const String loginEndpoint = '/auth/v1/login';
  static const String registerEndpoint = '/auth/v1/register';

  // product
  static const String productsBaseEndpoint = '/products';
  static String productsByIdEndpoint(String id) => '/products/$id';
  static const String productsFilterEndpoint = '/products/filter-product';


  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String roleKey = 'user_role';
}