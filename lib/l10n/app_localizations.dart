import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_et.dart';
import 'app_localizations_ru.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('et'),
    Locale('ru'),
  ];

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @common_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get common_retry;

  /// Snackbar action that opens the paywall.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get common_upgrade;

  /// Bottom nav tab. @maxLength 9
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// Bottom nav tab. @maxLength 9
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get nav_expenses;

  /// Eyebrow above the date picker when the caller gives no label.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get datePicker_defaultLabel;

  /// Body of a coming-soon page.
  ///
  /// In en, this message translates to:
  /// **'{title} is on its way.'**
  String placeholder_onItsWay(String title);

  /// No description provided for @error_network.
  ///
  /// In en, this message translates to:
  /// **'Please check your connection.'**
  String get error_network;

  /// No description provided for @error_permission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission.'**
  String get error_permission;

  /// No description provided for @error_notFound.
  ///
  /// In en, this message translates to:
  /// **'The requested data was not found.'**
  String get error_notFound;

  /// No description provided for @error_unknown.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred. Try again later.'**
  String get error_unknown;

  /// No description provided for @error_freeTierMemories.
  ///
  /// In en, this message translates to:
  /// **'Free plan is limited to 3 memories. Upgrade to Pro for unlimited memories.'**
  String get error_freeTierMemories;

  /// No description provided for @error_freeTierPhotos.
  ///
  /// In en, this message translates to:
  /// **'Free plan is limited to 40 photos per memory. Upgrade to Pro for unlimited photos.'**
  String get error_freeTierPhotos;

  /// No description provided for @error_questPlanningClosed.
  ///
  /// In en, this message translates to:
  /// **'This memory was logged after the trip ended, so there\'s nothing to plan.'**
  String get error_questPlanningClosed;

  /// No description provided for @error_authLink.
  ///
  /// In en, this message translates to:
  /// **'That link has expired or was already used. If you\'ve already confirmed your email, just log in.'**
  String get error_authLink;

  /// No description provided for @error_rateLimitedEmail.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent too many emails for now. Please try again in a little while.'**
  String get error_rateLimitedEmail;

  /// No description provided for @error_rateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a bit and try again.'**
  String get error_rateLimited;

  /// No description provided for @error_rateLimitedSeconds.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Too many attempts. Please wait 1 second and try again.} other{Too many attempts. Please wait {count} seconds and try again.}}'**
  String error_rateLimitedSeconds(int count);
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
      <String>['en', 'et', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'et':
      return AppLocalizationsEt();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
