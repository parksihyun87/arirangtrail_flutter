// auth_provider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// UserProfile 모델
class UserProfile {
  final String username;
  final String nickname;
  final String? imageUrl;

  UserProfile({required this.username, required this.nickname, this.imageUrl});

  Map<String, dynamic> toJson() =>
      {'username': username, 'nickname': nickname, 'imageUrl': imageUrl};

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
      username: json['username'],
      nickname: json['nickname'],
      imageUrl: json['imageUrl']);
}

class AuthProvider with ChangeNotifier {
  UserProfile? _userProfile;
  String? _token;       // 기존 이름 유지
  String? _refreshToken; // refreshToken 추가
  bool _isLoggedIn = false;

  DateTime? _expiresAt;
  Timer? _refreshTimer;

  // Getters - 기존 이름 유지하면서 ApiClient 호환
  UserProfile? get userProfile => _userProfile;
  String? get token => _token; // 기존 이름 유지
  String? get accessToken => _token; // ApiClient 호환용 (같은 값 반환)
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get userData => _userProfile?.toJson(); // ApiClient 호환용

  // --- 로그인 성공 시 호출되는 함수 (오버로드 추가) ---
  // 기존 방식 (기존 코드와의 호환성 유지)
  Future<void> login(UserProfile userProfile, String token, String refreshToken, int expiresIn) async {
    await loginWithTokens(
      accessToken: token,
      refreshToken: refreshToken,
      userData: userProfile.toJson(),
      expiresIn: expiresIn,
    );
  }

  // 공개 메서드로 토큰 수동 갱신 (이름 변경)
  Future<void> renewToken() async {
    await _refreshTokenInternal();
  }

  // 새로운 방식 (ApiClient와 호환)
  Future<void> loginWithTokens({
    required String accessToken,
    required String refreshToken,
    Map<String, dynamic>? userData,
    int? expiresIn,
  }) async {
    _token = accessToken;        // _accessToken -> _token
    _refreshToken = refreshToken;
    _isLoggedIn = true;

    // 사용자 프로필 설정
    if (userData != null) {
      try {
        _userProfile = UserProfile.fromJson(userData);
      } catch (e) {
        print('사용자 데이터 파싱 오류: $e');
      }
    }

    // 토큰 만료 시간 설정
    if (expiresIn != null) {
      _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
      _scheduleTokenRefresh();
    } else {
      // 기본값: 1시간
      _expiresAt = DateTime.now().add(const Duration(hours: 1));
      _scheduleTokenRefresh();
    }

    await _saveTokensToPrefs(accessToken, refreshToken);
    if (_userProfile != null) {
      await _saveProfileToPrefs(_userProfile!);
    }
    notifyListeners();
  }

  // --- 액세스 토큰만 업데이트 (ApiClient용) ---
  Future<void> updateAccessToken(String newAccessToken) async {
    _token = newAccessToken;      // _accessToken -> _token

    // SharedPreferences에도 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', newAccessToken);

    // 만료 시간 업데이트 (기본 1시간)
    _expiresAt = DateTime.now().add(const Duration(hours: 1));
    _scheduleTokenRefresh();

    notifyListeners();
  }

  // --- 토큰 자동 갱신 로직 ---
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    if (_expiresAt == null) return;

    final durationUntilRefresh = _expiresAt!.difference(DateTime.now()) - const Duration(minutes: 1);
    print("다음 토큰 갱신까지 남은 시간: $durationUntilRefresh");

    if (!durationUntilRefresh.isNegative) {
      _refreshTimer = Timer(durationUntilRefresh, () => _refreshTokenInternal());
    }
  }

  Future<void> _refreshTokenInternal() async {
    print("⏰ 웹소켓 유지를 위한 Access Token 선제적 갱신 시도...");
    try {
      // ApiClient의 refreshToken 메서드를 직접 호출하지 않고
      // 여기서 직접 구현 (순환 참조 방지)
      if (_refreshToken == null) {
        throw Exception("No refresh token available");
      }

      // 여기서는 dio를 직접 사용하거나 ApiClient의 저수준 메서드를 호출
      // 임시로 기존 방식 유지하되, 나중에 ApiClient와 조정 필요
      final prefs = await SharedPreferences.getInstance();
      final storedRefreshToken = prefs.getString('refresh_token') ?? _refreshToken;

      if (storedRefreshToken != null) {
        // 실제 API 호출 로직은 ApiClient와 협의하여 구현
        print("✅ 토큰 갱신 로직 실행 (ApiClient와 연동 필요)");

        // 임시로 1시간 연장
        _expiresAt = DateTime.now().add(const Duration(hours: 1));
        _scheduleTokenRefresh();
        notifyListeners();
      }
    } catch (e) {
      print("❌ 선제적 갱신 중 에러: $e");
      await logout();
    }
  }

  // --- 로그아웃 및 데이터 관리 ---
  Future<void> logout() async {
    _refreshTimer?.cancel();
    _userProfile = null;
    _token = null;               // _accessToken -> _token
    _refreshToken = null;
    _isLoggedIn = false;
    _expiresAt = null;

    await _clearAllData();
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString('jwt_token');        // _accessToken -> _token
    _refreshToken = prefs.getString('refresh_token');

    // 사용자 프로필 로드
    final profile = await _loadProfileFromPrefs();
    if (profile != null) {
      _userProfile = profile;
    }

    // 로그인 상태 확인
    if (_token != null && _refreshToken != null) {   // _accessToken -> _token
      _isLoggedIn = true;

      // 만료 시간 로드 및 토큰 갱신 스케줄링
      final expiresAtString = prefs.getString('expires_at');
      if (expiresAtString != null) {
        _expiresAt = DateTime.parse(expiresAtString);
        if (_expiresAt!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
          await _refreshTokenInternal();
        } else {
          _scheduleTokenRefresh();
        }
      } else {
        // 만료 시간 정보가 없으면 기본값으로 설정
        _expiresAt = DateTime.now().add(const Duration(hours: 1));
        _scheduleTokenRefresh();
      }
    }

    notifyListeners();
  }

  // --- 사용자 정보 업데이트 (ApiClient 호환용) ---
  Future<void> updateUserData(Map<String, dynamic> userData) async {
    try {
      _userProfile = UserProfile.fromJson(userData);
      await _saveProfileToPrefs(_userProfile!);
      notifyListeners();
    } catch (e) {
      print('사용자 데이터 업데이트 오류: $e');
    }
  }

  // --- Private 메서드들 ---
  Future<void> _saveTokensToPrefs(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> _saveProfileToPrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
    if (_expiresAt != null) {
      await prefs.setString('expires_at', _expiresAt!.toIso8601String());
    }
  }

  Future<UserProfile?> _loadProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileString = prefs.getString('user_profile');
    if (profileString != null) {
      try {
        return UserProfile.fromJson(jsonDecode(profileString));
      } catch (e) {
        print('사용자 프로필 로드 오류: $e');
      }
    }
    return null;
  }

  Future<void> _clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_profile');
    await prefs.remove('expires_at');
  }
}