import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:project/provider/auth_provider.dart';
import 'package:project/provider/locale_provider.dart';
import 'package:project/splash_screen.dart'; // SplashScreen 임포트
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

// ✨✨✨ 바로 이 main() 함수가 반드시 있어야 합니다! ✨✨✨
Future<void> main() async {
  // Flutter 엔진과 위젯 트리를 바인딩합니다. (필수)
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일을 로드합니다.
  await dotenv.load(fileName: ".env");

  // 한국 시간/날짜 포맷을 초기화합니다.
  await initializeDateFormatting('ko_KR', null);

  // 안드로이드에서 최신 구글 맵 렌더러를 사용하도록 설정합니다.
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  // 앱을 실행합니다.
  runApp(
    MultiProvider(
      providers: [
        // 앱 전역에서 사용할 Provider들을 등록합니다.
        ChangeNotifierProvider(create: (_) => AuthProvider()..loadUserData()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Arirang Trail',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2d3748)),
        appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2d3748), foregroundColor: Colors.white),
      ),
      locale: localeProvider.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashScreen(), // 앱의 첫 화면
    );
  }
}