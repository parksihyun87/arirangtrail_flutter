import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'api_client.dart';
import 'join_page.dart';
import 'l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showResultDialog(
          title: l10n.inputError, content: l10n.errorEnterAllFields);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient
          .postForm('api/login', {'username': username, 'password': password});
      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final token =
            response.headers['authorization'] ?? responseData['accessToken'];
        if (token == null) throw Exception('로그인에 성공했지만 토큰을 받지 못했습니다.');
        final userProfile = UserProfile(
          username: responseData['username'] ?? username,
          nickname: responseData['nickname'] ?? '여행자 $username',
          imageUrl: responseData['imageUrl'] ?? 'assets/person.png',
        );
        if (mounted) {
          context.read<AuthProvider>().login(userProfile, token);
          _showResultDialog(
              title: l10n.loginSuccess,
              content: l10n.welcomeMessage(userProfile.nickname),
              onConfirm: () => Navigator.of(context).pop());
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['message'] ?? '아이디 또는 비밀번호를 확인해주세요.');
      }
    } catch (e) {
      _showResultDialog(
          title: l10n.loginFailed,
          content: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showResultDialog(
      {required String title,
      required String content,
      VoidCallback? onConfirm}) {
    final l10n = AppLocalizations.of(context)!;
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
                    child: Text(l10n.confirm))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFF2d3748),
      appBar: AppBar(
          title: Text(l10n.login),
          backgroundColor: Colors.transparent,
          elevation: 0),
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
                  labelText: l10n.username,
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                  labelText: l10n.password,
                  labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50)),
              onPressed: _isLoading ? null : _performLogin,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : Text(l10n.login),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const JoinPage())),
              child: Text(l10n.createNewAccount,
                  style: const TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
