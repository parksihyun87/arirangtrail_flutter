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
  String get chatRoom => '채팅방';

  @override
  String get chatRoomList => '채팅방 목록';

  @override
  String get chatRoomCreator => '방장';

  @override
  String get chatMessage => '참여 가능한 채팅방이 없습니다';

  @override
  String get chatHintText => '메시지를 입력하세요...';

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
  String get loginNeed => '로그인이 필요합니다.';

  @override
  String get loginComment => '로그인 후 이용 가능한 서비스입니다.';

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

  @override
  String get eventPeriod => '행사 기간';

  @override
  String get performanceTime => '공연 시간';

  @override
  String get usageFee => '이용 요금';

  @override
  String get phoneNumber => '전화번호';

  @override
  String get directions => '오시는 길';

  @override
  String get getDirections => '길찾기';

  @override
  String get askWhichMap => '어떤 지도로 길을 찾으시겠어요?';

  @override
  String get kakaoMap => '카카오맵';

  @override
  String get googleMap => '구글맵';

  @override
  String get notification => '알림';

  @override
  String get ok => '확인';

  @override
  String get unsupportedDirections => '이 장소는 길찾기를 지원하지 않습니다.';

  @override
  String get mapNotAvailable => '지도 정보를 제공하지 않습니다.';

  @override
  String get locationServiceDisabled => '위치 서비스를 활성화해주세요.';

  @override
  String get locationPermissionDenied => '위치 권한이 거부되었습니다.';

  @override
  String get locationPermissionPermanentlyDenied =>
      '위치 권한이 영구적으로 거부되었습니다. 앱 설정에서 권한을 허용해주세요.';

  @override
  String get couldNotLaunchGoogleMaps => '구글 맵을 열 수 없습니다.';

  @override
  String get couldNotGetLocation => '현재 위치를 가져올 수 없습니다.';
}
