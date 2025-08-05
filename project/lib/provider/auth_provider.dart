// AuthProvider.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/api_client.dart'; // 싱글톤 인스턴스 임포트
import 'package:shared_preferences/shared_preferences.dart';

import '../provider/auth_provider.dart';

// UserProfile 모델은 그대로
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
  String? _token;
  bool _isLoggedIn = false;

  DateTime? _expiresAt;
  Timer? _refreshTimer;

  UserProfile? get userProfile => _userProfile;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  // --- 로그인 성공 시 호출되는 함수 ---
  // ✨ 1. 파라미터에 int expiresIn을 추가하고, accessToken을 token으로 통일
  Future<void> login(UserProfile userProfile, String token, String refreshToken, int expiresIn) async {
    _userProfile = userProfile;
    _token = token; // ✨ accessToken -> token
    _isLoggedIn = true;

    // ✨ 2. expiresIn 파라미터를 사용하여 만료 시간 계산
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    _scheduleTokenRefresh();

    await apiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
    await _saveProfileToPrefs(userProfile);
    notifyListeners();
  }

  // --- 토큰 자동 갱신 로직 (수정 없음) ---
  void _scheduleTokenRefresh() {
    _refreshTimer?.cancel();
    if (_expiresAt == null) return;

    final durationUntilRefresh = _expiresAt!.difference(DateTime.now()) - const Duration(minutes: 1);
    print("다음 토큰 갱신까지 남은 시간: $durationUntilRefresh");

    if (!durationUntilRefresh.isNegative) {
      _refreshTimer = Timer(durationUntilRefresh, refreshToken);
    }
  }

  Future<void> refreshToken() async {
    print("⏰ 웹소켓 유지를 위한 Access Token 선제적 갱신 시도...");
    try {
      final response = await apiClient.reissueToken();
      if (response.statusCode == 200) {
        final newAccessToken = response.headers['authorization'];
        if (newAccessToken != null) {
          print("✅ 선제적 갱신 성공!");
          _token = newAccessToken;
          // 백엔드가 재발급 시에도 expiresIn을 보내준다면 그 값을 사용하는 것이 더 좋습니다.
          // 여기서는 기본값으로 1시간을 가정합니다.
          _expiresAt = DateTime.now().add(const Duration(hours: 1));
          _scheduleTokenRefresh();

          await apiClient.saveTokens(accessToken: newAccessToken);
          notifyListeners();
        }
      } else {
        print("❌ 선제적 갱신 실패. 로그아웃 처리합니다.");
        await logout();
      }
    } catch (e) {
      print("❌ 선제적 갱신 중 에러: $e");
      await logout();
    }
  }

  // --- 로그아웃 및 데이터 저장/로드 로직 ---
  Future<void> logout() async {
    _refreshTimer?.cancel();
    _userProfile = null;
    _token = null;
    _isLoggedIn = false;
    _expiresAt = null;

    await apiClient.clearTokens();
    await _clearProfileFromPrefs();
    notifyListeners();
  }

  Future<void> loadUserData() async {
    final storedToken = await apiClient.getAccessToken();
    final profile = await _loadProfileFromPrefs();

    if (storedToken != null && profile != null) {
      _token = storedToken;
      _userProfile = profile;
      _isLoggedIn = true;

      final expiresAtString = (await SharedPreferences.getInstance()).getString('expires_at');
      if (expiresAtString != null) {
        _expiresAt = DateTime.parse(expiresAtString);
        if (_expiresAt!.isBefore(DateTime.now().add(const Duration(minutes: 1)))) {
          await refreshToken();
        } else {
          _scheduleTokenRefresh();
        }
      }
      notifyListeners();
    }
  }

  Future<void> _saveProfileToPrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
    if (_expiresAt != null) {
      // ✨ 3. toIso822String -> toIso8601String 으로 오타 수정
      await prefs.setString('expires_at', _expiresAt!.toIso8601String());
    }
  }

  Future<UserProfile?> _loadProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileString = prefs.getString('user_profile');
    if (profileString != null) {
      // 'user_profile' 키에 저장된 JSON 문자열을 UserProfile 객체로 다시 변환하여 반환
      return UserProfile.fromJson(jsonDecode(profileString));
    }
    return null; // 저장된 정보가 없으면 null 반환
  }

  Future<void> _clearProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
    await prefs.remove('expires_at');
  }
}