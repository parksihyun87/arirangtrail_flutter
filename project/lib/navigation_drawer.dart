import 'package:flutter/material.dart';
import 'package:project/provider/auth_provider.dart';
import 'package:provider/provider.dart';
import 'calendar_page.dart';
import 'chat/chat_room_list_screen.dart';
import 'l10n/app_localizations.dart';
import './user/login_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: authProvider.isLoggedIn
                ? Text(
                    l10n.welcomeMessage(authProvider.userProfile!.nickname),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  )
                : Text(l10n.login,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail:
                authProvider.isLoggedIn ? Text(l10n.loginTitle) : null,
            currentAccountPicture: CircleAvatar(
              backgroundImage: authProvider.isLoggedIn &&
                      authProvider.userProfile?.imageUrl != null
                  ? AssetImage(authProvider.userProfile!.imageUrl!)
                      as ImageProvider
                  : const AssetImage('assets/arirang1.png'),
            ),
            decoration: const BoxDecoration(color: Color(0xFF2d3748)),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: Text(l10n.home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_month_outlined),
            title: Text(l10n.calendar),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CalendarPage()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline), // 채팅 아이콘
            title: Text(l10n.chatRoom),
            onTap: () {
              // authProvider를 통해 로그인 상태를 확인합니다.
              if (authProvider.isLoggedIn) {
                // --- 1. 로그인한 사용자일 경우 ---
                // 기존처럼 Drawer를 닫고 채팅방 목록 화면으로 이동합니다.
                Navigator.pop(context); // Drawer 닫기
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatRoomListScreen(),
                  ),
                );
              } else {
                // --- 2. 로그인하지 않은 사용자일 경우 ---
                // 안내 다이얼로그(AlertDialog)를 띄웁니다.
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    // AlertDialog 위젯을 반환합니다.
                    return AlertDialog(
                      title: Text(l10n.loginNeed), // 다이얼로그 제목
                      content: Text(l10n.loginComment), // 다이얼로그 내용
                      actions: <Widget>[
                        // '확인' 버튼
                        TextButton(
                          child: Text(l10n.confirm),
                          onPressed: () {
                            // 다이얼로그를 닫습니다.
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
          const Divider(),
          if (authProvider.isLoggedIn) ...[
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(l10n.logout),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthProvider>().logout();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                    l10n.logoutSuccessMessage,
                    textAlign: TextAlign.center,
                  )),
                );
              },
            ),
          ] else ...[
            ListTile(
              leading: const Icon(Icons.login),
              title: Text(l10n.login),
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
