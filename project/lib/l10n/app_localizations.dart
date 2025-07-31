import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko')
  ];

  /// No description provided for @login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logout;

  /// No description provided for @join.
  ///
  /// In ko, this message translates to:
  /// **'회원가입'**
  String get join;

  /// No description provided for @calendar.
  ///
  /// In ko, this message translates to:
  /// **'캘린더'**
  String get calendar;

  /// No description provided for @home.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get home;

  /// No description provided for @language.
  ///
  /// In ko, this message translates to:
  /// **'언어 변경'**
  String get language;

  /// No description provided for @myChatHistory.
  ///
  /// In ko, this message translates to:
  /// **'나의 채팅기록'**
  String get myChatHistory;

  /// No description provided for @myPage.
  ///
  /// In ko, this message translates to:
  /// **'마이페이지'**
  String get myPage;

  /// No description provided for @logoutSuccessMessage.
  ///
  /// In ko, this message translates to:
  /// **'성공적으로 로그아웃되었습니다.'**
  String get logoutSuccessMessage;

  /// No description provided for @welcomeMessage.
  ///
  /// In ko, this message translates to:
  /// **'{nickname}님, 환영합니다!'**
  String welcomeMessage(String nickname);

  /// No description provided for @username.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get username;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @email.
  ///
  /// In ko, this message translates to:
  /// **'이메일'**
  String get email;

  /// No description provided for @firstName.
  ///
  /// In ko, this message translates to:
  /// **'성 (First Name)'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In ko, this message translates to:
  /// **'이름 (Last Name)'**
  String get lastName;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @birthdate.
  ///
  /// In ko, this message translates to:
  /// **'생년월일 (Birthdate)'**
  String get birthdate;

  /// No description provided for @loginSuccess.
  ///
  /// In ko, this message translates to:
  /// **'로그인 성공'**
  String get loginSuccess;

  /// No description provided for @joinSuccess.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 성공'**
  String get joinSuccess;

  /// No description provided for @loginFailed.
  ///
  /// In ko, this message translates to:
  /// **'로그인 실패'**
  String get loginFailed;

  /// No description provided for @joinFailed.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 실패'**
  String get joinFailed;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @loading.
  ///
  /// In ko, this message translates to:
  /// **'로딩 중...'**
  String get loading;

  /// No description provided for @joinComplete.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 완료'**
  String get joinComplete;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In ko, this message translates to:
  /// **'이미 계정이 있으신가요? 로그인'**
  String get alreadyHaveAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In ko, this message translates to:
  /// **'새 계정 만들기 (회원가입)'**
  String get createNewAccount;

  /// No description provided for @inputError.
  ///
  /// In ko, this message translates to:
  /// **'입력 오류'**
  String get inputError;

  /// No description provided for @errorEnterAllFields.
  ///
  /// In ko, this message translates to:
  /// **'아이디와 비밀번호를 모두 입력해주세요.'**
  String get errorEnterAllFields;

  /// No description provided for @errorSelectItem.
  ///
  /// In ko, this message translates to:
  /// **'{itemName} 항목을 입력해주세요.'**
  String errorSelectItem(String itemName);

  /// No description provided for @loginTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 축제를 즐겨보세요!'**
  String get loginTitle;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 축제'**
  String get homeTitle;

  /// No description provided for @homeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'전국의 축제 정보를 한눈에!'**
  String get homeSubtitle;

  /// No description provided for @noImages.
  ///
  /// In ko, this message translates to:
  /// **'표시할 이미지가 없습니다.'**
  String get noImages;

  /// No description provided for @calendarView.
  ///
  /// In ko, this message translates to:
  /// **'조회순'**
  String get calendarView;

  /// No description provided for @calendarName.
  ///
  /// In ko, this message translates to:
  /// **'이름순'**
  String get calendarName;

  /// No description provided for @calendarEnding.
  ///
  /// In ko, this message translates to:
  /// **'마감순'**
  String get calendarEnding;

  /// No description provided for @calendarComment.
  ///
  /// In ko, this message translates to:
  /// **'해당 날짜에 예정된 축제가 없습니다.'**
  String get calendarComment;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
