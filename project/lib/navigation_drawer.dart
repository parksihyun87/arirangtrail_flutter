import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_provider.dart';
import 'calendar_page.dart';

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
            accountName: Text(
              authProvider.userProfile?.nickname ?? '로그인이 필요합니다',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            accountEmail:
                authProvider.isLoggedIn ? const Text("오늘의 축제를 즐겨보세요!") : null,
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: authProvider.isLoggedIn &&
                      authProvider.userProfile?.imageUrl != null
                  ? NetworkImage(authProvider.userProfile!.imageUrl!)
                  : const AssetImage('assets/arirang1.png') as ImageProvider,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: const Text('캘린더'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CalendarPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('지역검색'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('축제후기'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_outline),
            title: const Text('커뮤니티'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('회사소개'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          if (authProvider.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.chat_outlined),
              title: Row(
                children: [
                  const Text('나의 채팅기록'),
                  const SizedBox(width: 8),
                  if (authProvider.totalUnreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${authProvider.totalUnreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: const Text('마이페이지'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.pop(context);
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('로그인'),
              onTap: () {
                context.read<AuthProvider>().login(
                      'fake_jwt_token_for_test',
                      UserProfile(
                        username: 'flutter_user',
                        nickname: '아리랑 감상가',
                        imageUrl:
                            'https://cdn-icons-png.flaticon.com/512/147/147144.png',
                      ),
                    );
                context.read<AuthProvider>().updateTotalUnreadCount(5);
                Navigator.pop(context);
              },
            ),
          ],
        ],
      ),
    );
  }
}
