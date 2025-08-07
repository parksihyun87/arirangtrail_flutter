// LoginPage.dart (전체 리팩토링 완료)

import 'package:dio/dio.dart'; // DioException을 사용하기 위해 임포트
import 'package:flutter/material.dart';
import 'package:project/provider/auth_provider.dart';
import 'package:project/user/simple_join.dart';
import 'package:provider/provider.dart';
import '../api_client.dart'; // 전역 apiClient 사용
import 'join_page.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- 일반 로그인 메서드 ---
  Future<void> _performLogin() async {
    // buildContext가 유효할 때만 실행되도록 체크
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
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
      // ApiClient에 정의된 postForm 메서드 사용
      final response = await apiClient.postForm('api/login', {
        'username': username,
        'password': password,
      });

      if (response.statusCode == 200) {
        final responseData = response.data; // dio는 자동으로 json을 파싱
        final accessToken = response.headers.value('authorization');
        final setCookieHeader = response.headers.value('set-cookie');

        String? refreshToken;
        if (setCookieHeader != null) {
          final cookie = setCookieHeader
              .split(';')
              .firstWhere((c) => c.trim().startsWith('refresh='), orElse: () => '');
          if (cookie.isNotEmpty) {
            refreshToken = cookie.split('=').last;
          }
        }

        if (accessToken == null || refreshToken == null) {
          throw Exception('서버로부터 토큰 정보를 받지 못했습니다.');
        }

        final int expiresIn = responseData['expiresIn'];
        final userProfile = UserProfile.fromJson(responseData);

        if (mounted) {
          await authProvider.login(
              userProfile, accessToken, refreshToken, expiresIn);

          _showResultDialog(
              title: l10n.loginSuccess,
              content: l10n.welcomeMessage(userProfile.nickname),
              onConfirm: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst));
        }
      }
      // dio는 2xx가 아닌 경우 예외를 발생시키므로 else 블록은 사실상 필요 없습니다.
      // 예외 처리는 catch 블록에서 처리됩니다.
    } on DioException catch (e) {
      String errorMessage = l10n.loginFailedMessage;
      // 서버가 보낸 에러 메시지가 있으면 그것을 사용
      if (e.response?.data != null && e.response!.data is Map) {
        errorMessage = e.response!.data['error'] ?? errorMessage;
      }
      _showResultDialog(title: l10n.loginFailed, content: errorMessage);
    } catch (e) {
      // DioException이 아닌 다른 예외 처리
      _showResultDialog(title: l10n.loginFailed, content: e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // --- OAuth 로그인 메서드 ---
  Future<void> _performOauthLogin(String provider) async {
    if (!mounted) return;
    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
          'http://arirangtrail.duckdns.org/oauth2/authorization/$provider?state=client_type=app');
      final result = await FlutterWebAuth2.authenticate(
        url: url.toString(),
        callbackUrlScheme: "arirangtrail",
      );
      final uri = Uri.parse(result);

      // [시나리오 1] 로그인/회원가입 콜백 성공
      if (uri.host == 'oauth-callback') {
        final code = uri.queryParameters['code'];
        if (code == null) throw Exception('로그인 콜백을 받았지만 인증 코드가 없습니다.');

        print("로그인 콜백 수신! 인증 코드: $code");

        // apiClient.post 호출 시 data: 파라미터 사용
        final response = await apiClient.post(
          'api/app/login',
          data: {'code': code},
        );

        if (response.statusCode == 200) {
          final responseData = response.data;

          final userProfileData = responseData['userProfile'];
          final accessToken = responseData['accessToken'];
          final refreshToken = responseData['refreshToken'];
          final expiresIn = responseData['expiresIn'];

          if (userProfileData == null || accessToken == null || refreshToken == null || expiresIn == null) {
            throw Exception('서버 응답에 필수 데이터가 누락되었습니다.');
          }

          final userProfile = UserProfile.fromJson(userProfileData);

          await authProvider.login(
            userProfile,
            accessToken,
            refreshToken,
            expiresIn,
          );

          print("✅ 로그인 성공 및 AuthProvider 상태 업데이트 완료!");
          _showResultDialog(
              title: l10n.loginSuccess,
              content: l10n.welcomeMessage(userProfile.nickname),
              onConfirm: () => Navigator.of(context).popUntil((route) => route.isFirst)
          );
        }
      }
      // [시나리오 2] 간편 회원가입으로 이동
      else if (uri.host == 'simplejoin') {
        final email = uri.queryParameters['email'];
        final username = uri.queryParameters['username'];

        print("신규 회원입니다. 회원가입 페이지로 이동합니다. 이메일: $email, 이름: $username");
        if(email != null && username != null){
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SimpleJoin(email: email, username: username),
          ));
        }
      }
      // [시나리오 3] 예상치 못한 경로
      else {
        throw Exception('알 수 없는 콜백 URL입니다: $result');
      }
    } on DioException catch (e) {
      // 서버에서 보낸 에러 메시지를 우선적으로 표시
      _showResultDialog(
          title: l10n.loginFailed,
          content: e.response?.data?['error'] ?? l10n.loginFailedMessage);
    } catch (e) {
      // 웹 인증 취소 등 기타 예외 처리
      print("❌ 로그인 처리 중 오류 발생: $e");
      // 사용자가 웹뷰를 닫는 등의 행동은 오류 메시지를 보여주지 않을 수 있습니다.
      // 여기서는 일단 실패 메시지를 보여줍니다.
      _showResultDialog(
        title: l10n.loginFailed,
        content: l10n.loginFailedMessage,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 결과 다이얼로그 ---
  void _showResultDialog({required String title, required String content, VoidCallback? onConfirm}) {
    if (!mounted) return;
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

  // --- 위젯 빌드 ---
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
            ),
            const SizedBox(height: 20),
            _buildOauthButton('google'),
            const SizedBox(height: 10),
            _buildOauthButton('naver'),
            const SizedBox(height: 10),
            _buildOauthButton('kakao'),
          ],
        ),
      ),
    );
  }

  // --- OAuth 버튼 빌더 ---
  Widget _buildOauthButton(String provider) {
    // 기준이 될 버튼의 크기를 상수로 정의합니다.
    const double buttonWidth = 230.0;
    const double buttonHeight = 50.0;

    final BorderRadius borderRadius = BorderRadius.circular(buttonHeight / 2);

    switch (provider) {
      case 'google':
        return SizedBox(
          width: buttonWidth,
          height: buttonHeight,
          child: ElevatedButton.icon(
            onPressed: () => _performOauthLogin(provider),
            icon: Image.asset('assets/google_login.png', height: 24.0),
            label: const Text('Start with Google'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              // shape 속성을 명시적으로 지정하여 확실하게 알약 모양으로 만듭니다.
              shape: const StadiumBorder(),
            ),
          ),
        );
      case 'naver':
      // ClipRRect로 감싸서 둥근 모서리를 적용합니다.
        return ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: GestureDetector(
              onTap: () => _performOauthLogin(provider),
              child: Image.asset(
                'assets/naver_login.png',
                // cover를 사용하면 비율을 유지하면서 공간을 꽉 채웁니다 (추천).
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      case 'kakao':
      // 카카오 버튼에도 동일하게 적용합니다.
        return ClipRRect(
          borderRadius: borderRadius,
          child: SizedBox(
            width: buttonWidth,
            height: buttonHeight,
            child: GestureDetector(
              onTap: () => _performOauthLogin(provider),
              child: Image.asset(
                'assets/kakao_login.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      default:
        return const SizedBox(
          width: buttonWidth,
          height: buttonHeight,
        );
    }
  }
}