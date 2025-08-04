// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:project/provider/auth_provider.dart';
// import 'package:provider/provider.dart';
// import '../api_client.dart';
// import 'join_page.dart';
// import '../l10n/app_localizations.dart';
// import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
//
// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});
//
//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }
//
// class _LoginPageState extends State<LoginPage> {
//   final _usernameController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _isLoading = false;
//
//   @override
//   void dispose() {
//     _usernameController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   // LoginPage.dart 안에
//
//   Future<void> _performLogin() async {
//     // 1. 필요한 객체들을 미리 준비합니다.
//     final authProvider = context.read<AuthProvider>();
//     final l10n = AppLocalizations.of(context)!;
//     final username = _usernameController.text;
//     final password = _passwordController.text;
//
//     // 2. 기본적인 입력값 검증
//     if (username.isEmpty || password.isEmpty) {
//       _showResultDialog(
//           title: l10n.inputError, content: l10n.errorEnterAllFields);
//       return;
//     }
//
//     // 3. 로딩 상태 시작
//     setState(() => _isLoading = true);
//
//     // 4. API 호출 및 결과 처리 (✨ 여기가 완전히 바뀝니다 ✨)
//     try {
//       // 4-1. 싱글톤 apiClient를 사용하여 로그인 API를 호출합니다.
//       final response = await apiClient.postForm('api/login', {
//         'username': username,
//         'password': password
//       });
//
//       // 4-2. 서버로부터 성공(200 OK) 응답을 받았을 경우
//       if (response.statusCode == 200) {
//         // 응답 본문(사용자 정보)과 헤더(토큰)를 파싱합니다.
//         final responseData = jsonDecode(utf8.decode(response.bodyBytes));
//         final accessToken = response.headers['authorization'];
//
//         // Refresh Token을 'set-cookie' 헤더에서 추출합니다.
//         String? refreshToken;
//         final setCookieHeader = response.headers['set-cookie'];
//         if (setCookieHeader != null) {
//           final cookie = setCookieHeader.split(';').firstWhere((c) => c.trim().startsWith('refresh='));
//           refreshToken = cookie.split('=').last;
//         }
//
//         // Access Token 또는 Refresh Token 둘 중 하나라도 없으면 에러로 간주합니다.
//         if (accessToken == null || refreshToken == null) {
//           throw Exception('서버로부터 토큰 정보를 받지 못했습니다.');
//         }
//
//         // 파싱한 정보로 UserProfile 객체를 만듭니다.
//         final userProfile = UserProfile.fromJson(responseData);
//
//         // 4-3. 모든 정보가 준비되면, AuthProvider의 login 함수를 호출하여 상태를 업데이트합니다.
//         if (mounted) {
//           await authProvider.login(userProfile, accessToken, refreshToken);
//
//           // 성공 다이얼로그를 보여줍니다.
//           _showResultDialog(
//               title: l10n.loginSuccess,
//               content: l10n.welcomeMessage(userProfile.nickname),
//               // 확인 버튼을 누르면 이전 화면으로 돌아갑니다 (보통 메인 화면)
//               onConfirm: () => Navigator.of(context).popUntil((route) => route.isFirst)
//           );
//         }
//       }
//       // 4-4. 서버로부터 실패 응답을 받았을 경우
//       else {
//         final errorData = jsonDecode(utf8.decode(response.bodyBytes));
//         // 서버가 보내준 에러 메시지를 사용합니다.
//         throw Exception(errorData['error'] ?? '알 수 없는 오류가 발생했습니다.');
//       }
//     } catch (e) {
//       // 4-5. API 호출 중 발생한 모든 종류의 에러를 여기서 처리합니다.
//       _showResultDialog(
//           title: l10n.loginFailed,
//           content: e.toString().replaceAll('Exception: ', ''));
//     } finally {
//       // 5. 성공하든 실패하든, 로딩 상태를 종료합니다.
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   Future<void> _performOauthLogin(String provider) async {
//     final l10n = AppLocalizations.of(context)!;
//     setState(() => _isLoading = true);
//     try {
//       final url = Uri.parse(
//           'http://arirangtrail.duckdns.org/oauth2/authorization/$provider');
//       final result = await FlutterWebAuth2.authenticate(
//         url: url.toString(),
//         callbackUrlScheme: "arirangtrail",
//       );
//       final uri = Uri.parse(result);
//       if (uri.path == '/oauth-callback') {
//         final token = uri.queryParameters['code'];
//         if (token != null) {
//           print("로그인 성공! 토큰: $token");
//         } else {
//           throw Exception('로그인 콜백을 받았지만 토큰이 없습니다.');
//         }
//       }
//
//       else if (uri.path == '/simplejoin') {
//         final email = uri.queryParameters['email'];
//         final name = uri.queryParameters['name'];
//
//         print("신규 회원입니다. 회원가입 페이지로 이동합니다.");
//         print("이메일: $email, 이름: $name");
//
//         // Navigator.of(context).push(MaterialPageRoute(
//         //   builder: (_) => SignUpPage(email: email, name: name),
//         // ));
//
//       }
//       // [시나리오 3] 예상치 못한 경로
//       else {
//         throw Exception('알 수 없는 콜백 URL입니다: $result');
//       }
//
//     }catch(e){
//       _showResultDialog(
//           title: l10n.loginFailed,
//           content: e.toString().replaceAll('Exception: ', ''));
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   void _showResultDialog(
//       {required String title,
//       required String content,
//       VoidCallback? onConfirm}) {
//     final l10n = AppLocalizations.of(context)!;
//     showDialog(
//         context: context,
//         builder: (context) => AlertDialog(
//               title: Text(title),
//               content: Text(content),
//               actions: [
//                 TextButton(
//                     onPressed: () {
//                       Navigator.of(context).pop();
//                       onConfirm?.call();
//                     },
//                     child: Text(l10n.confirm))
//               ],
//             ));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     return Scaffold(
//       backgroundColor: const Color(0xFF2d3748),
//       appBar: AppBar(
//           title: Text(l10n.login),
//           backgroundColor: Colors.transparent,
//           elevation: 0),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(32.0),
//         child: Column(
//           children: [
//             Image.asset('assets/arirang1.png',
//                 height: 100,
//                 color: Colors.white,
//                 colorBlendMode: BlendMode.srcIn),
//             const SizedBox(height: 40),
//             TextField(
//               controller: _usernameController,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                   labelText: l10n.username,
//                   labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _passwordController,
//               obscureText: true,
//               style: const TextStyle(color: Colors.white),
//               decoration: InputDecoration(
//                   labelText: l10n.password,
//                   labelStyle: TextStyle(color: Colors.white.withOpacity(0.7))),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                   minimumSize: const Size(double.infinity, 50)),
//               onPressed: _isLoading ? null : _performLogin,
//               child: _isLoading
//                   ? const CircularProgressIndicator()
//                   : Text(l10n.login),
//             ),
//             const SizedBox(height: 24),
//             TextButton(
//               onPressed: () => Navigator.push(context,
//                   MaterialPageRoute(builder: (context) => const JoinPage())),
//               child: Text(l10n.createNewAccount,
//                   style: const TextStyle(color: Colors.white)),
//             ),
//             const SizedBox(height: 20),
//             _buildOauthButton('google'),
//             const SizedBox(height: 10),
//             _buildOauthButton('naver'),
//             const SizedBox(height: 10),
//             _buildOauthButton('kakao'),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildOauthButton(String provider) {
//     // 기준이 될 버튼의 크기를 상수로 정의합니다.
//     const double buttonWidth = 230.0;
//     const double buttonHeight = 50.0;
//
//     final BorderRadius borderRadius = BorderRadius.circular(buttonHeight / 2);
//
//     switch (provider) {
//       case 'google':
//         return SizedBox(
//           width: buttonWidth,
//           height: buttonHeight,
//           child: ElevatedButton.icon(
//             onPressed: () => _performOauthLogin(provider),
//             icon: Image.asset('assets/google_login.png', height: 24.0),
//             label: const Text('Start with Google'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white,
//               foregroundColor: Colors.black,
//               // shape 속성을 명시적으로 지정하여 확실하게 알약 모양으로 만듭니다.
//               shape: const StadiumBorder(),
//             ),
//           ),
//         );
//       case 'naver':
//       // ClipRRect로 감싸서 둥근 모서리를 적용합니다.
//         return ClipRRect(
//           borderRadius: borderRadius,
//           child: SizedBox(
//             width: buttonWidth,
//             height: buttonHeight,
//             child: GestureDetector(
//               onTap: () => _performOauthLogin(provider),
//               child: Image.asset(
//                 'assets/naver_login.png',
//                 // cover를 사용하면 비율을 유지하면서 공간을 꽉 채웁니다 (추천).
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         );
//       case 'kakao':
//       // 카카오 버튼에도 동일하게 적용합니다.
//         return ClipRRect(
//           borderRadius: borderRadius,
//           child: SizedBox(
//             width: buttonWidth,
//             height: buttonHeight,
//             child: GestureDetector(
//               onTap: () => _performOauthLogin(provider),
//               child: Image.asset(
//                 'assets/kakao_login.png',
//                 fit: BoxFit.cover,
//               ),
//             ),
//           ),
//         );
//       default:
//         return const SizedBox(
//           width: buttonWidth,
//           height: buttonHeight,
//         );
//     }
//   }
// }
