import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../provider/auth_provider.dart';

class DebugTokenScreen extends StatelessWidget {
  const DebugTokenScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JWT 토큰 디버그'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 로그인 상태 표시
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '로그인 상태',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('로그인됨: ${authProvider.isLoggedIn ? "예" : "아니오"}'),
                        if (authProvider.userProfile != null) ...[
                          Text('사용자명: ${authProvider.userProfile!.username}'),
                          Text('닉네임: ${authProvider.userProfile!.nickname}'),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // JWT 토큰 표시
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'JWT 토큰',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const Spacer(),
                            if (authProvider.token != null)
                              ElevatedButton(
                                onPressed: () {
                                  final token = authProvider.token!.startsWith('Bearer ')
                                      ? authProvider.token!
                                      : 'Bearer ${authProvider.token}';
                                  Clipboard.setData(
                                    ClipboardData(text: token),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('토큰이 클립보드에 복사되었습니다!'),
                                    ),
                                  );
                                },
                                child: const Text('복사'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (authProvider.token != null) ...[
                          Text('토큰 존재: 예'),
                          const SizedBox(height: 8),
                          Text('Bearer 토큰:'),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: SelectableText(
                              authProvider.token!.startsWith('Bearer ')
                                  ? authProvider.token!
                                  : 'Bearer ${authProvider.token}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('토큰 길이: ${authProvider.token!.length} 문자'),
                          Text('토큰 시작: ${authProvider.token!.substring(0, 50)}...'),
                        ] else ...[
                          const Text('토큰 존재: 아니오'),
                          const Text('로그인이 필요합니다.'),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 테스트 URL 정보
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '연결 정보',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text('WebSocket URL:'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const SelectableText(
                            'ws://arirangtrail.duckdns.org/ws-stomp',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('API Base URL:'),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const SelectableText(
                            'http://arirangtrail.duckdns.org',
                            style: TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 테스트 버튼들
                if (authProvider.token != null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _testApiConnection(context, authProvider),
                      child: const Text('API 연결 테스트'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _openWebTest(context, authProvider),
                      child: const Text('웹 테스트 페이지 열기 (토큰 자동 입력)'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _testApiConnection(BuildContext context, AuthProvider authProvider) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('API 연결 테스트 중...')),
      );

      // 채팅방 목록 API 테스트
      final response = await http.get(
        Uri.parse('http://arirangtrail.duckdns.org/api/chat/rooms')
            .replace(queryParameters: {'username': authProvider.userProfile!.username}),
        headers: {
          'Authorization': 'Bearer ${authProvider.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ API 연결 성공!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ API 연결 실패: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ API 연결 에러: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openWebTest(BuildContext context, AuthProvider authProvider) {
    // 웹 테스트 페이지를 여는 기능
    // 실제로는 url_launcher 패키지를 사용하거나
    // 앱 내 웹뷰를 사용할 수 있습니다

    final token = 'Bearer ${authProvider.token}';
    final message = '''
웹 테스트를 위한 정보:

WebSocket URL: ws://arirangtrail.duckdns.org/ws-stomp
JWT 토큰: $token

이 정보를 복사해서 웹 브라우저의 테스트 페이지에 입력하세요.
토큰이 클립보드에 복사됩니다.
    ''';

    Clipboard.setData(ClipboardData(text: token));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('웹 테스트 정보'),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}