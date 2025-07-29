import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'home_page.dart';
import 'auth_provider.dart';
import 'navigation_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2d3748);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arirang Trail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: Image.asset(
            'assets/arirang1.png',
            height: 70,
            color: Colors.white,
            colorBlendMode: BlendMode.srcIn,
          ),
          centerTitle: true,
        ),
        drawer: const CustomDrawer(),
        body: const HomePage(),
      ),
    );
  }
}
