import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';


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
  bool _isLoggedIn = false; // ✨ isLoggedIn을 별도 변수로 관리

  // ApiClient는 이제 싱글톤을 사용합니다.
  // final ApiClient _apiClient = ApiClient(); // 더 이상 필요 없음

  UserProfile? get userProfile => _userProfile;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;

  // 로그인 성공 시 호출되는 함수
  Future<void> login(UserProfile userProfile, String token, String refreshToken) async {
    _userProfile = userProfile;
    _token = token;
    _isLoggedIn = true;

    // 토큰 저장은 ApiClient의 책임
    await apiClient.saveTokens(accessToken: token, refreshToken: refreshToken);
    await _saveProfileToPrefs(userProfile); // 프로필 저장은 여기서

    notifyListeners();
  }

  Future<void> logout() async {
    _userProfile = null;
    _token = null;
    _isLoggedIn = false;

    await apiClient.clearTokens(); // 토큰 삭제는 ApiClient에게 요청
    await _clearProfileFromPrefs();

    notifyListeners();
  }

  // 앱 시작 시 로그인 상태 복원
  Future<void> loadUserData() async {
    final storedToken = await apiClient.getAccessToken();
    final profile = await _loadProfileFromPrefs();

    if (storedToken != null && profile != null) {
      _token = storedToken;
      _userProfile = profile;
      _isLoggedIn = true;
    } else {
      _isLoggedIn = false;
    }
    notifyListeners();
  }

  // SharedPreferences 관련 헬퍼 메소드들
  Future<void> _saveProfileToPrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> _loadProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final profileString = prefs.getString('user_profile');
    return profileString != null ? UserProfile.fromJson(jsonDecode(profileString)) : null;
  }

  Future<void> _clearProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
  }
}