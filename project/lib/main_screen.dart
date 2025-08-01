import 'package:flutter/material.dart';
import 'package:project/provider/locale_provider.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'navigation_drawer.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100.0),
        child: Container(
          color: const Color(0xFF2d3748),
          child: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Builder(
                  builder: (context) =>
                      IconButton(
                        icon: const Icon(
                            Icons.menu, size: 40, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                ),

                Expanded(
                  child: Image.asset(
                    'assets/arirang1.png',
                    height: 100,
                    color: Colors.white,
                    colorBlendMode: BlendMode.srcIn,
                  ),
                ),
                IconButton(
                  icon:
                  const Icon(Icons.language, size: 35, color: Colors.white),
                  onPressed: () => _showLanguageDialog(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      drawer: const CustomDrawer(),
      body: const HomePage(),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text('Language Select (언어 선택)'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    context.read<LocaleProvider>().setLocale(
                        const Locale('ko'));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('한국어 (Korean)'),
                ),
                TextButton(
                  onPressed: () {
                    context.read<LocaleProvider>().setLocale(
                        const Locale('en'));
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('English'),
                ),
              ],
            ),
          ),
    );
  }
}
