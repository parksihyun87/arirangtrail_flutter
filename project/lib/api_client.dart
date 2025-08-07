// api_client.dart
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  final String _baseUrl = 'http://arirangtrail.duckdns.org/';

  // AuthProvider 참조 (import 없이 dynamic으로 처리)
  dynamic _authProvider;
  bool _isRefreshing = false;

  // 싱글톤 생성자
  ApiClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
    _setupInterceptors();
  }

  // 싱글톤 인스턴스 생성
  static ApiClient getInstance() {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  // AuthProvider 주입 (의존성 주입)
  void setAuthProvider(dynamic authProvider) {
    _authProvider = authProvider;
  }

  // 인터셉터 설정
  void _setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        // skipAuth 옵션이 있는 요청은 인증 헤더를 추가하지 않음
        if (options.extra['skipAuth'] == true) {
          handler.next(options);
          return;
        }

        // AuthProvider로부터 최신 토큰 가져오기
        final token = await _getAccessTokenFromProvider();
        if (token != null) {
          // ✨ 핵심 수정: 토큰에 "Bearer "가 없으면 붙여주고, 있으면 그대로 사용
          if (token.startsWith('Bearer ')) {
            options.headers['Authorization'] = token;
          } else {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }

        // Content-Type 설정
        if (options.contentType == null) {
          if (options.data is FormData) {
            options.contentType = 'multipart/form-data';
          } else if (options.headers['Content-Type']?.contains('x-www-form-urlencoded') == true) {
            options.contentType = 'application/x-www-form-urlencoded';
          } else {
            options.contentType = 'application/json; charset=UTF-8';
          }
        }

        handler.next(options);
      },

      // 응답 인터셉터 - 토큰 만료 처리
      onError: (DioException error, ErrorInterceptorHandler handler) async {
        if (error.response?.statusCode == 456 && !_isRefreshing) {
          // 토큰 재발급 시도
          final newToken = await _refreshToken();
          if (newToken != null) {
            // 원래 요청 재시도
            final options = error.requestOptions;
            options.headers['Authorization'] = newToken;

            try {
              final response = await _dio.fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              // 재시도도 실패하면 원래 에러 전달
            }
          } else {
            // 리프레시 토큰도 만료된 경우 로그아웃 처리
            if (_authProvider != null && _authProvider.logout != null) {
              await _authProvider.logout();
            }
          }
        }
        handler.next(error);
      },
    ));
  }

  // AuthProvider로부터 토큰 가져오기
  Future<String?> _getAccessTokenFromProvider() async {
    // AuthProvider가 주입되었으면 AuthProvider에서 가져오기
    if (_authProvider != null) {
      try {
        if (_authProvider.isLoggedIn == true) {
          return _authProvider.token;  // accessToken 대신 token 사용
        }
      } catch (e) {
        print('AuthProvider에서 토큰 가져오기 실패: $e');
      }
    }

    // fallback: SharedPreferences에서 직접 가져오기
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // 토큰 재발급
  Future<String?> _refreshToken() async {
    if (_isRefreshing) return null;

    _isRefreshing = true;
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _dio.post(
        'api/reissue',
        options: Options(
          headers: {'Cookie': 'refresh=$refreshToken'},
          extra: {'skipAuth': true}, // 이 요청은 인증 인터셉터를 건너뛰기
        ),
      );

      if (response.statusCode == 200) {
        final newAccessToken = response.headers.value('authorization');
        if (newAccessToken != null) {
          // AuthProvider에 새 토큰 저장
          if (_authProvider != null && _authProvider.updateAccessToken != null) {
            try {
              await _authProvider.updateAccessToken(newAccessToken);
            } catch (e) {
              print('AuthProvider 토큰 업데이트 실패: $e');
              // fallback: SharedPreferences에 직접 저장
              await saveTokens(accessToken: newAccessToken);
            }
          } else {
            // AuthProvider가 없으면 SharedPreferences에 직접 저장
            await saveTokens(accessToken: newAccessToken);
          }
          return newAccessToken;
        }
      }
      return null;
    } catch (e) {
      print('토큰 재발급 실패: $e');
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<String?> _getRefreshToken() async {
    // AuthProvider에서 먼저 시도
    if (_authProvider != null) {
      try {
        if (_authProvider.isLoggedIn == true && _authProvider.refreshToken != null) {
          return _authProvider.refreshToken;
        }
      } catch (e) {
        print('AuthProvider에서 리프레시 토큰 가져오기 실패: $e');
      }
    }

    // fallback: SharedPreferences에서 가져오기
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  // === 기존 호환성을 위한 메서드들 ===
  Future<void> saveTokens({String? accessToken, String? refreshToken}) async {
    final prefs = await SharedPreferences.getInstance();
    if (accessToken != null) await prefs.setString('jwt_token', accessToken);
    if (refreshToken != null) await prefs.setString('refresh_token', refreshToken);
  }

  Future<String?> getAccessToken() async {
    return _getAccessTokenFromProvider();
  }

  Future<String?> getRefreshToken() async {
    return _getRefreshToken();
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
  }

  // 기존 코드와 호환성을 위한 reissueToken 메서드 (Response 타입으로 반환)
  Future<Response> reissueToken() async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) throw Exception("No refresh token");

    return await _dio.post(
      'api/reissue',
      options: Options(
        headers: {'Cookie': 'refresh=$refreshToken'},
        extra: {'skipAuth': true},
      ),
    );
  }

  // === API 메서드들 ===
  Future<Response> get(String endpoint, {Map<String, dynamic>? queryParameters}) async {
    return await _dio.get(endpoint, queryParameters: queryParameters);
  }

  Future<Response> post(String endpoint, {dynamic data}) async {
    return await _dio.post(endpoint, data: data);
  }

  Future<Response> postForm(String endpoint, Map<String, dynamic> data) async {
    return await _dio.post(
      endpoint,
      data: FormData.fromMap(data),
      options: Options(
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      ),
    );
  }

  Future<Response> put(String endpoint, {dynamic data}) async {
    return await _dio.put(endpoint, data: data);
  }

  Future<Response> delete(String endpoint) async {
    return await _dio.delete(endpoint);
  }
}

// 전역 인스턴스 (기존 코드와 호환성 유지)
final apiClient = ApiClient.getInstance();