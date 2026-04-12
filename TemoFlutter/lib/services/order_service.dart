import 'api_service.dart';

class OrderService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createPurchaseRequest(String productId, String sellerId) async {
    try {
      final response = await _apiService.post(
        endpoint: '/orders/request',
        body: {
          'productId': productId,
          'sellerId': sellerId,
        },
        needAuth: true,
      );
      return response;
    } catch (e) {
      throw Exception('Gửi yêu cầu mua hàng thất bại: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> respondToRequest(String orderId, String status) async {
    try {
      final response = await _apiService.post(
        endpoint: '/orders/respond',
        body: {
          'orderId': orderId,
          'status': status,
        },
        needAuth: true,
      );
      return response;
    } catch (e) {
      throw Exception('Phản hồi yêu cầu thất bại: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getMyOrders() async {
    try {
      final response = await _apiService.get(
        endpoint: '/orders/my-orders',
        needAuth: true,
      );
      return response;
    } catch (e) {
      throw Exception('Lấy danh sách đơn hàng thất bại: ${e.toString()}');
    }
  }
}
