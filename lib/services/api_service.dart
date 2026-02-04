import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use production URL (Coolify deployment)
  static const String _productionUrl = 'https://backend.yaztrans.com';

  static String get baseUrl {
    // Override for development if needed, but default to production as requested
    const bool useProduction = true;

    if (useProduction) return _productionUrl;

    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer \$token',
    };
  }

  Future<dynamic> get(String endpoint) async {
    try {
      final url = '$baseUrl$endpoint';
      debugPrint('API GET: $url');
      final headers = await _getHeaders();
      debugPrint('Headers: $headers');
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      debugPrint('Response status: ${response.statusCode}');

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API GET error for $endpoint: $e');
      throw Exception('Network error: $e');
    }
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('\$baseUrl\$endpoint'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      return _handleResponse(response);
    } catch (e) {
      throw Exception('Network error: \$e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: \${response.statusCode} - \${response.body}');
    }
  }
}
