import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:project/provider/auth_provider.dart';
import 'package:project/user/simple_join.dart';
import 'package:provider/provider.dart';
import '../api_client.dart';
import '../provider/auth_provider.dart';
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

  Future<void> _performLogin() async {
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
      // 1. ApiClient를 사용하여 로그인 API 호출 (이 부분은 이전과 동일)
      final response = await apiClient.postForm('api/login', {
        'username': username,
        'password': password
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        final accessToken = response.headers['authorization'];

        // 2. Refresh Token 파싱
        String? refreshToken;
        final setCookieHeader = response.headers['set-cookie'];
        if (setCookieHeader != null) {
          final cookie = setCookieHeader.split(';').firstWhere((c) => c.trim().startsWith('refresh='));
          refreshToken = cookie.split('=').last;
        }

        if (accessToken == null || refreshToken == null) {
          throw Exception('서버로부터 토큰 정보를 받지 못했습니다.');
        }

        // ✨ 3. 서버가 보내준 expiresIn 값을 추출
        final int expiresIn = responseData['expiresIn'];

        final userProfile = UserProfile.fromJson(responseData);

        if (mounted) {
          // ✨ 4. AuthProvider.login에 expiresIn 값을 추가로 전달
          await authProvider.login(userProfile, accessToken, refreshToken, expiresIn);

          _showResultDialog(
              title: l10n.loginSuccess,
              content: l10n.welcomeMessage(userProfile.nickname),
              onConfirm: () => Navigator.of(context).popUntil((route) => route.isFirst)
          );
        }
      } else {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        throw Exception(errorData['error'] ?? '알 수 없는 오류가 발생했습니다.');
      }
    } catch (e) {
      _showResultDialog(
          title: l10n.loginFailed,
          content: e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _performOauthLogin(String provider) async {
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
      if (uri.host == 'oauth-callback') {
        final code = uri.queryParameters['code']; // 변수명을 token에서 code로 변경하여 명확화
        if (code != null) {
          print("로그인 콜백 수신! 인증 코드: $code");
          try {
            final response = await apiClient.post(
              'api/app/login',
              {'code': code},
            );

            // ✨ 서버로부터 200 OK 응답을 받았을 때 처리 로직
            if (response.statusCode == 200) {
              // 1. 응답 본문을 JSON 객체로 디코딩
              final responseData = jsonDecode(utf8.decode(response.bodyBytes));

              // 2. AuthProvider 인스턴스 가져오기
              // BuildContext가 사용 가능한 위치여야 합니다.
              // 사용 불가능한 경우, Provider를 다른 방식으로 가져와야 합니다.
              final authProvider = Provider.of<AuthProvider>(context, listen: false);

              // 3. 응답 데이터에서 정보 추출
              final userProfileData = responseData['userProfile'];
              final accessToken = responseData['accessToken'];
              final refreshToken = responseData['refreshToken'];
              final expiresIn = responseData['expiresIn']; // 초 단위 만료 시간

              // 4. 데이터 유효성 검사
              if (userProfileData == null || accessToken == null || refreshToken == null || expiresIn == null) {
                throw Exception('서버 응답에 필수 데이터가 누락되었습니다.');
              }

              // 5. UserProfile 객체 생성
              final userProfile = UserProfile.fromJson(userProfileData);

              // 6. AuthProvider의 login 메서드 호출하여 상태 업데이트 및 저장
              await authProvider.login(
                userProfile,
                accessToken,
                refreshToken,
                expiresIn,
              );

              print("✅ 로그인 성공 및 AuthProvider 상태 업데이트 완료!");
              // (옵션) 로그인 성공 후 홈 화면 등 다른 화면으로 이동
              _showResultDialog(
                  title: l10n.loginSuccess,
                  content: l10n.welcomeMessage(userProfile.nickname),
                  onConfirm: () => Navigator.of(context).popUntil((route) => route.isFirst)
              );

            } else {
              // 200이 아닌 다른 상태 코드 처리
              throw Exception('로그인에 실패했습니다. 상태 코드: ${response.statusCode}, 메시지: ${response.body}');
            }
          } catch (e) {
            // 네트워크 오류 또는 로직 처리 중 예외 발생 시
            print("❌ 로그인 처리 중 오류 발생: $e");
            // 사용자에게 오류 메시지 표시
            // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('로그인에 실패했습니다: $e')));
          }
        } else {
          throw Exception('로그인 콜백을 받았지만 인증 코드가 없습니다.');
        }
      }

      else if (uri.host == 'simplejoin') {
        final email = uri.queryParameters['email'];
        final username = uri.queryParameters['username'];

        print("신규 회원입니다. 회원가입 페이지로 이동합니다.");
        print("이메일: $email, 이름: $username");
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

    }catch(e){
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
              onPressed: () =>
                  Navigator.push(context,
                      MaterialPageRoute(
                          builder: (context) => const JoinPage())),
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
