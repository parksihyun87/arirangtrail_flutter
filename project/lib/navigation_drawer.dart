import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'calendar_page.dart';
import 'login_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName:
                Text(authProvider.userProfile?.nickname ?? '로그인이 필요합니다'),
            accountEmail:
                authProvider.isLoggedIn ? const Text("오늘의 축제를 즐겨보세요!") : null,
            currentAccountPicture: CircleAvatar(
              backgroundImage: authProvider.isLoggedIn &&
                      authProvider.userProfile?.imageUrl != null
                  ? AssetImage(authProvider.userProfile!.imageUrl!)
                      as ImageProvider
                  : const AssetImage('assets/arirang1.png'),
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2d3748),
            ),
          ),

          // --- 공통 메뉴 (항상 보임) ---
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('홈'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('캘린더'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CalendarPage()));
            },
          ),
          const Divider(),

          // --- 로그인 상태에 따라 달라지는 메뉴 ---
          if (authProvider.isLoggedIn) ...[
            // 로그인 했을 때만 보임
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: const Text('나의 채팅기록'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('마이페이지'),
              onTap: () => Navigator.pop(context),
            ),

            // 로그아웃 버튼의 onTap 로직 변경
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () async {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
                await showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('로그아웃'),
                    content: const Text('성공적으로 로그아웃되었습니다.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('확인'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else ...[
            // 로그아웃 상태일 때만 보임
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('로그인'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const LoginPage()));
              },
            ),
          ]
        ],
      ),
    );
  }
}
