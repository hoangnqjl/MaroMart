import 'api_service.dart';

class ReviewService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> submitReview({
    required String orderId,
    required String revieweeId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: '/reviews/submit',
        body: {
          'orderId': orderId,
          'revieweeId': revieweeId,
          'rating': rating,
          'comment': comment,
        },
        needAuth: true,
      );
      return response;
    } catch (e) {
      throw Exception('Gửi đánh giá thất bại: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getUserReviews(String userId) async {
    try {
      final response = await _apiService.get(
        endpoint: '/reviews/user/$userId',
        needAuth: true,
      );
      return response as List<dynamic>;
    } catch (e) {
      throw Exception('Lấy đánh giá thất bại: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> getRatingSummary(String userId) async {
    try {
      final response = await _apiService.get(
        endpoint: '/reviews/summary/$userId',
        needAuth: true,
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching rating summary: $e');
      return {'averageRating': 0.0, 'totalReviews': 0};
    }
  }
}
