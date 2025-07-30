import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  final String _baseUrl = 'http://arirangtrail.duckdns.org/';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  Future<Map<String, String>> _getHeaders({bool isForm = false}) async {
    final token = await getToken();
    final headers = {
      'Content-Type': isForm
          ? 'application/x-www-form-urlencoded'
          : 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = token;
    }
    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    return await http
        .get(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _getHeaders(),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    return await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
  }

  Future<http.Response> postForm(
      String endpoint, Map<String, String> body) async {
    return await http
        .post(
          Uri.parse('$_baseUrl$endpoint'),
          headers: await _getHeaders(isForm: true),
          body: body,
        )
        .timeout(const Duration(seconds: 30));
  }
}
