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
  bool _isLoggedIn = false;
  int _totalUnreadCount = 0;

  final ApiClient _apiClient = ApiClient();

  UserProfile? get userProfile => _userProfile;

  bool get isLoggedIn => _isLoggedIn;

  int get totalUnreadCount => _totalUnreadCount;

  // 로그인 시, UI 상태를 변경하고 토큰과 프로필 정보를 저장
  Future<void> login(UserProfile userProfile, String token) async {
    _userProfile = userProfile;
    _isLoggedIn = true;

    await _apiClient.saveToken(token);
    await _saveProfileToPrefs(userProfile);

    notifyListeners();
  }

  // 로그아웃 시, UI 상태를 초기화하고 저장된 정보를 모두 삭제
  Future<void> logout() async {
    _userProfile = null;
    _isLoggedIn = false;
    _totalUnreadCount = 0;

    await _apiClient.clearToken();
    await _clearProfileFromPrefs();

    notifyListeners();
  }

  // 앱 시작 시, 저장된 토큰과 프로필을 불러와 로그인 상태를 복원
  Future<void> loadUserData() async {
    final token = await _apiClient.getToken();
    final profile = await _loadProfileFromPrefs();

    if (token != null && profile != null) {
      _userProfile = profile;
      _isLoggedIn = true;
    }
    notifyListeners();
  }

  void updateTotalUnreadCount(int count) {
    _totalUnreadCount = count;
    notifyListeners();
  }

  Future<void> _saveProfileToPrefs(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_profile', jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> _loadProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String? profileString = prefs.getString('user_profile');
    return profileString != null
        ? UserProfile.fromJson(jsonDecode(profileString))
        : null;
  }

  Future<void> _clearProfileFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_profile');
  }
}
