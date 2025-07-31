// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get login => '로그인';

  @override
  String get logout => '로그아웃';

  @override
  String get join => '회원가입';

  @override
  String get calendar => '캘린더';

  @override
  String get home => '홈';

  @override
  String get language => '언어 변경';

  @override
  String get myChatHistory => '나의 채팅기록';

  @override
  String get myPage => '마이페이지';

  @override
  String get logoutSuccessMessage => '성공적으로 로그아웃되었습니다.';

  @override
  String welcomeMessage(String nickname) {
    return '$nickname님, 환영합니다!';
  }

  @override
  String get username => '아이디';

  @override
  String get password => '비밀번호';

  @override
  String get email => '이메일';

  @override
  String get firstName => '성 (First Name)';

  @override
  String get lastName => '이름 (Last Name)';

  @override
  String get nickname => '닉네임';

  @override
  String get birthdate => '생년월일 (Birthdate)';

  @override
  String get loginSuccess => '로그인 성공';

  @override
  String get joinSuccess => '회원가입 성공';

  @override
  String get loginFailed => '로그인 실패';

  @override
  String get joinFailed => '회원가입 실패';

  @override
  String get confirm => '확인';

  @override
  String get loading => '로딩 중...';

  @override
  String get joinComplete => '회원가입 완료';

  @override
  String get alreadyHaveAccount => '이미 계정이 있으신가요? 로그인';

  @override
  String get createNewAccount => '새 계정 만들기 (회원가입)';

  @override
  String get inputError => '입력 오류';

  @override
  String get errorEnterAllFields => '아이디와 비밀번호를 모두 입력해주세요.';

  @override
  String errorSelectItem(String itemName) {
    return '$itemName 항목을 입력해주세요.';
  }

  @override
  String get loginTitle => '오늘의 축제를 즐겨보세요!';

  @override
  String get homeTitle => '오늘의 축제';

  @override
  String get homeSubtitle => '전국의 축제 정보를 한눈에!';

  @override
  String get noImages => '표시할 이미지가 없습니다.';

  @override
  String get calendarView => '조회순';

  @override
  String get calendarName => '이름순';

  @override
  String get calendarEnding => '마감순';

  @override
  String get calendarComment => '해당 날짜에 예정된 축제가 없습니다.';
}
