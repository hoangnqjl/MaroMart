import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:temo/models/Product/Product.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'api_service.dart';
import '../utils/constants.dart';
import '../utils/storage.dart';
import 'package:flutter/foundation.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  final ValueNotifier<int> productChangeNotifier = ValueNotifier<int>(0);

  void notifyProductChanges() {
    productChangeNotifier.value++;
  }

  // Global sync for saved products
  static final ValueNotifier<Set<String>> savedProductIdsNotifier = ValueNotifier<Set<String>>({});
  static bool _hasFetchedSaved = false;
  static bool _isFetchingSaved = false;

  Future<void> fetchSavedProductsIfNeeded() async {
    if (_hasFetchedSaved || _isFetchingSaved) return;
    
    // Check token via StorageHelper
    final token = StorageHelper.getToken();
    if (token == null) return;

    _isFetchingSaved = true;
    try {
      final response = await _apiService.get(endpoint: '/products/user/saved', needAuth: true);
      if (response != null && response is List) {
        final Set<String> savedIds = response.map((p) {
          if (p is Map && p['product'] != null) {
            return p['product']['productId']?.toString() ?? '';
          }
          return p['productId']?.toString() ?? '';
        }).where((id) => id.isNotEmpty).toSet();
        
        savedProductIdsNotifier.value = savedIds;
        _hasFetchedSaved = true;
      }
    } catch (e) {
      debugPrint("Error fetching saved products: $e");
    } finally {
      _isFetchingSaved = false;
    }
  }

  Future<void> toggleSave(String productId) async {
    final currentSaved = Set<String>.from(savedProductIdsNotifier.value);
    final isCurrentlySaved = currentSaved.contains(productId);

    // Optimistic Update
    if (isCurrentlySaved) {
      currentSaved.remove(productId);
    } else {
      currentSaved.add(productId);
    }
    savedProductIdsNotifier.value = currentSaved;

    try {
      final response = await _apiService.post(
        endpoint: '/products/$productId/save',
        body: {},
        needAuth: true,
      );
      
      if (response != null && response['isSaved'] != null) {
        final newSaved = Set<String>.from(savedProductIdsNotifier.value);
        if (response['isSaved'] == true) {
          newSaved.add(productId);
        } else {
          newSaved.remove(productId);
        }
        savedProductIdsNotifier.value = newSaved;
      }
    } catch (e) {
      // Revert on error
      final revertSaved = Set<String>.from(savedProductIdsNotifier.value);
      if (isCurrentlySaved) {
        revertSaved.add(productId);
      } else {
        revertSaved.remove(productId);
      }
      savedProductIdsNotifier.value = revertSaved;
      rethrow;
    }
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

  // --- NEW AI METHODS ---
  Future<Map<String, dynamic>> validateMedia(List<XFile> files, String productName, {List<String>? remoteUrls}) async {
    try {
      final Map<String, String> fields = {'productName': productName};
      if (remoteUrls != null && remoteUrls.isNotEmpty) {
          fields['remoteUrls'] = jsonEncode(remoteUrls);
      }

      final response = await _apiService.postMultipart(
        endpoint: '/ai/validate-media', // Đổi từ /products/ sang /ai/ cho đúng logic mới
        fields: fields,
        files: files,
        fileKey: 'files',
        needAuth: true,
      );
      return response['data'] ?? {};
    } catch (e) {
      throw Exception('Lỗi kiểm duyệt ảnh: $e');
    }
  }

  Future<Map<String, dynamic>> generateDetails({
    required String productName,
    required String visualDetails,
    String? style,
    String? length,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: '/ai/generate-details',
        body: {
          "productName": productName,
          "visualDetails": visualDetails,
          "style": style ?? "Professional",
          "length": length ?? "Medium"
        },
        needAuth: true,
      );
      return response['data'] ?? {};
    } catch (e) {
      throw Exception('Lỗi tạo chi tiết sản phẩm: $e');
    }
  }

  Future<Map<String, dynamic>> validateContent({
    required String productName,
    required String productDescription,
    required String category,
    required String type,
    required Map<String, dynamic> attributes,
  }) async {
    try {
      final response = await _apiService.post(
        endpoint: '/ai/validate-content',
        body: {
          "productName": productName,
          "productDescription": productDescription,
          "category": category,
          "type": type,
          "attributes": attributes
        },
        needAuth: true,
      );
      return response['data'] ?? {};
    } catch (e) {
      throw Exception('Lỗi kiểm tra nội dung: $e');
    }
  }
  // ----------------------

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

  Future<List<dynamic>> getCategories() async {
    try {
      final response = await _apiService.get(
        endpoint: '/categories',
        needAuth: false,
      );
      if (response is List) return response;
      if (response is Map && response['data'] is List) return response['data'];
      return [];
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
      return [];
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

      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
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

  Future<List<Product>> getUserProducts(String userId, {int page = 1, int limit = 10, String? status}) async {
    try {
      final queryParams = {
        'userId': userId,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;

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

  Future<Product> updateProductWithMedia(
      String productId,
      Map<String, String> fields,
      List<XFile>? files,
      ) async {
    try {
      final endpoint = ApiConstants.productsByIdEndpoint(productId);

      final response = await _apiService.putMultipart(
        endpoint: endpoint,
        fields: fields,
        files: files,
        fileKey: 'productMedia',
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

  Future<void> pushProduct(String productId, int days) async {
    try {
      await _apiService.post(
        endpoint: '/products/push',
        body: {'productId': productId, 'days': days},
        needAuth: true,
      );
      notifyProductChanges();
    } catch (e) {
      throw Exception('Đẩy tin thất bại: ${e.toString()}');
    }
  }

  Future<List<Product>> getRecommendedProducts({int limit = 10}) async {
    try {
      final response = await _apiService.get(
        endpoint: '/products/recommended',
        queryParameters: {'limit': limit.toString()},
        needAuth: false,
      );

      if (response is List) {
        return response.map((json) => Product.fromJson(json)).toList();
      } else if (response is Map && response['data'] is List) {
        return (response['data'] as List).map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Lỗi lấy sản phẩm đề xuất: $e');
    }
  }
}