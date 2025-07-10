import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api';
  
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Future<Map<String, String>> get _headersWithAuth async {
    final token = await _getToken();
    return {
      ..._headers,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> _removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<ApiResponse<T>> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    try {
      final responseBody = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          if (responseBody['data'] != null) {
            return ApiResponse.success(fromJson(responseBody['data']));
          } else {
            // For endpoints that don't return data in the data field
            return ApiResponse.success(fromJson(responseBody));
          }
        } else {
          return ApiResponse.error(
            responseBody['message'] ?? 'Unknown error occurred',
            response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          responseBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        response.statusCode,
      );
    }
  }

  static Future<ApiResponse<List<T>>> _handleListResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
    String dataKey,
  ) async {
    try {
      final responseBody = json.decode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody['success'] == true) {
          final List<dynamic> dataList = responseBody['data'][dataKey] ?? [];
          final List<T> items = dataList
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.success(items, 
            pagination: responseBody['data']['pagination']);
        } else {
          return ApiResponse.error(
            responseBody['message'] ?? 'Unknown error occurred',
            response.statusCode,
          );
        }
      } else {
        return ApiResponse.error(
          responseBody['message'] ?? 'Request failed',
          response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: $e',
        response.statusCode,
      );
    }
  }

  // GET request
  static Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithQuery = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.get(uriWithQuery, headers: headers);
      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // GET request for lists
  static Future<ApiResponse<List<T>>> getList<T>(
    String endpoint,
    T Function(Map<String, dynamic>) fromJson,
    String dataKey, {
    Map<String, String>? queryParams,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final uriWithQuery = queryParams != null
          ? uri.replace(queryParameters: queryParams)
          : uri;

      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.get(uriWithQuery, headers: headers);
      return _handleListResponse(response, fromJson, dataKey);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // POST request
  static Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // PUT request
  static Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // PATCH request
  static Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data,
    T Function(Map<String, dynamic>) fromJson, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode(data),
      );

      return _handleResponse(response, fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // DELETE request
  static Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final headers = requireAuth ? await _headersWithAuth : _headers;

      final response = await http.delete(uri, headers: headers);
      return _handleResponse(response, (data) => data);
    } on SocketException {
      return ApiResponse.error('No internet connection', 0);
    } catch (e) {
      return ApiResponse.error('Network error: $e', 0);
    }
  }

  // Auth helpers
  static Future<void> saveAuthToken(String token) => _saveToken(token);
  static Future<void> clearAuthToken() => _removeToken();
  static Future<String?> getAuthToken() => _getToken();
}

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;
  final Map<String, dynamic>? pagination;

  ApiResponse.success(this.data, {this.pagination}) 
      : success = true, error = null, statusCode = 200;

  ApiResponse.error(this.error, this.statusCode) 
      : success = false, data = null, pagination = null;

  bool get isSuccess => success;
  bool get isError => !success;
}