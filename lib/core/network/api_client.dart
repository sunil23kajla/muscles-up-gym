import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_endpoints.dart';

class ApiClient {
  static String? _token;
  static void Function()? onSessionExpired;

  static void _logRequest(String method, String url, {dynamic body}) {
    print('━━━━━━━━━━━━━━━━━━━━ 🌐 API REQUEST ━━━━━━━━━━━━━━━━━━━━');
    print('🚀 Method: $method');
    print('🔗 URL: $url');
    if (body != null) {
      try {
        print('📦 Body: ${jsonEncode(body)}');
      } catch (_) {
        print('📦 Body: $body');
      }
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  static void _logResponse(http.Response response) {
    print('━━━━━━━━━━━━━━━━━━━━ 📥 API RESPONSE ━━━━━━━━━━━━━━━━━━━━');
    print('🎯 Status Code: ${response.statusCode}');
    print('🔗 URL: ${response.request?.url}');
    print('📦 Body: ${response.body}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // Set the Bearer authorization token globally
  static void setToken(String? token) {
    _token = token;
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // Handle Response Parsing and Exceptions
  static dynamic _processResponse(http.Response response) {
    _logResponse(response);
    final statusCode = response.statusCode;
    final body = response.body;

    dynamic jsonResponse;
    try {
      jsonResponse = jsonDecode(body);
    } catch (_) {
      jsonResponse = body;
    }

    if (statusCode >= 200 && statusCode < 300) {
      return jsonResponse;
    } else {
      if (statusCode == 401) {
        onSessionExpired?.call();
      }
      String errorMessage = 'Something went wrong';
      if (jsonResponse is Map && jsonResponse.containsKey('message')) {
        errorMessage = jsonResponse['message'];
      }
      throw ApiException(errorMessage, statusCode);
    }
  }

  // GET Request
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      String urlString = '${ApiEndpoints.baseUrl}$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(urlString).replace(queryParameters: queryParams);
        urlString = uri.toString();
      }

      _logRequest('GET', urlString);
      final uri = Uri.parse(urlString);
      final response = await http
          .get(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw ApiException('Connection timed out. Please ensure the backend server is running and reachable.', 408);
      }
      throw ApiException('Network connection failed. Please ensure your backend is started and reachable at port 5000.', 0);
    }
  }

  // POST Request
  Future<dynamic> post(String endpoint, dynamic body) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      _logRequest('POST', uri.toString(), body: body);
      final response = await http
          .post(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw ApiException('Connection timed out. Please ensure the backend server is running and reachable.', 408);
      }
      throw ApiException('Network connection failed. Please ensure your backend is started and reachable at port 5000.', 0);
    }
  }

  // PUT Request
  Future<dynamic> put(String endpoint, dynamic body) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      _logRequest('PUT', uri.toString(), body: body);
      final response = await http
          .put(
            uri,
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw ApiException('Connection timed out. Please ensure the backend server is running and reachable.', 408);
      }
      throw ApiException('Network connection failed. Please ensure your backend is started and reachable at port 5000.', 0);
    }
  }

  // DELETE Request
  Future<dynamic> delete(String endpoint) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      _logRequest('DELETE', uri.toString());
      final response = await http
          .delete(uri, headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw ApiException('Connection timed out. Please ensure the backend server is running and reachable.', 408);
      }
      throw ApiException('Network connection failed. Please ensure your backend is started and reachable at port 5000.', 0);
    }
  }

  // MULTIPART Request
  Future<dynamic> uploadMedia(String endpoint, String filePath, {String fieldName = 'media'}) async {
    try {
      final uri = Uri.parse('${ApiEndpoints.baseUrl}$endpoint');
      _logRequest('MULTIPART POST', uri.toString(), body: filePath);
      
      var request = http.MultipartRequest('POST', uri);
      
      // Add Authorization header manually because MultipartRequest headers are slightly different
      if (_token != null) {
        request.headers['Authorization'] = 'Bearer $_token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60)); // Larger timeout for videos
      final response = await http.Response.fromStream(streamedResponse);
      
      return _processResponse(response);
    } catch (e) {
      if (e is ApiException) rethrow;
      if (e is TimeoutException) {
        throw ApiException('Upload timed out. The file might be too large or connection is slow.', 408);
      }
      throw ApiException('Network connection failed during upload. $e', 0);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
