import 'dart:async';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'navigation_drawer.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _showContent = false;

  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showContent = true);
    });
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            toolbarHeight: 80,
            leading: Builder(
              builder: (context) => Padding(
                padding: const EdgeInsets.only(
                  left: 12.0,
                  top: 8.0,
                  bottom: 8.0,
                  right: 12.0,
                ),
                child: IconButton(
                  icon: const Icon(Icons.menu, size: 40, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            title: Image.asset(
              'assets/arirang1.png',
              height: 100,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
            ),
            centerTitle: true,
            backgroundColor: const Color(0xFF2d3748),
          ),
          drawer: const CustomDrawer(),
          body: const HomePage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateToHome,
      child: Scaffold(
        backgroundColor: const Color(0xFF2d3748),
        body: Center(
          child: AnimatedOpacity(
            opacity: _showContent ? 1.0 : 0.0,
            duration: const Duration(seconds: 1),
            curve: Curves.easeIn,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/arirang1.png',
                  height: 150,
                  color: Colors.white,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(height: 40),
                const Text(
                  '화면을 터치하여 시작하세요',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '외국인들을 위한 관광 플랫폽입니다.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
