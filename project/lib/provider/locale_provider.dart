import "package:flutter/material.dart";

class LocaleProvider with ChangeNotifier {
  // 앱 시작 시 기본 언어는 한국어로 설정
  Locale _locale = const Locale('ko');

  // 외부에서 현재 언어 설정을 읽을 수 있도록 하는 getter
  Locale get locale => _locale;

  // 언어를 변경하는 함수
  void setLocale(Locale newLocale) {
    _locale = newLocale;
    // notifyListeners()를 호출하여 언어가 변경되었음을 앱의 모든 부분에 알린다
    notifyListeners();
  }
}
