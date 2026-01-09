// lib/services/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/env_config.dart';

class ApiClient {
  static Future<ApiResponse> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(endpoint).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: headers)
          .timeout(EnvConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(EnvConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> put(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse(endpoint),
            headers: headers ?? {'Content-Type': 'application/json'},
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(EnvConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static Future<ApiResponse> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final response = await http
          .delete(Uri.parse(endpoint), headers: headers)
          .timeout(EnvConfig.requestTimeout);

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  static ApiResponse _handleResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(data);
      } else {
        final message = data['message'] ?? 'Request failed';
        return ApiResponse.error(message, statusCode: response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error(
        'Failed to parse response: ${e.toString()}',
        statusCode: response.statusCode,
      );
    }
  }
}

class ApiResponse {
  final bool success;
  final dynamic data;
  final String? error;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.statusCode,
  });

  factory ApiResponse.success(dynamic data) {
    return ApiResponse(
      success: true,
      data: data,
    );
  }

  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: message,
      statusCode: statusCode,
    );
  }

  // Helper to extract data from common response formats
  dynamic get extractedData {
    if (data is Map && data['success'] == true) {
      return data['data'];
    }
    return data;
  }
}

// Usage Example:
// 
// final response = await ApiClient.get(
//   EnvConfig.restaurants,
//   headers: ApiService.getUserHeaders(userId),
// );
// 
// if (response.success) {
//   final restaurants = response.extractedData;
//   // Use restaurants data
// } else {
//   print('Error: ${response.error}');
// }