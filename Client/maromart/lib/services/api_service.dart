import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import '../utils/storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class ApiService {
  Map<String, String> _getHeaders({bool needAuth = false}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (needAuth) {
      final token = StorageHelper.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> post({
    required String endpoint,
    required Map<String, dynamic> body,
    bool needAuth = false,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http.post(
        url,
        headers: _getHeaders(needAuth: needAuth),
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Không có kết nối internet');
    } on TimeoutException {
      throw Exception('Timeout - Vui lòng thử lại');
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }

  Future<dynamic> postMultipart({
    required String endpoint,
    required Map<String, String> fields,
    List<XFile>? files,
    String fileKey = 'productMedia',
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      var request = http.MultipartRequest('POST', url);

      if (needAuth) {
        final token = StorageHelper.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.fields.addAll(fields);

      if (files != null && files.isNotEmpty) {
        for (var xFile in files) {
          final bytes = await xFile.readAsBytes();
          final mimeType = lookupMimeType(xFile.name, headerBytes: bytes);

          MediaType? contentType;
          if (mimeType != null) {
            final split = mimeType.split('/');
            contentType = MediaType(split[0], split[1]);
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fileKey,
              bytes,
              filename: xFile.name,
              contentType: contentType,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(ApiConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);

    } on SocketException {
      throw Exception('Không có kết nối internet');
    } on TimeoutException {
      throw Exception('Timeout - Vui lòng thử lại');
    } catch (e) {
      throw Exception('Lỗi Upload: ${e.toString()}');
    }
  }

  Future<dynamic> postMultipartMultiKey({
    required String endpoint,
    required Map<String, String> fields,
    required Map<String, List<XFile>> fileMap,
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      var request = http.MultipartRequest('POST', url);

      if (needAuth) {
        final token = StorageHelper.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.fields.addAll(fields);

      for (var entry in fileMap.entries) {
        final fileKey = entry.key;
        final files = entry.value;

        for (var xFile in files) {
          final bytes = await xFile.readAsBytes();
          final mimeType = lookupMimeType(xFile.name, headerBytes: bytes);

          MediaType? contentType;
          if (mimeType != null) {
            final split = mimeType.split('/');
            contentType = MediaType(split[0], split[1]);
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fileKey,
              bytes,
              filename: xFile.name,
              contentType: contentType,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(ApiConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);

    } on SocketException {
      throw Exception('Không có kết nối internet');
    } on TimeoutException {
      throw Exception('Timeout - Vui lòng thử lại');
    } catch (e) {
      throw Exception('Lỗi Upload (MultiKey): ${e.toString()}');
    }
  }

  Future<dynamic> putMultipart({
    required String endpoint,
    required Map<String, String> fields,
    List<XFile>? files,
    String fileKey = 'productMedia',
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
      var request = http.MultipartRequest('PUT', url);

      if (needAuth) {
        final token = StorageHelper.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      request.fields.addAll(fields);

      if (files != null && files.isNotEmpty) {
        for (var xFile in files) {
          final bytes = await xFile.readAsBytes();
          final mimeType = lookupMimeType(xFile.name, headerBytes: bytes);

          MediaType? contentType;
          if (mimeType != null) {
            final split = mimeType.split('/');
            contentType = MediaType(split[0], split[1]);
          }

          request.files.add(
            http.MultipartFile.fromBytes(
              fileKey,
              bytes,
              filename: xFile.name,
              contentType: contentType,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(ApiConstants.connectTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);

    } on SocketException {
      throw Exception('Không có kết nối internet');
    } on TimeoutException {
      throw Exception('Timeout - Vui lòng thử lại');
    } catch (e) {
      throw Exception('Lỗi Update: ${e.toString()}');
    }
  }

  Future<dynamic> get({
    required String endpoint,
    Map<String, String>? queryParameters,
    bool needAuth = true,
  }) async {
    try {
      var url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      if (queryParameters != null && queryParameters.isNotEmpty) {
        url = url.replace(queryParameters: queryParameters);
      }

      final response = await http.get(
        url,
        headers: _getHeaders(needAuth: needAuth),
      ).timeout(ApiConstants.receiveTimeout);

      return _handleResponse(response);
    } on SocketException {
      throw Exception('Không có kết nối internet');
    } on TimeoutException {
      throw Exception('Timeout - Vui lòng thử lại');
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }

  Future<dynamic> put({
    required String endpoint,
    required Map<String, dynamic> body,
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http.put(
        url,
        headers: _getHeaders(needAuth: needAuth),
        body: jsonEncode(body),
      ).timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }

  Future<dynamic> delete({
    required String endpoint,
    bool needAuth = true,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');

      final response = await http.delete(
        url,
        headers: _getHeaders(needAuth: needAuth),
      ).timeout(ApiConstants.connectTimeout);

      return _handleResponse(response);
    } catch (e) {
      throw Exception('Lỗi: ${e.toString()}');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (e) {
      body = null;
    }

    if (statusCode >= 200 && statusCode < 300) {
      if (body == null) return {'success': true};
      return body;
    } else {
      String errorMessage = 'Có lỗi xảy ra ($statusCode)';

      if (body is Map<String, dynamic>) {
        if (body['message'] != null) {
          errorMessage = body['message'];
        }

        if (body['errors'] != null && body['errors'] is List) {
          final List errors = body['errors'];
          String detailErrors = errors.join('\n- ');
          errorMessage = "$errorMessage:\n- $detailErrors";
        }
      }

      if (statusCode == 401) {
        throw Exception('Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.');
      }

      throw Exception(errorMessage);
    }
  }
}