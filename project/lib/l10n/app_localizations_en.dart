// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get join => 'Sign Up';

  @override
  String get calendar => 'Calendar';

  @override
  String get home => 'Home';

  @override
  String get language => 'Language';

  @override
  String get myChatHistory => 'My Chat History';

  @override
  String get myPage => 'My Page';

  @override
  String get logoutSuccessMessage => 'Successfully logged out.';

  @override
  String welcomeMessage(String nickname) {
    return 'Welcome, $nickname!';
  }

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get email => 'Email';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get nickname => 'Nickname';

  @override
  String get birthdate => 'Birthdate';

  @override
  String get loginSuccess => 'Login Success';

  @override
  String get joinSuccess => 'Sign Up Success';

  @override
  String get loginFailed => 'Login Failed';

  @override
  String get joinFailed => 'Sign Up Failed';

  @override
  String get confirm => 'Confirm';

  @override
  String get loading => 'Loading...';

  @override
  String get joinComplete => 'Sign Up Complete';

  @override
  String get alreadyHaveAccount => 'Already have an account? Login';

  @override
  String get createNewAccount => 'Create a new account (Sign Up)';

  @override
  String get inputError => 'Input Error';

  @override
  String get errorEnterAllFields => 'Please enter both username and password.';

  @override
  String errorSelectItem(String itemName) {
    return 'Please enter your $itemName.';
  }

  @override
  String get loginTitle => 'Enjoy today\'s festival!';

  @override
  String get homeTitle => 'Today\'s Festivals';

  @override
  String get homeSubtitle =>
      'Festival information from all over the country at a glance!';

  @override
  String get noImages => 'No images to display.';

  @override
  String get calendarView => 'views';

  @override
  String get calendarName => 'name';

  @override
  String get calendarEnding => 'ending';

  @override
  String get calendarComment =>
      'There are no festivals scheduled for that date.';
}
