import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:maromart/models/Product/Product.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../utils/constants.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  final ValueNotifier<int> productChangeNotifier = ValueNotifier<int>(0);

  void notifyProductChanges() {
    productChangeNotifier.value++;
  }

  Future<Map<String, dynamic>?> getAISuggestion({
    required String productName,
    required String description,
    required String condition,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: '/attribute-suggestion',
        body: {
          "productName": productName,
          "description": description,
          "condition": condition,
        },
        needAuth: true,
      );

      if (response is Map<String, dynamic>) {
        return response;
      }
      return null;
    } catch (e) {
      print("Lỗi AI Suggestion: $e");
      return null;
    }
  }

  Future<List<Product>> getProducts({int page = 1, int limit = 10}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final dynamic response = await _apiService.get(
        endpoint: ApiConstants.productsBaseEndpoint,
        queryParameters: queryParams,
        needAuth: false,
      );

      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getProductsByCategory({String? categoryId}) async {
    try {
      Map<String, String> queryParams = {};

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }


      final response = await _apiService.get(
        endpoint: ApiConstants.productsFilterEndpoint,
        queryParameters: queryParams,
        needAuth: true,
      );

      // Parse kết quả
      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      }
      else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Lỗi lấy danh sách sản phẩm: $e');
    }
  }

  Future<List<Product>> getProductsByFilter({
    String? categoryId,
    String? province,
    String? ward,
  }) async {
    try {
      Map<String, String> queryParams = {};

      if (categoryId != null && categoryId.isNotEmpty) {
        queryParams['categoryId'] = categoryId;
      }
      if (province != null && province.isNotEmpty) {
        queryParams['province'] = province;
      }
      if (ward != null && ward.isNotEmpty) {
        queryParams['ward'] = ward;
      }

      final response = await _apiService.get(
        endpoint: ApiConstants.productsFilterEndpoint,
        queryParameters: queryParams,
        needAuth: true,
      );

      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }
      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Lỗi lọc sản phẩm: $e');
    }
  }

  Future<Product> getProductById(String productId) async {
    try {
      final endpoint = ApiConstants.productsByIdEndpoint(productId);

      final response = await _apiService.get(
        endpoint: endpoint,
        needAuth: false,
      );

      final productJson = response['data'] ?? response;
      return Product.fromJson(productJson as Map<String, dynamic>);

    } catch (e) {
      rethrow;
    }
  }

  Future<Product> createProduct({
    required Map<String, String> fields,
    List<XFile>? files,
  }) async {
    try {
      final response = await _apiService.postMultipart(
        endpoint: ApiConstants.productsBaseEndpoint,
        fields: fields,
        files: files,
        fileKey: 'productMedia',
        needAuth: true,
      );
      notifyProductChanges();
      final productJson = response['data'] ?? response;

      return Product.fromJson(productJson);

    } catch (e) {
      rethrow;
    }
  }

  Future<List<Product>> getUserProducts(String userId, {int page = 1, int limit = 10}) async {
    try {
      final queryParams = {
        'userId': userId,
        'page': page.toString(),
        'limit': limit.toString(),
      };

      final response = await _apiService.get(
        endpoint: ApiConstants.productsFilterEndpoint,
        queryParameters: queryParams,
        needAuth: true,
      );

      // Xử lý dữ liệu trả về
      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      throw Exception('Lỗi lấy sản phẩm của User: $e');
    }
  }

  Future<Product> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      final endpoint = ApiConstants.productsByIdEndpoint(productId);

      final response = await _apiService.put(
        endpoint: endpoint,
        body: productData,
        needAuth: true,
      );
      notifyProductChanges();
      final updatedProductJson = response['data'] ?? response;
      return Product.fromJson(updatedProductJson as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }


  Future<void> deleteProduct(String productId) async {
    try {
      final endpoint = ApiConstants.productsByIdEndpoint(productId);

      await _apiService.delete(
        endpoint: endpoint,
        needAuth: true,
      );
      notifyProductChanges();
    } catch (e) {
      rethrow;
    }
  }


  Future<List<Product>> filterProducts(Map<String, String> filters) async {
    try {
      final response = await _apiService.get(
        endpoint: ApiConstants.productsFilterEndpoint,
        queryParameters: filters,
        needAuth: false,
      );

      if (response['data'] is List) {
        final List<dynamic> productListJson = response['data'];

        return productListJson
            .map((json) => Product.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }
  Future<List<Product>> searchProducts(String keyword) async {
    try {
      final response = await _apiService.get(
        endpoint: '/products/search',
        queryParameters: {'q': keyword},
        needAuth: false,
      );

      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi tìm kiếm: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) return {'success': true};
      return jsonDecode(response.body);
    } else if (statusCode == 401) {
      throw Exception('Phiên đăng nhập hết hạn');
    } else if (statusCode >= 500) {
      throw Exception('Lỗi server ($statusCode)');
    } else {
      try {
        final error = jsonDecode(response.body);
        if (error is Map<String, dynamic>) {
          throw Exception(error['message'] ?? 'Có lỗi xảy ra');
        }
        throw Exception('Có lỗi xảy ra ($statusCode)');
      } catch (e) {
        throw Exception('Có lỗi xảy ra ($statusCode)');
      }
    }
  }
}