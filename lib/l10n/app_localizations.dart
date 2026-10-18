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

  /// No description provided for @common_back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get common_back;

  /// No description provided for @common_dayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String common_dayCount(int count);

  /// No description provided for @common_photoCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 photo} other{{count} photos}}'**
  String common_photoCount(int count);

  /// No description provided for @auth_logIn.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get auth_logIn;

  /// Mode toggle segment.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get auth_createAccount;

  /// Sign-up submit button.
  ///
  /// In en, this message translates to:
  /// **'Create my account'**
  String get auth_createMyAccount;

  /// Auth title, line 1 (upright).
  ///
  /// In en, this message translates to:
  /// **'Begin your'**
  String get auth_titleLead;

  /// Auth title, line 2 (italic accent).
  ///
  /// In en, this message translates to:
  /// **'collection.'**
  String get auth_titleEmphasis;

  /// No description provided for @auth_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get auth_nameLabel;

  /// Example name in the empty field.
  ///
  /// In en, this message translates to:
  /// **'Ada Wong'**
  String get auth_nameHint;

  /// No description provided for @auth_emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get auth_emailLabel;

  /// No description provided for @auth_emailHint.
  ///
  /// In en, this message translates to:
  /// **'ada@example.com'**
  String get auth_emailHint;

  /// No description provided for @auth_passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get auth_passwordLabel;

  /// No description provided for @auth_confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get auth_confirmPasswordLabel;

  /// No description provided for @auth_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get auth_nameRequired;

  /// No description provided for @auth_emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get auth_emailRequired;

  /// No description provided for @auth_emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email.'**
  String get auth_emailInvalid;

  /// No description provided for @auth_passwordRequiredSignup.
  ///
  /// In en, this message translates to:
  /// **'Enter a password.'**
  String get auth_passwordRequiredSignup;

  /// No description provided for @auth_passwordRequiredLogin.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get auth_passwordRequiredLogin;

  /// No description provided for @auth_passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters.'**
  String get auth_passwordTooShort;

  /// No description provided for @auth_passwordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get auth_passwordsMismatch;

  /// No description provided for @auth_showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get auth_showPassword;

  /// No description provided for @auth_hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get auth_hidePassword;

  /// No description provided for @auth_strengthWeak.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get auth_strengthWeak;

  /// No description provided for @auth_strengthGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get auth_strengthGood;

  /// No description provided for @auth_strengthStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get auth_strengthStrong;

  /// No description provided for @auth_privacyNote.
  ///
  /// In en, this message translates to:
  /// **'Your memories stay yours — nothing is ever published.'**
  String get auth_privacyNote;

  /// {stars} is auth_rewardTeaseStars, shown highlighted.
  ///
  /// In en, this message translates to:
  /// **'Your first memory earns {stars} — and the Storyteller badge is only three notes away.'**
  String auth_rewardTease(String stars);

  /// No description provided for @auth_rewardTeaseStars.
  ///
  /// In en, this message translates to:
  /// **'10 stars'**
  String get auth_rewardTeaseStars;

  /// Divider between the form and social sign-in.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get auth_or;

  /// Apple's own button wording per language.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get auth_signInWithApple;

  /// No description provided for @auth_continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get auth_continueWithGoogle;

  /// No description provided for @auth_checkInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get auth_checkInbox;

  /// {email} is shown bold.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it on this phone and you\'ll be signed straight in, or confirm anywhere and log in here.'**
  String auth_confirmationSent(String email);

  /// No description provided for @auth_backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to log in'**
  String get auth_backToLogin;

  /// No description provided for @auth_resendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend in {seconds}s'**
  String auth_resendIn(int seconds);

  /// No description provided for @auth_resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get auth_resendEmail;

  /// No description provided for @auth_sentAgain.
  ///
  /// In en, this message translates to:
  /// **'Sent again ✓'**
  String get auth_sentAgain;

  /// No description provided for @auth_useDifferentEmail.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get auth_useDifferentEmail;

  /// Mono eyebrow, uppercased in code. @maxLength 26
  ///
  /// In en, this message translates to:
  /// **'Your memory companion'**
  String get guest_eyebrow;

  /// Hero headline line 1 (upright).
  ///
  /// In en, this message translates to:
  /// **'Every memory,'**
  String get guest_headlineLead;

  /// Hero headline line 2 (italic accent).
  ///
  /// In en, this message translates to:
  /// **'beautifully captured.'**
  String get guest_headlineEmphasis;

  /// No description provided for @guest_body.
  ///
  /// In en, this message translates to:
  /// **'From big celebrations to spontaneous little adventures, some moments are just too good to forget. Plan them, live them, and let us turn the best bits into stories you\'ll want to revisit again and again.'**
  String get guest_body;

  /// No description provided for @guest_occasionWeddings.
  ///
  /// In en, this message translates to:
  /// **'Weddings'**
  String get guest_occasionWeddings;

  /// No description provided for @guest_occasionTrips.
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get guest_occasionTrips;

  /// No description provided for @guest_occasionBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Birthdays'**
  String get guest_occasionBirthdays;

  /// No description provided for @guest_occasionMilestones.
  ///
  /// In en, this message translates to:
  /// **'Milestones'**
  String get guest_occasionMilestones;

  /// No description provided for @guest_cta.
  ///
  /// In en, this message translates to:
  /// **'Start capturing your moments'**
  String get guest_cta;

  /// No description provided for @guest_howTitle.
  ///
  /// In en, this message translates to:
  /// **'Make plans. Make memories. Make them last.'**
  String get guest_howTitle;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'The before'**
  String get guest_stepBeforeEyebrow;

  /// No description provided for @guest_stepBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan the fun. We\'ll handle the details.'**
  String get guest_stepBeforeTitle;

  /// No description provided for @guest_stepBeforeBody.
  ///
  /// In en, this message translates to:
  /// **'Big weekend? Little adventure? Just a Tuesday worth remembering? Map out your plans, make your lists, and keep everything in one happy place.'**
  String get guest_stepBeforeBody;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'The during'**
  String get guest_stepDuringEyebrow;

  /// No description provided for @guest_stepDuringTitle.
  ///
  /// In en, this message translates to:
  /// **'Live it up. Jot it down.'**
  String get guest_stepDuringTitle;

  /// No description provided for @guest_stepDuringBody.
  ///
  /// In en, this message translates to:
  /// **'Snap photos, drop little notes, and take on surprise challenges along the way. The best memories aren\'t always the ones you planned.'**
  String get guest_stepDuringBody;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'The after'**
  String get guest_stepAfterEyebrow;

  /// No description provided for @guest_stepAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Good times deserve a replay.'**
  String get guest_stepAfterTitle;

  /// No description provided for @guest_stepAfterBody.
  ///
  /// In en, this message translates to:
  /// **'When the adventure ends, watch your moments come together in a personal highlight film. Relive the magic and keep the memories.'**
  String get guest_stepAfterBody;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'A few memories, kept'**
  String get guest_sampleMemoriesEyebrow;

  /// No description provided for @guest_sampleTokyo.
  ///
  /// In en, this message translates to:
  /// **'Family trip to Tokyo'**
  String get guest_sampleTokyo;

  /// No description provided for @guest_sampleSolo.
  ///
  /// In en, this message translates to:
  /// **'A solo getaway'**
  String get guest_sampleSolo;

  /// No description provided for @guest_sampleAnniversary.
  ///
  /// In en, this message translates to:
  /// **'Our anniversary'**
  String get guest_sampleAnniversary;

  /// No description provided for @guest_sampleGraduation.
  ///
  /// In en, this message translates to:
  /// **'Graduation'**
  String get guest_sampleGraduation;

  /// No description provided for @guest_sampleFood.
  ///
  /// In en, this message translates to:
  /// **'A food lover\'s weekend'**
  String get guest_sampleFood;

  /// No description provided for @guest_sampleBucketList.
  ///
  /// In en, this message translates to:
  /// **'A bucket-list moment'**
  String get guest_sampleBucketList;
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
