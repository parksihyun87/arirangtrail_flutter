// ApiClient.dart
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✨ 싱글톤(Singleton)으로 ApiClient 인스턴스를 관리합니다.
// 이렇게 하면 앱 전체에서 단 하나의 ApiClient만 사용하게 되어 상태 공유가 쉬워집니다.
final apiClient = ApiClient();

class ApiClient {
  final String _baseUrl = 'http://arirangtrail.duckdns.org/';
  // final String _baseUrl = 'http://10.0.2.2:8080';
  bool _isRefreshing = false;

  // === 토큰 관리 (SharedPreferences 접근) ===
  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) await prefs.setString('jwt_token', accessToken);
    if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  // === 헤더 생성 ===
  Future<Map<String, String>> _getHeaders({bool isForm = false}) async {
    final token = await getAccessToken();
    final headers = {
      'Content-Type': isForm ? 'application/x-www-form-urlencoded' : 'application/json; charset=UTF-8',
    };
    if (token != null) {
      headers['Authorization'] = token;
    }
    return headers;
  }

  // === 인터셉터 로직 ===
  Future<http.Response> _requestWithRetry(
      Future<http.Response> Function(Map<String, String> headers) requestFunction) async {

    var headers = await _getHeaders();
    http.Response response = await requestFunction(headers);

    if (response.statusCode == 456 && !_isRefreshing) {
      _isRefreshing = true;
      print("Access Token 만료! 재발급을 시도합니다...");

      try {
        final refreshResponse = await reissueToken();

        if (refreshResponse.statusCode == 200) {
          final newAccessToken = refreshResponse.headers['authorization'];
          if (newAccessToken != null) {
            print("토큰 재발급 성공! 원래 요청을 재시도합니다.");
            await saveTokens(accessToken: newAccessToken);

            // 새 토큰으로 헤더를 다시 만들어서 원래 요청 재시도
            headers = await _getHeaders();
            response = await requestFunction(headers);
          }
        } else {
          print("Refresh Token이 만료되었습니다. 로그아웃 처리합니다.");
          // TODO: AuthProvider의 logout 호출
        }
      } finally {
        _isRefreshing = false;
      }
    }
    return response;
  }

  Future<http.Response> reissueToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception("No refresh token");

    final uri = Uri.parse(_baseUrl).resolve('api/reissue'); // ✨ 수정

    return http.post(
        uri,
        headers: { 'Cookie': 'refresh=$refreshToken' }
    );
  }

  // === API 메소드들 ===

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse(_baseUrl).resolve(endpoint); // ✨ 수정
    return _requestWithRetry((headers) => http.get(uri, headers: headers));
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse(_baseUrl).resolve(endpoint); // ✨ 수정
    return _requestWithRetry((headers) => http.post(
      uri,
      headers: headers,
      body: jsonEncode(body),
    ));
  }

  Future<http.Response> postForm(String endpoint, Map<String, String> body) async {
    final uri = Uri.parse(_baseUrl).resolve(endpoint); // ✨ 수정
    return http.post(
      uri,
      headers: await _getHeaders(isForm: true),
      body: body,
    );
  }
}