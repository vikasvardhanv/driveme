import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yazdrive/utils/logger.dart';

class ApiService {
  // Use production URL (Coolify deployment)
  static const String _productionUrl = 'https://backend.yaztrans.com';

  static String get baseUrl => _productionUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      LogService().api('API GET: $url');
      final headers = await _getHeaders();
      LogService().api('Headers: $headers');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      LogService().api('Response status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      LogService().error('API GET error for $endpoint', e);
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final url = '$baseUrl$endpoint';
      LogService().api('API POST: $url');
      if (body != null) {
         // Sanitize body for logs (remove password)
         final sanitizedBody = Map<String, dynamic>.from(body as Map);
         if (sanitizedBody.containsKey('password')) sanitizedBody['password'] = '***';
         LogService().api('Body: $sanitizedBody');
      }

      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );
      
      LogService().api('Response status: ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      LogService().error('API POST error for $endpoint', e);
      throw Exception('Network error: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      LogService().error('API Error: ${response.statusCode} - ${response.body}');
      throw Exception('API Error: ${response.statusCode} - ${response.body}');
    }
  }
}
