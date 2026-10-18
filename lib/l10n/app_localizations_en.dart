// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_done => 'Done';

  @override
  String get common_retry => 'Retry';

  @override
  String get common_upgrade => 'Upgrade';

  @override
  String get nav_home => 'Home';

  @override
  String get nav_expenses => 'Expenses';

  @override
  String get datePicker_defaultLabel => 'Pick a date';

  @override
  String placeholder_onItsWay(String title) {
    return '$title is on its way.';
  }

  @override
  String get error_network => 'Please check your connection.';

  @override
  String get error_permission => 'You do not have permission.';

  @override
  String get error_notFound => 'The requested data was not found.';

  @override
  String get error_unknown => 'An unknown error occurred. Try again later.';

  @override
  String get error_freeTierMemories =>
      'Free plan is limited to 3 memories. Upgrade to Pro for unlimited memories.';

  @override
  String get error_freeTierPhotos =>
      'Free plan is limited to 40 photos per memory. Upgrade to Pro for unlimited photos.';

  @override
  String get error_questPlanningClosed =>
      'This memory was logged after the trip ended, so there\'s nothing to plan.';

  @override
  String get error_authLink =>
      'That link has expired or was already used. If you\'ve already confirmed your email, just log in.';

  @override
  String get error_rateLimitedEmail =>
      'We\'ve sent too many emails for now. Please try again in a little while.';

  @override
  String get error_rateLimited =>
      'Too many attempts. Please wait a bit and try again.';

  @override
  String error_rateLimitedSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Too many attempts. Please wait $count seconds and try again.',
      one: 'Too many attempts. Please wait 1 second and try again.',
    );
    return '$_temp0';
  }
}
