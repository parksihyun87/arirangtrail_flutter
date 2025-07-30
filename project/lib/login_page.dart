import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api_client.dart';
import 'auth_provider.dart';
import 'join_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final ApiClient _apiClient = ApiClient();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _performLogin() async {
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showResultDialog(title: '입력 오류', content: '아이디와 비밀번호를 모두 입력해주세요.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _apiClient.postForm('api/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final token =
            response.headers['authorization'] ?? responseData['accessToken'];

        if (token == null) {
          throw Exception('로그인에 성공했지만 토큰을 받지 못했습니다.');
        }

        final userProfile = UserProfile(
          username: responseData['username'] ?? username,
          nickname: responseData['nickname'] ?? '여행자 $username',
          imageUrl: responseData['imageUrl'] ?? 'assets/person.png',
        );

        // TODO: 안 읽은 메시지 개수 API 연동 (apiClient.get 사용)
        // final unreadCountResponse = await _apiClient.get('/chat/users/${userProfile.username}/unread-count');
        int totalUnreadCount = 0;

        if (mounted) {
          context.read<AuthProvider>().login(userProfile, token);
          context.read<AuthProvider>().updateTotalUnreadCount(totalUnreadCount);

          _showResultDialog(
            title: '로그인 성공',
            content: '${userProfile.nickname}님, 환영합니다!',
            onConfirm: () => Navigator.of(context).pop(),
          );
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '아이디 또는 비밀번호를 확인해주세요.');
      }
    } catch (e) {
      _showResultDialog(
          title: '로그인 실패', content: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showResultDialog(
      {required String title,
      required String content,
      VoidCallback? onConfirm}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm?.call();
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2d3748),
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Image.asset('assets/arirang1.png',
                height: 100,
                color: Colors.white,
                colorBlendMode: BlendMode.srcIn),
            const SizedBox(height: 40),
            TextField(
              controller: _usernameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: '아이디',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: '비밀번호',
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2d3748),
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isLoading ? null : _performLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('로그인'),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const JoinPage()));
              },
              child: const Text('새 계정 만들기 (회원가입)',
                  style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
