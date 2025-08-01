import 'package:flutter/material.dart';
import 'package:project/provider/auth_provider.dart';
import 'package:project/review_page.dart';
import 'package:project/widget/translator.dart';
import 'package:provider/provider.dart';
import 'calendar_page.dart';
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
                ? TranslatedText(
                    text: authProvider.userProfile!.nickname,
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
            leading: const Icon(Icons.reviews_outlined),
            title: const Text('축제후기'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReviewPage()));
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
                  SnackBar(content: Text(l10n.logoutSuccessMessage)),
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
