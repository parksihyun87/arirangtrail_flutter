import 'package:flutter/material.dart';

class UserProfile {
  final String username;
  final String nickname;
  final String? imageUrl;

  UserProfile({
    required this.username,
    required this.nickname,
    this.imageUrl,
  });
}

class AuthProvider with ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoggedIn = false;
  int _totalUnreadCount = 0;

  UserProfile? get userProfile => _userProfile;

  bool get isLoggedIn => _isLoggedIn;

  int get totalUnreadCount => _totalUnreadCount;

  void login(String token, UserProfile userProfile) {
    _userProfile = userProfile;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _userProfile = null;
    _isLoggedIn = false;
    _totalUnreadCount = 0;
    notifyListeners();
  }

  void updateTotalUnreadCount(int count) {
    _totalUnreadCount = count;
    notifyListeners();
  }
}
