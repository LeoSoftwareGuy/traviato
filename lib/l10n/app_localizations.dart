import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
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
  /// **'Your first memory earns {stars} and the Storyteller badge is only three notes away.'**
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

  /// No description provided for @common_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get common_today;

  /// Day pager / hero pill. ET abbreviates per spec.
  ///
  /// In en, this message translates to:
  /// **'Day {day} of {total}'**
  String common_dayOf(int day, int total);

  /// No description provided for @common_starCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 star} other{{count} stars}}'**
  String common_starCount(int count);

  /// Greeting when the profile has no username (e.g. Apple sign-in hid the name).
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get home_greetingNoName;

  /// {name} is shown in the accent colour.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String home_greeting(String name);

  /// Mono eyebrow, uppercased in code. @maxLength 26
  ///
  /// In en, this message translates to:
  /// **'Happening now'**
  String get home_happeningNow;

  /// Mono eyebrow, uppercased in code. @maxLength 26
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get home_comingUp;

  /// Mono eyebrow and badge.
  ///
  /// In en, this message translates to:
  /// **'Kept forever'**
  String get home_keptForever;

  /// Badge on a finished memory without a kept wrap-up.
  ///
  /// In en, this message translates to:
  /// **'Recap'**
  String get home_recap;

  /// No description provided for @home_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No memories yet'**
  String get home_emptyTitle;

  /// No description provided for @home_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Start your first memory and watch it become a journal you keep forever.'**
  String get home_emptyBody;

  /// No description provided for @home_emptyCta.
  ///
  /// In en, this message translates to:
  /// **'Create your first memory'**
  String get home_emptyCta;

  /// No description provided for @home_keptForeverEmpty.
  ///
  /// In en, this message translates to:
  /// **'No memories logged yet — they show up here once a trip wraps.'**
  String get home_keptForeverEmpty;

  /// Stat label under the number, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{memory} other{memories}}'**
  String home_statMemories(int count);

  /// Stat label under the number, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{place} other{places}}'**
  String home_statPlaces(int count);

  /// Stat label under the number, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String home_statDays(int count);

  /// Countdown pill on an upcoming memory.
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get home_countdownToday;

  /// Countdown pill on an upcoming memory.
  ///
  /// In en, this message translates to:
  /// **'in {days}d'**
  String home_countdownInDays(int days);

  /// No description provided for @home_datesTbd.
  ///
  /// In en, this message translates to:
  /// **'Dates TBD'**
  String get home_datesTbd;

  /// No description provided for @home_questsPlanned.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quest planned} other{{count} quests planned}}'**
  String home_questsPlanned(int count);

  /// No description provided for @home_nothingPlanned.
  ///
  /// In en, this message translates to:
  /// **'Nothing planned yet'**
  String get home_nothingPlanned;

  /// No description provided for @home_planArrow.
  ///
  /// In en, this message translates to:
  /// **'Plan →'**
  String get home_planArrow;

  /// Hero action button. @maxLength 10
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get home_actionPlan;

  /// Hero action button. @maxLength 10
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get home_actionExpenses;

  /// Hero action button. @maxLength 10
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get home_actionJournal;

  /// Screen-reader label for the hero card cover tap.
  ///
  /// In en, this message translates to:
  /// **'Open plan'**
  String get home_coverOpenPlan;

  /// Screen-reader label for the hero card cover tap.
  ///
  /// In en, this message translates to:
  /// **'Open journal'**
  String get home_coverOpenJournal;

  /// No description provided for @home_checklist.
  ///
  /// In en, this message translates to:
  /// **'Checklist'**
  String get home_checklist;

  /// No description provided for @home_packedProgress.
  ///
  /// In en, this message translates to:
  /// **'{packed} of {total} packed →'**
  String home_packedProgress(int packed, int total);

  /// No description provided for @vibe_romantic.
  ///
  /// In en, this message translates to:
  /// **'Romantic'**
  String get vibe_romantic;

  /// No description provided for @vibe_adventure.
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get vibe_adventure;

  /// No description provided for @vibe_cultural.
  ///
  /// In en, this message translates to:
  /// **'Cultural'**
  String get vibe_cultural;

  /// No description provided for @vibe_chill.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get vibe_chill;

  /// No description provided for @vibe_foodie.
  ///
  /// In en, this message translates to:
  /// **'Foodie'**
  String get vibe_foodie;

  /// No description provided for @vibe_roadTrip.
  ///
  /// In en, this message translates to:
  /// **'Road trip'**
  String get vibe_roadTrip;

  /// No description provided for @vibe_wellness.
  ///
  /// In en, this message translates to:
  /// **'Wellness'**
  String get vibe_wellness;

  /// No description provided for @vibe_wildlife.
  ///
  /// In en, this message translates to:
  /// **'Wildlife'**
  String get vibe_wildlife;

  /// No description provided for @vibe_nightlife.
  ///
  /// In en, this message translates to:
  /// **'Nightlife'**
  String get vibe_nightlife;

  /// No description provided for @vibe_photography.
  ///
  /// In en, this message translates to:
  /// **'Photography'**
  String get vibe_photography;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'New memory'**
  String get trip_newMemory;

  /// No description provided for @trip_createTitleLead.
  ///
  /// In en, this message translates to:
  /// **'What deserves'**
  String get trip_createTitleLead;

  /// No description provided for @trip_createTitleEmphasis.
  ///
  /// In en, this message translates to:
  /// **'a memory?'**
  String get trip_createTitleEmphasis;

  /// No description provided for @trip_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name it'**
  String get trip_nameLabel;

  /// No description provided for @trip_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Summer in Tokyo'**
  String get trip_nameHint;

  /// No description provided for @trip_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this memory a name.'**
  String get trip_nameRequired;

  /// No description provided for @trip_whereLabel.
  ///
  /// In en, this message translates to:
  /// **'Where did it happen?'**
  String get trip_whereLabel;

  /// No description provided for @trip_whereHint.
  ///
  /// In en, this message translates to:
  /// **'Where did this happen?'**
  String get trip_whereHint;

  /// No description provided for @trip_startsLabel.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get trip_startsLabel;

  /// No description provided for @trip_endsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get trip_endsLabel;

  /// No description provided for @trip_endBeforeStart.
  ///
  /// In en, this message translates to:
  /// **'End date can\'t be before the start date.'**
  String get trip_endBeforeStart;

  /// No description provided for @trip_datesRequired.
  ///
  /// In en, this message translates to:
  /// **'Add a start and end date.'**
  String get trip_datesRequired;

  /// No description provided for @trip_datesHint.
  ///
  /// In en, this message translates to:
  /// **'Not sure yet? Pick your best guess you can change it later.'**
  String get trip_datesHint;

  /// No description provided for @trip_vibeLabel.
  ///
  /// In en, this message translates to:
  /// **'The vibe'**
  String get trip_vibeLabel;

  /// No description provided for @trip_vibesChosen.
  ///
  /// In en, this message translates to:
  /// **'{count} chosen'**
  String trip_vibesChosen(int count);

  /// No description provided for @trip_createCta.
  ///
  /// In en, this message translates to:
  /// **'Create memory'**
  String get trip_createCta;

  /// {stars} is common_starCount(10), shown highlighted.
  ///
  /// In en, this message translates to:
  /// **'Creating this earns {stars}. Log a note each day and you\'ll unlock Storyteller.'**
  String trip_rewardNudge(String stars);

  /// No description provided for @trip_coverChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose a cover'**
  String get trip_coverChoose;

  /// No description provided for @trip_coverChange.
  ///
  /// In en, this message translates to:
  /// **'Change cover'**
  String get trip_coverChange;

  /// No description provided for @trip_coverAutoHint.
  ///
  /// In en, this message translates to:
  /// **'or we\'ll pick one that suits the vibe'**
  String get trip_coverAutoHint;

  /// Mono tag, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Your cover'**
  String get trip_coverYours;

  /// Mono tag, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Suggested: {vibe}'**
  String trip_coverSuggested(String vibe);

  /// No description provided for @trip_coverUploadTitle.
  ///
  /// In en, this message translates to:
  /// **'Upload a cover photo'**
  String get trip_coverUploadTitle;

  /// No description provided for @trip_takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get trip_takePhoto;

  /// No description provided for @trip_chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get trip_chooseFromGallery;

  /// No description provided for @trip_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this memory'**
  String get trip_deleteTitle;

  /// No description provided for @trip_deleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Yes! Delete it forever'**
  String get trip_deleteConfirm;

  /// No description provided for @trip_noteDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day of notes} other{{count} days of notes}}'**
  String trip_noteDays(int count);

  /// {photos} is common_photoCount, {notes} is trip_noteDays.
  ///
  /// In en, this message translates to:
  /// **'This removes {photos} and {notes}. Your earned stars are lost. It can\'t be undone.'**
  String trip_deleteConsequence(String photos, String notes);

  /// No description provided for @common_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get common_edit;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

  /// No description provided for @common_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get common_save;

  /// Star award toast. The ✦ glyph replaces the word "star" (spec Phase 4).
  ///
  /// In en, this message translates to:
  /// **'+1 ✦ · quest done'**
  String get toast_questDone;

  /// Checklist toast (no stars awarded).
  ///
  /// In en, this message translates to:
  /// **'✦ Packed — nice'**
  String get toast_packed;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'The plan'**
  String get plan_eyebrow;

  /// Follows home_questsPlanned after a ·.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day total} other{{count} days total}}'**
  String plan_daysTotal(int count);

  /// No description provided for @plan_noDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates to this memory to start planning your days.'**
  String get plan_noDates;

  /// Day pager title / tab.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String plan_dayN(int day);

  /// Mono sub-line under the day title.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String plan_doneCount(int done, int total);

  /// No description provided for @plan_addQuest.
  ///
  /// In en, this message translates to:
  /// **'+ Add a quest'**
  String get plan_addQuest;

  /// No description provided for @plan_addQuestToDay.
  ///
  /// In en, this message translates to:
  /// **'+ Add a quest to Day {day}'**
  String plan_addQuestToDay(int day);

  /// No description provided for @plan_addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get plan_addTitle;

  /// No description provided for @plan_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit plan'**
  String get plan_editTitle;

  /// No description provided for @plan_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name this plan'**
  String get plan_nameLabel;

  /// No description provided for @plan_nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pack the car'**
  String get plan_nameHint;

  /// No description provided for @plan_nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give this plan a name.'**
  String get plan_nameRequired;

  /// No description provided for @plan_timeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time (optional)'**
  String get plan_timeLabel;

  /// No description provided for @plan_noTime.
  ///
  /// In en, this message translates to:
  /// **'No time set'**
  String get plan_noTime;

  /// No description provided for @plan_detailLabel.
  ///
  /// In en, this message translates to:
  /// **'Detail (optional)'**
  String get plan_detailLabel;

  /// No description provided for @plan_detailHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Cooler, blankets, hiking boots'**
  String get plan_detailHint;

  /// No description provided for @manage_title.
  ///
  /// In en, this message translates to:
  /// **'Edit this memory'**
  String get manage_title;

  /// The memory's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get manage_nameLabel;

  /// No description provided for @manage_rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get manage_rename;

  /// No description provided for @manage_saveDates.
  ///
  /// In en, this message translates to:
  /// **'Save dates'**
  String get manage_saveDates;

  /// No description provided for @manage_deleteAndSave.
  ///
  /// In en, this message translates to:
  /// **'Delete and save'**
  String get manage_deleteAndSave;

  /// Two-step warning when new dates leave content outside the memory (#271). {range} is the new 'd MMM y – d MMM y' range; {items} is a comma-joined list of manage_noteCount / common_photoCount / manage_questCount / manage_bonusTaskCount.
  ///
  /// In en, this message translates to:
  /// **'Outside {range}: {items}. They\'ll be deleted. This can\'t be undone.'**
  String manage_datesConsequence(String range, String items);

  /// No description provided for @manage_noteCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String manage_noteCount(int count);

  /// No description provided for @manage_questCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quest} other{{count} quests}}'**
  String manage_questCount(int count);

  /// No description provided for @manage_bonusTaskCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bonus task} other{{count} bonus tasks}}'**
  String manage_bonusTaskCount(int count);

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get manage_cover;

  /// No description provided for @checklist_title.
  ///
  /// In en, this message translates to:
  /// **'Pack for the trip'**
  String get checklist_title;

  /// No description provided for @checklist_emptyCategory.
  ///
  /// In en, this message translates to:
  /// **'No items in this category yet.'**
  String get checklist_emptyCategory;

  /// No description provided for @checklist_addHint.
  ///
  /// In en, this message translates to:
  /// **'Add something of your own...'**
  String get checklist_addHint;

  /// Badge on must-pack items.
  ///
  /// In en, this message translates to:
  /// **'Essential'**
  String get checklist_essential;

  /// No description provided for @checklist_packedOf.
  ///
  /// In en, this message translates to:
  /// **'{checked} of {total} packed'**
  String checklist_packedOf(int checked, int total);

  /// No description provided for @checklist_catTravelEssentials.
  ///
  /// In en, this message translates to:
  /// **'Travel essentials'**
  String get checklist_catTravelEssentials;

  /// No description provided for @checklist_catClothingShoes.
  ///
  /// In en, this message translates to:
  /// **'Clothing & shoes'**
  String get checklist_catClothingShoes;

  /// No description provided for @checklist_catGadgetsTech.
  ///
  /// In en, this message translates to:
  /// **'Gadgets & tech'**
  String get checklist_catGadgetsTech;

  /// No description provided for @checklist_catToiletriesHealth.
  ///
  /// In en, this message translates to:
  /// **'Toiletries & health'**
  String get checklist_catToiletriesHealth;

  /// No description provided for @checklist_catNiceToHaves.
  ///
  /// In en, this message translates to:
  /// **'Nice-to-haves'**
  String get checklist_catNiceToHaves;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal_eyebrow;

  /// No description provided for @journal_quietOne.
  ///
  /// In en, this message translates to:
  /// **'Day 1'**
  String get journal_quietOne;

  /// No description provided for @journal_dayQuietOne.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String journal_dayQuietOne(int day);

  /// Followed by · and journal_questsDone.
  ///
  /// In en, this message translates to:
  /// **'No photos, no notes yet'**
  String get journal_noEntries;

  /// No description provided for @journal_questsDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 quest done} other{{count} quests done}}'**
  String journal_questsDone(int count);

  /// {name} is the memory's own title (user content).
  ///
  /// In en, this message translates to:
  /// **'Day {day} — {name}'**
  String journal_dayTitle(int day, String name);

  /// Note page stamp, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {date}'**
  String journal_noteStamp(int day, String date);

  /// No description provided for @journal_noDates.
  ///
  /// In en, this message translates to:
  /// **'Add dates to this memory to start your journal.'**
  String get journal_noDates;

  /// No description provided for @journal_dayNotYet.
  ///
  /// In en, this message translates to:
  /// **'This day hasn\'t happened yet'**
  String get journal_dayNotYet;

  /// No description provided for @journal_toDo.
  ///
  /// In en, this message translates to:
  /// **'To Do'**
  String get journal_toDo;

  /// No description provided for @journal_todayToDo.
  ///
  /// In en, this message translates to:
  /// **'Today\'s to do'**
  String get journal_todayToDo;

  /// Wrap-up button; the unlocked one appends ▸ in code.
  ///
  /// In en, this message translates to:
  /// **'View wrap-up'**
  String get journal_viewWrapUp;

  /// No description provided for @journal_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get journal_photos;

  /// No description provided for @journal_photosSaved.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String journal_photosSaved(int count);

  /// Add-photo tile in the strip; ✦2 is the award.
  ///
  /// In en, this message translates to:
  /// **'Add ✦2'**
  String get journal_addPhotoTile;

  /// {ask} is one of journal_wrapUpAsk*.
  ///
  /// In en, this message translates to:
  /// **'Your film needs a little more to work with. {ask}'**
  String journal_wrapUpExplainer(String ask);

  /// No description provided for @journal_wrapUpAskPhotosAndNote.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 more photo and one note to unlock it.} other{Add {count} more photos and one note to unlock it.}}'**
  String journal_wrapUpAskPhotosAndNote(int count);

  /// No description provided for @journal_wrapUpAskPhotos.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Add 1 more photo to unlock it.} other{Add {count} more photos to unlock it.}}'**
  String journal_wrapUpAskPhotos(int count);

  /// No description provided for @journal_wrapUpAskNote.
  ///
  /// In en, this message translates to:
  /// **'Write one note to unlock it.'**
  String get journal_wrapUpAskNote;

  /// No description provided for @journal_wrapUpReqPhotos.
  ///
  /// In en, this message translates to:
  /// **'Five photos in this memory'**
  String get journal_wrapUpReqPhotos;

  /// No description provided for @journal_wrapUpReqNote.
  ///
  /// In en, this message translates to:
  /// **'At least one note written'**
  String get journal_wrapUpReqNote;

  /// No description provided for @journal_wrapUpFree.
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy — this one\'s the same on every plan.'**
  String get journal_wrapUpFree;

  /// No description provided for @journal_nothingYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get journal_nothingYet;

  /// No description provided for @journal_nothingFromDay.
  ///
  /// In en, this message translates to:
  /// **'Nothing from Day {day} yet'**
  String journal_nothingFromDay(int day);

  /// No description provided for @journal_nudgeBody.
  ///
  /// In en, this message translates to:
  /// **'Every photo you add will contribute to the final wrap-up.'**
  String get journal_nudgeBody;

  /// No description provided for @journal_addAPhoto.
  ///
  /// In en, this message translates to:
  /// **'＋ Add a photo'**
  String get journal_addAPhoto;

  /// No description provided for @journal_writeNote.
  ///
  /// In en, this message translates to:
  /// **'Write a note'**
  String get journal_writeNote;

  /// No description provided for @journal_addNotesToday.
  ///
  /// In en, this message translates to:
  /// **'✎ Add notes about today'**
  String get journal_addNotesToday;

  /// No description provided for @journal_continueEntry.
  ///
  /// In en, this message translates to:
  /// **'✎ Continue entry'**
  String get journal_continueEntry;

  /// No description provided for @journal_wordCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 word} other{{count} words}}'**
  String journal_wordCount(int count);

  /// Note card footer, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Edited {time}'**
  String journal_edited(String time);

  /// Star award toast (spec copy table).
  ///
  /// In en, this message translates to:
  /// **'+1 ✦ · note saved'**
  String get toast_noteSaved;

  /// No description provided for @note_discardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get note_discardTitle;

  /// No description provided for @note_deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this note?'**
  String get note_deleteTitle;

  /// No description provided for @note_deleteBody.
  ///
  /// In en, this message translates to:
  /// **'The note for this day and its ✦1 star will be removed. This can\'t be undone.'**
  String get note_deleteBody;

  /// No description provided for @note_keepNote.
  ///
  /// In en, this message translates to:
  /// **'Keep note'**
  String get note_keepNote;

  /// No description provided for @note_keepWriting.
  ///
  /// In en, this message translates to:
  /// **'Keep writing'**
  String get note_keepWriting;

  /// No description provided for @note_discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get note_discard;

  /// No description provided for @note_bodyHint.
  ///
  /// In en, this message translates to:
  /// **'Keep going: type, or tap the mic and just talk.'**
  String get note_bodyHint;

  /// No description provided for @note_micOff.
  ///
  /// In en, this message translates to:
  /// **'Microphone is off. Turn it on in Settings, or just type.'**
  String get note_micOff;

  /// No description provided for @note_voiceUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Voice isn\'t available right now only typing works.'**
  String get note_voiceUnavailable;

  /// Screen-reader label for the Aa button.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get note_typeSemantics;

  /// Screen-reader label for the mic.
  ///
  /// In en, this message translates to:
  /// **'Dictate'**
  String get note_dictateSemantics;

  /// Screen-reader label for the mic while listening.
  ///
  /// In en, this message translates to:
  /// **'Stop dictation'**
  String get note_stopDictationSemantics;

  /// No description provided for @dictation_tapToTalk.
  ///
  /// In en, this message translates to:
  /// **'Tap to talk'**
  String get dictation_tapToTalk;

  /// No description provided for @dictation_tapToStop.
  ///
  /// In en, this message translates to:
  /// **'Tap to stop'**
  String get dictation_tapToStop;

  /// Source picker sheet title.
  ///
  /// In en, this message translates to:
  /// **'Add a photo'**
  String get photo_addTitle;

  /// Details form title before saving.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get photo_detailsTitle;

  /// No description provided for @photo_captionLabel.
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get photo_captionLabel;

  /// No description provided for @photo_captionHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Sunset at the harbor'**
  String get photo_captionHint;

  /// No description provided for @photo_placeLabel.
  ///
  /// In en, this message translates to:
  /// **'Place (optional)'**
  String get photo_placeLabel;

  /// No description provided for @photo_placeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Old Town'**
  String get photo_placeHint;

  /// Star award toast.
  ///
  /// In en, this message translates to:
  /// **'+2 ✦ · photo logged'**
  String get toast_photoLogged;

  /// Star award toast after a batch upload.
  ///
  /// In en, this message translates to:
  /// **'+{points} ✦ · {count, plural, =1{1 photo logged} other{{count} photos logged}}'**
  String toast_photosLogged(int points, int count);

  /// No description provided for @photo_uploadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Uploading photos'**
  String get photo_uploadingTitle;

  /// No description provided for @photo_uploadingProgress.
  ///
  /// In en, this message translates to:
  /// **'Uploading {current} of {total}…'**
  String photo_uploadingProgress(int current, int total);

  /// No description provided for @photo_uploadComplete.
  ///
  /// In en, this message translates to:
  /// **'Upload complete'**
  String get photo_uploadComplete;

  /// No description provided for @photo_uploadSummary.
  ///
  /// In en, this message translates to:
  /// **'{success} uploaded, {failed} failed.'**
  String photo_uploadSummary(int success, int failed);

  /// No description provided for @photo_retryFailed.
  ///
  /// In en, this message translates to:
  /// **'Retry failed ({count})'**
  String photo_retryFailed(int count);

  /// No description provided for @photo_locationTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag this photo with its location?'**
  String get photo_locationTitle;

  /// No description provided for @photo_locationBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} can save where a photo was taken so it shows up in your journal and wrap-up. You can still add photos without this.'**
  String photo_locationBody(String appName);

  /// No description provided for @photo_notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get photo_notNow;

  /// No description provided for @photo_allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get photo_allow;

  /// Screen-reader label.
  ///
  /// In en, this message translates to:
  /// **'Delete photo'**
  String get photo_deleteSemantics;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expense_eyebrow;

  /// No description provided for @expense_compareLink.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get expense_compareLink;

  /// No description provided for @expense_searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search memories'**
  String get expense_searchHint;

  /// Sort toggle.
  ///
  /// In en, this message translates to:
  /// **'Latest first'**
  String get expense_sortLatest;

  /// Sort toggle.
  ///
  /// In en, this message translates to:
  /// **'Biggest spender'**
  String get expense_sortBiggest;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Memories'**
  String get expense_memoriesHeader;

  /// Mono counter, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{visible} of {total}'**
  String expense_visibleOf(int visible, int total);

  /// No description provided for @expense_noSearchMatch.
  ///
  /// In en, this message translates to:
  /// **'No memories match your search.'**
  String get expense_noSearchMatch;

  /// No description provided for @expense_loadThreeMore.
  ///
  /// In en, this message translates to:
  /// **'Load 3 more'**
  String get expense_loadThreeMore;

  /// No description provided for @expense_loadMoreRemaining.
  ///
  /// In en, this message translates to:
  /// **'Load more ({count} more)'**
  String expense_loadMoreRemaining(int count);

  /// No description provided for @expense_addExpense.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get expense_addExpense;

  /// No description provided for @expense_emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expense_emptyTitle;

  /// No description provided for @expense_emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add a memory first, then start tracking what you spend on it.'**
  String get expense_emptyBody;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get expense_byCategory;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'All expenses'**
  String get expense_allExpenses;

  /// No description provided for @expense_itemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String expense_itemCount(int count);

  /// Compact trip length on a summary row.
  ///
  /// In en, this message translates to:
  /// **'{days}d'**
  String expense_durationShort(int days);

  /// Mono label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get expense_totalSpent;

  /// Mono label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Per day avg'**
  String get expense_perDayAvg;

  /// Mono label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Biggest category'**
  String get expense_biggestCategory;

  /// No description provided for @expense_pickMemoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a memory above'**
  String get expense_pickMemoryTitle;

  /// No description provided for @expense_pickMemoryBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll see the total, where it went, and every expense as you logged it.'**
  String get expense_pickMemoryBody;

  /// No description provided for @expense_newExpense.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get expense_newExpense;

  /// No description provided for @expense_memoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Memory'**
  String get expense_memoryLabel;

  /// No description provided for @expense_memoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick which memory this belongs to.'**
  String get expense_memoryRequired;

  /// No description provided for @expense_descriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get expense_descriptionLabel;

  /// No description provided for @expense_descriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Sunset dinner'**
  String get expense_descriptionHint;

  /// No description provided for @expense_descriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'What was it?'**
  String get expense_descriptionRequired;

  /// No description provided for @expense_amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expense_amountLabel;

  /// No description provided for @expense_amountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0.'**
  String get expense_amountInvalid;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expense_categoryHeader;

  /// Date picker eyebrow.
  ///
  /// In en, this message translates to:
  /// **'Spent on'**
  String get expense_spentOn;

  /// No description provided for @expense_todayDate.
  ///
  /// In en, this message translates to:
  /// **'Today · {date}'**
  String expense_todayDate(String date);

  /// No description provided for @expense_saveExpense.
  ///
  /// In en, this message translates to:
  /// **'Save expense'**
  String get expense_saveExpense;

  /// No description provided for @expense_catFoodDrinks.
  ///
  /// In en, this message translates to:
  /// **'Food & Drinks'**
  String get expense_catFoodDrinks;

  /// No description provided for @expense_catTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get expense_catTransport;

  /// No description provided for @expense_catAccommodation.
  ///
  /// In en, this message translates to:
  /// **'Accommodation'**
  String get expense_catAccommodation;

  /// No description provided for @expense_catActivities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get expense_catActivities;

  /// No description provided for @expense_catShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get expense_catShopping;

  /// No description provided for @expense_catOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expense_catOther;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Compare'**
  String get compare_eyebrow;

  /// No description provided for @compare_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Which trip cost'**
  String get compare_titleLead;

  /// No description provided for @compare_titleEmphasis.
  ///
  /// In en, this message translates to:
  /// **'what, really?'**
  String get compare_titleEmphasis;

  /// No description provided for @compare_hintPickTwo.
  ///
  /// In en, this message translates to:
  /// **'Pick two memories to put their spending side by side.'**
  String get compare_hintPickTwo;

  /// No description provided for @compare_hintPickSecond.
  ///
  /// In en, this message translates to:
  /// **'Now pick a second one.'**
  String get compare_hintPickSecond;

  /// {a}/{b} are memory names (user content).
  ///
  /// In en, this message translates to:
  /// **'{a} vs {b} — tap either to swap it out.'**
  String compare_hintReady(String a, String b);

  /// No description provided for @compare_needTwo.
  ///
  /// In en, this message translates to:
  /// **'Create at least two memories to compare their spending.'**
  String get compare_needTwo;

  /// No description provided for @compare_doneComparing.
  ///
  /// In en, this message translates to:
  /// **'✕ Done comparing'**
  String get compare_doneComparing;

  /// No description provided for @compare_pickTwo.
  ///
  /// In en, this message translates to:
  /// **'Pick two'**
  String get compare_pickTwo;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Financial comparison'**
  String get compare_tableHeader;

  /// No description provided for @compare_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get compare_total;

  /// No description provided for @compare_perDay.
  ///
  /// In en, this message translates to:
  /// **'Per day'**
  String get compare_perDay;

  /// All names are memory names; amounts come pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} cost about the same overall.'**
  String compare_verdictSame(String a, String b);

  /// No description provided for @compare_verdictSameButPerDay.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b} cost about the same overall, but {higher} ran {perDay}/day higher. {cheaper} was the cheaper trip per day.'**
  String compare_verdictSameButPerDay(
    String a,
    String b,
    String higher,
    String perDay,
    String cheaper,
  );

  /// No description provided for @compare_verdictMore.
  ///
  /// In en, this message translates to:
  /// **'{bigger} cost {total} more overall than {smaller}.'**
  String compare_verdictMore(String bigger, String total, String smaller);

  /// No description provided for @compare_verdictMoreAndPerDay.
  ///
  /// In en, this message translates to:
  /// **'{bigger} cost {total} more overall and ran {perDay}/day higher too. {cheaper} was the cheaper trip per day.'**
  String compare_verdictMoreAndPerDay(
    String bigger,
    String total,
    String perDay,
    String cheaper,
  );

  /// No description provided for @compare_verdictMoreButPerDay.
  ///
  /// In en, this message translates to:
  /// **'{bigger} cost {total} more overall, but {higher} ran {perDay}/day higher. {cheaper} was the cheaper trip per day.'**
  String compare_verdictMoreButPerDay(
    String bigger,
    String total,
    String higher,
    String perDay,
    String cheaper,
  );

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Bonus tasks'**
  String get bonus_eyebrow;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Next memory'**
  String get bonus_nextMemory;

  /// Headline line 1; line 2 is bonus_upcomingEmphasis in italic.
  ///
  /// In en, this message translates to:
  /// **'Your next tray opens'**
  String get bonus_upcomingLead;

  /// Italic headline line 2. weekday is mon…sun; date is the day and month, e.g. '21 October'.
  ///
  /// In en, this message translates to:
  /// **'{weekday, select, mon{Monday} tue{Tuesday} wed{Wednesday} thu{Thursday} fri{Friday} sat{Saturday} other{Sunday}}, {date}'**
  String bonus_upcomingEmphasis(String weekday, String date);

  /// days is 2 or more (1 uses bonus_upcomingBodyTomorrow); title is the memory's own name, unquoted.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{That\'s in 1 day, when {title} begins.} other{That\'s in {days} days, when {title} begins.}} Nothing to do before then.'**
  String bonus_upcomingBody(int days, String title);

  /// title is the memory's own name, unquoted.
  ///
  /// In en, this message translates to:
  /// **'That\'s tomorrow, when {title} begins. Nothing to do before then.'**
  String bonus_upcomingBodyTomorrow(String title);

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'What a tray looks like'**
  String get bonus_trayPreview;

  /// No description provided for @bonus_trayCaption.
  ///
  /// In en, this message translates to:
  /// **'Two small dares a day. Do one, both, or neither. They\'re never homework.'**
  String get bonus_trayCaption;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the way'**
  String get bonus_nothingEyebrow;

  /// Headline line 1.
  ///
  /// In en, this message translates to:
  /// **'Bonus tasks start'**
  String get bonus_nothingLead;

  /// Italic headline line 2 when the user already has stars.
  ///
  /// In en, this message translates to:
  /// **'with your next memory'**
  String get bonus_nothingEmphasisNext;

  /// Italic headline line 2 for a brand-new user.
  ///
  /// In en, this message translates to:
  /// **'with your first memory'**
  String get bonus_nothingEmphasisFirst;

  /// No description provided for @bonus_nothingBody.
  ///
  /// In en, this message translates to:
  /// **'Add one, even a rough one. Dares show up on its first day.'**
  String get bonus_nothingBody;

  /// No description provided for @bonus_brandNewBody.
  ///
  /// In en, this message translates to:
  /// **'A wedding, a weekend away, a birthday dinner. Anything you\'d want to keep.'**
  String get bonus_brandNewBody;

  /// No description provided for @bonus_createMemory.
  ///
  /// In en, this message translates to:
  /// **'Create a memory'**
  String get bonus_createMemory;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Your stars'**
  String get stars_yourStars;

  /// Follows the big star total.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{across 1 memory} other{across {count} memories}}'**
  String stars_acrossMemories(int count);

  /// No description provided for @stars_photos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get stars_photos;

  /// No description provided for @stars_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get stars_notes;

  /// No description provided for @stars_quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get stars_quests;

  /// No description provided for @stars_bonusTasks.
  ///
  /// In en, this message translates to:
  /// **'Bonus tasks'**
  String get stars_bonusTasks;

  /// Mono detail on the Bonus tasks row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 dare} other{{count} dares}}'**
  String stars_bonusCount(int count);

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'By memory'**
  String get stars_byMemory;

  /// No description provided for @stars_allMemories.
  ///
  /// In en, this message translates to:
  /// **'All memories ›'**
  String get stars_allMemories;

  /// Title of the full stars-by-memory list.
  ///
  /// In en, this message translates to:
  /// **'All memories'**
  String get stars_allMemoriesTitle;

  /// Stars from memories that no longer exist.
  ///
  /// In en, this message translates to:
  /// **'Earlier memories'**
  String get stars_earlierMemories;

  /// Memory status in a mono meta line, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Kept'**
  String get stars_statusKept;

  /// Memory status in a mono meta line, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get stars_statusNow;

  /// Memory status in a mono meta line, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get stars_statusUpcoming;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'How stars collect'**
  String get stars_howCollect;

  /// No description provided for @stars_guideIntro.
  ///
  /// In en, this message translates to:
  /// **'Every star you earn shows up here, sorted by where it came from.'**
  String get stars_guideIntro;

  /// No description provided for @stars_guidePhoto.
  ///
  /// In en, this message translates to:
  /// **'A photo'**
  String get stars_guidePhoto;

  /// No description provided for @stars_guideNote.
  ///
  /// In en, this message translates to:
  /// **'A note'**
  String get stars_guideNote;

  /// No description provided for @stars_guideQuest.
  ///
  /// In en, this message translates to:
  /// **'A quest done'**
  String get stars_guideQuest;

  /// No description provided for @stars_guideBonus.
  ///
  /// In en, this message translates to:
  /// **'A bonus task'**
  String get stars_guideBonus;

  /// No description provided for @stars_footer.
  ///
  /// In en, this message translates to:
  /// **'Stars keep count of what you\'ve captured. They aren\'t points to spend, just a record of the memories you made.'**
  String get stars_footer;

  /// Star award toast (spec format).
  ///
  /// In en, this message translates to:
  /// **'+{points} ✦ · dare done'**
  String toast_dareDone(int points);

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'No rush · waits for you'**
  String get bonus_streakSaverHeader;

  /// Mono header / badge, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bonus_completed;

  /// Mono badge, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Completed · Day {day}'**
  String bonus_completedDay(int day);

  /// No description provided for @bonus_openCamera.
  ///
  /// In en, this message translates to:
  /// **'Open camera'**
  String get bonus_openCamera;

  /// No description provided for @bonus_maybeLater.
  ///
  /// In en, this message translates to:
  /// **'Maybe later'**
  String get bonus_maybeLater;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Unlocked · optional'**
  String get bonus_stretchUnlocked;

  /// No description provided for @bonus_bothDone.
  ///
  /// In en, this message translates to:
  /// **'Both done · ✦{stars} today'**
  String bonus_bothDone(int stars);

  /// No description provided for @bonus_newOnesTomorrow.
  ///
  /// In en, this message translates to:
  /// **'New ones tomorrow.'**
  String get bonus_newOnesTomorrow;

  /// No description provided for @notif_promptTitle.
  ///
  /// In en, this message translates to:
  /// **'Get a gentle nudge for your daily dares?'**
  String get notif_promptTitle;

  /// No description provided for @notif_promptBody.
  ///
  /// In en, this message translates to:
  /// **'{appName} can remind you once in the morning and once in the evening when a bonus task is still open — never more than that, and easy to turn off later.'**
  String notif_promptBody(String appName);

  /// Local notification, ~9:00 on a memory day after an active day.
  ///
  /// In en, this message translates to:
  /// **'Two little dares today ✦'**
  String get notif_morningTitle;

  /// No description provided for @notif_morningBody.
  ///
  /// In en, this message translates to:
  /// **'Open the tray and see what today\'s got.'**
  String get notif_morningBody;

  /// Local notification, ~19:00 while a bonus task is still open.
  ///
  /// In en, this message translates to:
  /// **'Still time for a dare'**
  String get notif_eveningTitle;

  /// No description provided for @notif_eveningBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s bonus tasks are waiting.'**
  String get notif_eveningBody;

  /// Local notification on the morning a memory starts.
  ///
  /// In en, this message translates to:
  /// **'Your trip starts today ✦'**
  String get notif_arrivalTitle;

  /// No description provided for @notif_arrivalBody.
  ///
  /// In en, this message translates to:
  /// **'Log the first moment and see what\'s waiting.'**
  String get notif_arrivalBody;

  /// Android notification channel name, shown in system settings.
  ///
  /// In en, this message translates to:
  /// **'Bonus dares'**
  String get notif_channelName;

  /// No description provided for @notif_channelDescription.
  ///
  /// In en, this message translates to:
  /// **'Daily nudges for your trip\'s bonus tasks.'**
  String get notif_channelDescription;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile_eyebrow;

  /// No description provided for @profile_defaultName.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profile_defaultName;

  /// Mono line, uppercased in code; {date} is month + year.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String profile_joined(String date);

  /// No description provided for @profile_logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profile_logOut;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get profile_achievements;

  /// No description provided for @profile_achievementsEarned.
  ///
  /// In en, this message translates to:
  /// **'{earned}/{total} earned'**
  String profile_achievementsEarned(int earned, int total);

  /// No description provided for @profile_updatePhoto.
  ///
  /// In en, this message translates to:
  /// **'Update your photo'**
  String get profile_updatePhoto;

  /// No description provided for @profile_editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile'**
  String get profile_editTitle;

  /// No description provided for @profile_nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profile_nameLabel;

  /// No description provided for @profile_bioLabel.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get profile_bioLabel;

  /// No description provided for @profile_bioHint.
  ///
  /// In en, this message translates to:
  /// **'A line about your travels'**
  String get profile_bioHint;

  /// Stat label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{memory} other{memories}}'**
  String profile_statMemories(int count);

  /// Stat label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{country} other{countries}}'**
  String profile_statCountries(int count);

  /// Stat label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String profile_statDays(int count);

  /// Stat label, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{star} other{stars}}'**
  String profile_statStars(int count);

  /// Tier pill period, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get sub_periodAnnual;

  /// Tier pill period, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get sub_periodMonthly;

  /// Tier pill, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get sub_freePlanPill;

  /// Tier pill; brand word, keep as is.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get sub_proPill;

  /// Mono header, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get sub_header;

  /// No description provided for @sub_proName.
  ///
  /// In en, this message translates to:
  /// **'{appName} Pro'**
  String sub_proName(String appName);

  /// No description provided for @sub_freePlan.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get sub_freePlan;

  /// No description provided for @sub_memoriesKeptMeta.
  ///
  /// In en, this message translates to:
  /// **'{kept} of {cap} memories kept. Upgrade for room to keep going.'**
  String sub_memoriesKeptMeta(int kept, int cap);

  /// Used as {date} in sub_renews* when the date is unknown.
  ///
  /// In en, this message translates to:
  /// **'soon'**
  String get sub_renewsSoon;

  /// No description provided for @sub_renews.
  ///
  /// In en, this message translates to:
  /// **'Renews {date}'**
  String sub_renews(String date);

  /// No description provided for @sub_renewsYearly.
  ///
  /// In en, this message translates to:
  /// **'Renews {date} · {price}/year'**
  String sub_renewsYearly(String date, String price);

  /// No description provided for @sub_renewsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Renews {date} · {price}/month'**
  String sub_renewsMonthly(String date, String price);

  /// No description provided for @sub_trialTerms.
  ///
  /// In en, this message translates to:
  /// **'7 days free, then upgrade. Cancel anytime.'**
  String get sub_trialTerms;

  /// No description provided for @sub_trialTermsYearly.
  ///
  /// In en, this message translates to:
  /// **'7 days free, then {price}/year. Cancel anytime.'**
  String sub_trialTermsYearly(String price);

  /// No description provided for @sub_memoriesKept.
  ///
  /// In en, this message translates to:
  /// **'Memories kept'**
  String get sub_memoriesKept;

  /// No description provided for @sub_unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get sub_unlimited;

  /// No description provided for @sub_ofCap.
  ///
  /// In en, this message translates to:
  /// **'{used} of {cap}'**
  String sub_ofCap(int used, int cap);

  /// No description provided for @sub_photosInMemory.
  ///
  /// In en, this message translates to:
  /// **'Photos in this memory'**
  String get sub_photosInMemory;

  /// No description provided for @sub_noLimit.
  ///
  /// In en, this message translates to:
  /// **'{count} · no limit'**
  String sub_noLimit(int count);

  /// No description provided for @sub_manageHint.
  ///
  /// In en, this message translates to:
  /// **'Opens your store\'s subscription settings. Changes and cancellations happen there.'**
  String get sub_manageHint;

  /// No description provided for @sub_restore.
  ///
  /// In en, this message translates to:
  /// **'Restore purchases'**
  String get sub_restore;

  /// No description provided for @sub_restored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored'**
  String get sub_restored;

  /// No description provided for @sub_nothingToRestore.
  ///
  /// In en, this message translates to:
  /// **'Nothing to restore on this account'**
  String get sub_nothingToRestore;

  /// No description provided for @sub_upgradeToPro.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Pro'**
  String get sub_upgradeToPro;

  /// No description provided for @sub_manage.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get sub_manage;

  /// No description provided for @sub_noSubscription.
  ///
  /// In en, this message translates to:
  /// **'No subscription found to manage.'**
  String get sub_noSubscription;

  /// No description provided for @sub_cantOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Could not open subscription settings.'**
  String get sub_cantOpenSettings;

  /// No description provided for @paywall_subMemoryCap.
  ///
  /// In en, this message translates to:
  /// **'Your three free memories are full. Upgrade to keep every trip you take, not just three.'**
  String get paywall_subMemoryCap;

  /// No description provided for @paywall_subPhotoCap.
  ///
  /// In en, this message translates to:
  /// **'This memory is full at 40 photos. Upgrade for unlimited photos on every trip.'**
  String get paywall_subPhotoCap;

  /// No description provided for @paywall_subProfile.
  ///
  /// In en, this message translates to:
  /// **'Every memory deserves a place to live. Upgrade any time for unlimited room.'**
  String get paywall_subProfile;

  /// No description provided for @paywall_trialStarted.
  ///
  /// In en, this message translates to:
  /// **'Trial started · 7 days free'**
  String get paywall_trialStarted;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{appName} Pro'**
  String paywall_brandEyebrow(String appName);

  /// No description provided for @paywall_titleLead.
  ///
  /// In en, this message translates to:
  /// **'Room for every'**
  String get paywall_titleLead;

  /// No description provided for @paywall_titleEmphasis.
  ///
  /// In en, this message translates to:
  /// **'memory you make'**
  String get paywall_titleEmphasis;

  /// No description provided for @paywall_perkMemories.
  ///
  /// In en, this message translates to:
  /// **'Unlimited memories'**
  String get paywall_perkMemories;

  /// No description provided for @paywall_perkMemoriesDetail.
  ///
  /// In en, this message translates to:
  /// **'Keep every trip instead of choosing three.'**
  String get paywall_perkMemoriesDetail;

  /// No description provided for @paywall_perkPhotos.
  ///
  /// In en, this message translates to:
  /// **'Unlimited photos per memory'**
  String get paywall_perkPhotos;

  /// No description provided for @paywall_perkPhotosDetail.
  ///
  /// In en, this message translates to:
  /// **'No 40-photo ceiling on a good week.'**
  String get paywall_perkPhotosDetail;

  /// No description provided for @paywall_perkExport.
  ///
  /// In en, this message translates to:
  /// **'HD film export'**
  String get paywall_perkExport;

  /// No description provided for @paywall_perkExportDetail.
  ///
  /// In en, this message translates to:
  /// **'Save the wrap-up in full quality. Coming soon.'**
  String get paywall_perkExportDetail;

  /// No description provided for @paywall_perkPriority.
  ///
  /// In en, this message translates to:
  /// **'Priority wrap-up generation'**
  String get paywall_perkPriority;

  /// No description provided for @paywall_perkPriorityDetail.
  ///
  /// In en, this message translates to:
  /// **'Your film jumps the queue.'**
  String get paywall_perkPriorityDetail;

  /// No description provided for @paywall_planAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get paywall_planAnnual;

  /// No description provided for @paywall_planMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get paywall_planMonthly;

  /// No description provided for @paywall_perYear.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get paywall_perYear;

  /// No description provided for @paywall_perMonth.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get paywall_perMonth;

  /// Mono line, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'{price} a month'**
  String paywall_perMonthEquivalent(String price);

  /// Mono badge, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String paywall_savePercent(int percent);

  /// No description provided for @paywall_termsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Terms · Privacy'**
  String get paywall_termsPrivacy;

  /// No description provided for @paywall_trialTermsYearly.
  ///
  /// In en, this message translates to:
  /// **'Free for 7 days, then {price}/year. Cancel anytime in Settings.'**
  String paywall_trialTermsYearly(String price);

  /// No description provided for @paywall_trialTermsMonthly.
  ///
  /// In en, this message translates to:
  /// **'Free for 7 days, then {price}/month. Cancel anytime in Settings.'**
  String paywall_trialTermsMonthly(String price);

  /// No description provided for @paywall_startTrial.
  ///
  /// In en, this message translates to:
  /// **'Start 7-day free trial'**
  String get paywall_startTrial;

  /// No description provided for @paywall_reassurance.
  ///
  /// In en, this message translates to:
  /// **'Your three free memories stay yours either way: nothing is deleted or locked if you don\'t upgrade.'**
  String get paywall_reassurance;

  /// No description provided for @wrapUp_openJournal.
  ///
  /// In en, this message translates to:
  /// **'Open journal'**
  String get wrapUp_openJournal;

  /// No description provided for @wrapUp_keepForever.
  ///
  /// In en, this message translates to:
  /// **'Keep forever'**
  String get wrapUp_keepForever;

  /// Film HUD primary button on a kept memory: replaces the film with the Kept Memory page (#279).
  ///
  /// In en, this message translates to:
  /// **'Open memory'**
  String get wrapUp_openMemory;

  /// Film HUD primary button when the film was opened from the Kept Memory page (#279).
  ///
  /// In en, this message translates to:
  /// **'Back to memory'**
  String get wrapUp_backToMemory;

  /// Kept Memory hero meta segment (#279); shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String keptMemory_noteCount(int count);

  /// No description provided for @keptMemory_playFilm.
  ///
  /// In en, this message translates to:
  /// **'Play the film'**
  String get keptMemory_playFilm;

  /// Kept Memory page button and photo viewer toggle: plays every photo automatically.
  ///
  /// In en, this message translates to:
  /// **'Slideshow'**
  String get keptMemory_slideshow;

  /// Photo viewer toggle while the slideshow plays.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get keptMemory_pause;

  /// Day chapter header, followed by · and the date; shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'Day {day}'**
  String keptMemory_day(int day);

  /// No description provided for @keptMemory_plan.
  ///
  /// In en, this message translates to:
  /// **'The plan'**
  String get keptMemory_plan;

  /// Plan card header count; shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} done'**
  String keptMemory_planDone(int done, int total);

  /// Short day label at the end of a plan row (D2 = day 2).
  ///
  /// In en, this message translates to:
  /// **'D{day}'**
  String keptMemory_planDay(int day);

  /// Kept Memory page footer; shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'Kept forever · since {date}'**
  String keptMemory_since(String date);

  /// Semantics label for the hero's ⋯ button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get keptMemory_more;

  /// Photo viewer top bar; shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'Day {day} · {position} / {total}'**
  String keptMemory_viewerPosition(int day, int position, int total);

  /// Photo viewer pill on a photo that completed a bonus task. {prompt} is the task's title.
  ///
  /// In en, this message translates to:
  /// **'Dare · {prompt} · ✦{stars}'**
  String keptMemory_bonusTag(String prompt, int stars);

  /// Film footnote label under a number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{photograph} other{photographs}}'**
  String wrapUp_photographs(int count);

  /// Film footnote label under a number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{bonus task} other{bonus tasks}}'**
  String wrapUp_bonusTasks(int count);

  /// Film footnote label under a number.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{star} other{stars}}'**
  String wrapUp_stars(int count);

  /// No description provided for @wrapUp_footnoteClosing.
  ///
  /// In en, this message translates to:
  /// **'None of which is the reason you\'ll remember it.'**
  String get wrapUp_footnoteClosing;

  /// No description provided for @wrapUp_generating1.
  ///
  /// In en, this message translates to:
  /// **'Reliving your memory…'**
  String get wrapUp_generating1;

  /// No description provided for @wrapUp_generating2.
  ///
  /// In en, this message translates to:
  /// **'Finding the best moments…'**
  String get wrapUp_generating2;

  /// No description provided for @wrapUp_generating3.
  ///
  /// In en, this message translates to:
  /// **'Writing the story…'**
  String get wrapUp_generating3;

  /// No description provided for @wrapUp_generating4.
  ///
  /// In en, this message translates to:
  /// **'Almost ready…'**
  String get wrapUp_generating4;

  /// Mono header on You, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_header;

  /// No description provided for @settings_language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settings_language;

  /// No description provided for @language_systemDefault.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get language_systemDefault;

  /// No description provided for @language_sheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Changes apply right away.'**
  String get language_sheetSubtitle;

  /// No description provided for @language_footer.
  ///
  /// In en, this message translates to:
  /// **'Only the app\'s labels change. Your notes, titles and captions stay exactly as you wrote them.'**
  String get language_footer;

  /// Toast after switching, shown in the NEW language; {name} is language_selfName.
  ///
  /// In en, this message translates to:
  /// **'Language: {name}'**
  String language_toast(String name);

  /// This language's own name as used mid-sentence (lowercase in ru/et).
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_selfName;

  /// A language's name in the UI language, under its native name in the sheet.
  ///
  /// In en, this message translates to:
  /// **'{lang, select, en{English} ru{Russian} et{Estonian} other{English}}'**
  String language_name(String lang);

  /// Subtitle under System default. platform: ios | android | other.
  ///
  /// In en, this message translates to:
  /// **'{platform, select, ios{Follows your iPhone} android{Follows your Android} other{Follows your device}} — {lang, select, en{English} ru{Russian} et{Estonian} other{English}} right now'**
  String language_systemFollows(String platform, String lang);

  /// Dictation language sheet title (spec copy table).
  ///
  /// In en, this message translates to:
  /// **'Speak in…'**
  String get dictation_title;

  /// {lang} is the current UI language code.
  ///
  /// In en, this message translates to:
  /// **'Only changes dictation. The app stays in {lang, select, en{English} ru{Russian} et{Estonian} other{English}}.'**
  String dictation_sheetSubtitle(String lang);

  /// Disabled row in the sheet. platform: ios | android | other.
  ///
  /// In en, this message translates to:
  /// **'{lang, select, en{English} ru{Russian} et{Estonian} other{English}} · not available for speech on this {platform, select, ios{iPhone} android{phone} other{device}}. You can still type in {lang, select, en{English} ru{Russian} et{Estonian} other{English}}.'**
  String dictation_unavailableRow(String lang, String platform);

  /// Sheet footer (spec copy table).
  ///
  /// In en, this message translates to:
  /// **'We\'ll remember this for your next note.'**
  String get dictation_remember;

  /// Label under the disabled mic (spec copy table).
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get dictation_notAvailable;

  /// Inline warning above the dock; followed by dictation_chooseAnother as a link.
  ///
  /// In en, this message translates to:
  /// **'{lang, select, en{English} ru{Russian} et{Estonian} other{English}} speech recognition isn\'t available on this {platform, select, ios{iPhone} android{phone} other{device}}.'**
  String dictation_unavailableWarning(String lang, String platform);

  /// No description provided for @dictation_chooseAnother.
  ///
  /// In en, this message translates to:
  /// **'Choose another language'**
  String get dictation_chooseAnother;

  /// Screen-reader label for the dock chip.
  ///
  /// In en, this message translates to:
  /// **'Dictation language: {name}'**
  String dictation_languageSemantics(String name);

  /// Body placeholder when the dictation language isn't available (design 2d).
  ///
  /// In en, this message translates to:
  /// **'Keep typing — or pick another language and speak.'**
  String get note_bodyHintUnavailable;

  /// Mono status line, uppercased in code; {code} is the 2-letter dictation language.
  ///
  /// In en, this message translates to:
  /// **'Listening · {code} · {time}'**
  String note_listeningIn(String code, String time);

  /// Compact word count under the dock chip (design 2a). @maxLength 6
  ///
  /// In en, this message translates to:
  /// **'{count} W'**
  String note_wordCountShort(int count);

  /// Seeded bonus task title (DB code worst_photo_of_day).
  ///
  /// In en, this message translates to:
  /// **'The worst photo of the day'**
  String get content_bonus_worst_photo_of_day_title;

  /// Seeded bonus task detail (DB code worst_photo_of_day).
  ///
  /// In en, this message translates to:
  /// **'Not your best angle. Not your best moment. That\'s the point.'**
  String get content_bonus_worst_photo_of_day_detail;

  /// Seeded bonus task title (DB code something_free).
  ///
  /// In en, this message translates to:
  /// **'Find something free'**
  String get content_bonus_something_free_title;

  /// Seeded bonus task detail (DB code something_free).
  ///
  /// In en, this message translates to:
  /// **'A view, a smile, a street performance: snap whatever cost you nothing today.'**
  String get content_bonus_something_free_detail;

  /// Seeded bonus task title (DB code local_snack).
  ///
  /// In en, this message translates to:
  /// **'Try a snack you can\'t get at home'**
  String get content_bonus_local_snack_title;

  /// Seeded bonus task detail (DB code local_snack).
  ///
  /// In en, this message translates to:
  /// **'Bonus points if you can\'t pronounce it.'**
  String get content_bonus_local_snack_detail;

  /// Seeded bonus task title (DB code menu_mystery).
  ///
  /// In en, this message translates to:
  /// **'Order something you can\'t translate'**
  String get content_bonus_menu_mystery_title;

  /// Seeded bonus task detail (DB code menu_mystery).
  ///
  /// In en, this message translates to:
  /// **'Point at the menu and commit.'**
  String get content_bonus_menu_mystery_detail;

  /// Seeded bonus task title (DB code stranger_kindness).
  ///
  /// In en, this message translates to:
  /// **'Capture a small kindness from a stranger'**
  String get content_bonus_stranger_kindness_title;

  /// Seeded bonus task detail (DB code stranger_kindness).
  ///
  /// In en, this message translates to:
  /// **'A wave, a smile, directions when you were lost.'**
  String get content_bonus_stranger_kindness_detail;

  /// Seeded bonus task title (DB code overheard).
  ///
  /// In en, this message translates to:
  /// **'Photograph what you\'re listening to'**
  String get content_bonus_overheard_title;

  /// Seeded bonus task detail (DB code overheard).
  ///
  /// In en, this message translates to:
  /// **'Street music, a language you don\'t speak, the sound of somewhere new.'**
  String get content_bonus_overheard_detail;

  /// Seeded bonus task title (DB code souvenir_hunt).
  ///
  /// In en, this message translates to:
  /// **'Photograph the tackiest souvenir you can find'**
  String get content_bonus_souvenir_hunt_title;

  /// Seeded bonus task detail (DB code souvenir_hunt).
  ///
  /// In en, this message translates to:
  /// **'You don\'t have to buy it. Just admire it.'**
  String get content_bonus_souvenir_hunt_detail;

  /// Seeded bonus task title (DB code sky_moment).
  ///
  /// In en, this message translates to:
  /// **'Catch the sky doing something'**
  String get content_bonus_sky_moment_title;

  /// Seeded bonus task detail (DB code sky_moment).
  ///
  /// In en, this message translates to:
  /// **'Sunset, storm clouds, an unreasonable number of stars.'**
  String get content_bonus_sky_moment_detail;

  /// Seeded bonus task title (DB code local_transport).
  ///
  /// In en, this message translates to:
  /// **'Document how you got around today'**
  String get content_bonus_local_transport_title;

  /// Seeded bonus task detail (DB code local_transport).
  ///
  /// In en, this message translates to:
  /// **'Bus, bike, boat, blistered feet — all valid.'**
  String get content_bonus_local_transport_detail;

  /// Seeded bonus task title (DB code unexpected_detour).
  ///
  /// In en, this message translates to:
  /// **'Snap a detour you didn\'t plan'**
  String get content_bonus_unexpected_detour_title;

  /// Seeded bonus task detail (DB code unexpected_detour).
  ///
  /// In en, this message translates to:
  /// **'The wrong turn that turned out fine.'**
  String get content_bonus_unexpected_detour_detail;

  /// Seeded bonus task title (DB code color_hunt).
  ///
  /// In en, this message translates to:
  /// **'Find the most colorful thing around you'**
  String get content_bonus_color_hunt_title;

  /// Seeded bonus task detail (DB code color_hunt).
  ///
  /// In en, this message translates to:
  /// **'A wall, a market stall, someone\'s questionable fashion choice.'**
  String get content_bonus_color_hunt_detail;

  /// Seeded bonus task title (DB code closeup_texture).
  ///
  /// In en, this message translates to:
  /// **'Get up close on a texture'**
  String get content_bonus_closeup_texture_title;

  /// Seeded bonus task detail (DB code closeup_texture).
  ///
  /// In en, this message translates to:
  /// **'Cobblestones, tree bark, the weird pattern on your hotel bedspread.'**
  String get content_bonus_closeup_texture_detail;

  /// Seeded bonus task title (DB code reflection_shot).
  ///
  /// In en, this message translates to:
  /// **'Catch a reflection'**
  String get content_bonus_reflection_shot_title;

  /// Seeded bonus task detail (DB code reflection_shot).
  ///
  /// In en, this message translates to:
  /// **'Water, glass, a suspiciously shiny spoon.'**
  String get content_bonus_reflection_shot_detail;

  /// Seeded bonus task title (DB code halfway_selfie).
  ///
  /// In en, this message translates to:
  /// **'Take a halfway-there selfie'**
  String get content_bonus_halfway_selfie_title;

  /// Seeded bonus task detail (DB code halfway_selfie).
  ///
  /// In en, this message translates to:
  /// **'Tired eyes optional. Big smile mandatory.'**
  String get content_bonus_halfway_selfie_detail;

  /// Seeded bonus task title (DB code local_hangout).
  ///
  /// In en, this message translates to:
  /// **'Photograph where the locals actually hang out'**
  String get content_bonus_local_hangout_title;

  /// Seeded bonus task detail (DB code local_hangout).
  ///
  /// In en, this message translates to:
  /// **'Not the postcard spot but the real one.'**
  String get content_bonus_local_hangout_detail;

  /// Seeded bonus task title (DB code comfort_food).
  ///
  /// In en, this message translates to:
  /// **'Snap the meal that felt like home'**
  String get content_bonus_comfort_food_title;

  /// Seeded bonus task detail (DB code comfort_food).
  ///
  /// In en, this message translates to:
  /// **'Even a thousand miles from it.'**
  String get content_bonus_comfort_food_detail;

  /// Seeded bonus task title (DB code new_skill).
  ///
  /// In en, this message translates to:
  /// **'Try something you\'ve never done before'**
  String get content_bonus_new_skill_title;

  /// Seeded bonus task detail (DB code new_skill).
  ///
  /// In en, this message translates to:
  /// **'A dance move, a dish, a language you\'re butchering on purpose.'**
  String get content_bonus_new_skill_detail;

  /// Seeded bonus task title (DB code market_haul).
  ///
  /// In en, this message translates to:
  /// **'Document a market or shop visit'**
  String get content_bonus_market_haul_title;

  /// Seeded bonus task detail (DB code market_haul).
  ///
  /// In en, this message translates to:
  /// **'What did you almost buy and talk yourself out of?'**
  String get content_bonus_market_haul_detail;

  /// Seeded bonus task title (DB code quiet_moment).
  ///
  /// In en, this message translates to:
  /// **'Capture a quiet moment mid-trip'**
  String get content_bonus_quiet_moment_title;

  /// Seeded bonus task detail (DB code quiet_moment).
  ///
  /// In en, this message translates to:
  /// **'Not everything has to be a highlight reel.'**
  String get content_bonus_quiet_moment_detail;

  /// Seeded bonus task title (DB code view_from_bed).
  ///
  /// In en, this message translates to:
  /// **'Photograph the view from where you\'re staying'**
  String get content_bonus_view_from_bed_title;

  /// Seeded bonus task detail (DB code view_from_bed).
  ///
  /// In en, this message translates to:
  /// **'Balcony, window, or just a very honest ceiling.'**
  String get content_bonus_view_from_bed_detail;

  /// Seeded bonus task title (DB code unplanned_friend).
  ///
  /// In en, this message translates to:
  /// **'Snap someone you met along the way'**
  String get content_bonus_unplanned_friend_title;

  /// Seeded bonus task detail (DB code unplanned_friend).
  ///
  /// In en, this message translates to:
  /// **'A new friend, a fellow traveler, a very opinionated local cat.'**
  String get content_bonus_unplanned_friend_detail;

  /// Seeded bonus task title (DB code touchdown).
  ///
  /// In en, this message translates to:
  /// **'Mark the moment you arrived'**
  String get content_bonus_touchdown_title;

  /// Seeded bonus task detail (DB code touchdown).
  ///
  /// In en, this message translates to:
  /// **'Airport sign, train platform, that first breath of new air.'**
  String get content_bonus_touchdown_detail;

  /// Seeded bonus task title (DB code first_impression).
  ///
  /// In en, this message translates to:
  /// **'Snap your very first impression'**
  String get content_bonus_first_impression_title;

  /// Seeded bonus task detail (DB code first_impression).
  ///
  /// In en, this message translates to:
  /// **'The view, the smell, the chaos just capture it before it becomes normal.'**
  String get content_bonus_first_impression_detail;

  /// Seeded bonus task title (DB code unpacking_ritual).
  ///
  /// In en, this message translates to:
  /// **'Photograph your unpacking ritual'**
  String get content_bonus_unpacking_ritual_title;

  /// Seeded bonus task detail (DB code unpacking_ritual).
  ///
  /// In en, this message translates to:
  /// **'However messy. However fast.'**
  String get content_bonus_unpacking_ritual_detail;

  /// Seeded bonus task title (DB code last_look).
  ///
  /// In en, this message translates to:
  /// **'Take one last look before you go'**
  String get content_bonus_last_look_title;

  /// Seeded bonus task detail (DB code last_look).
  ///
  /// In en, this message translates to:
  /// **'The view, the room, the spot you\'ll miss most.'**
  String get content_bonus_last_look_detail;

  /// Seeded bonus task title (DB code farewell_meal).
  ///
  /// In en, this message translates to:
  /// **'Capture your final meal here'**
  String get content_bonus_farewell_meal_title;

  /// Seeded bonus task detail (DB code farewell_meal).
  ///
  /// In en, this message translates to:
  /// **'Make it count or make it whatever\'s left in the fridge.'**
  String get content_bonus_farewell_meal_detail;

  /// Seeded bonus task title (DB code souvenir_final).
  ///
  /// In en, this message translates to:
  /// **'Photograph what you\'re bringing home'**
  String get content_bonus_souvenir_final_title;

  /// Seeded bonus task detail (DB code souvenir_final).
  ///
  /// In en, this message translates to:
  /// **'Physical or otherwise.'**
  String get content_bonus_souvenir_final_detail;

  /// Seeded bonus task title (DB code snap_anything).
  ///
  /// In en, this message translates to:
  /// **'Snap anything at all'**
  String get content_bonus_snap_anything_title;

  /// Seeded bonus task detail (DB code snap_anything).
  ///
  /// In en, this message translates to:
  /// **'Seriously. Anything. This one\'s just to get you started.'**
  String get content_bonus_snap_anything_detail;

  /// Seeded bonus task title (DB code snap_suitecase).
  ///
  /// In en, this message translates to:
  /// **'Snap your packing process'**
  String get content_bonus_snap_suitecase_title;

  /// Seeded bonus task detail (DB code snap_suitecase).
  ///
  /// In en, this message translates to:
  /// **'Document the chaos of getting ready for your trip.'**
  String get content_bonus_snap_suitecase_detail;

  /// Seeded bonus task title (DB code stranger_portrait).
  ///
  /// In en, this message translates to:
  /// **'Ask a stranger if you can take their photo'**
  String get content_bonus_stranger_portrait_title;

  /// Seeded bonus task detail (DB code stranger_portrait).
  ///
  /// In en, this message translates to:
  /// **'Bonus vulnerability points. They\'ll probably say yes.'**
  String get content_bonus_stranger_portrait_detail;

  /// Seeded bonus task title (DB code no_phone_hour).
  ///
  /// In en, this message translates to:
  /// **'Go an hour without checking your phone, then tell us what you noticed'**
  String get content_bonus_no_phone_hour_title;

  /// Seeded bonus task detail (DB code no_phone_hour).
  ///
  /// In en, this message translates to:
  /// **'Write it, don\'t just remember it.'**
  String get content_bonus_no_phone_hour_detail;

  /// Seeded bonus task title (DB code try_the_dare).
  ///
  /// In en, this message translates to:
  /// **'Do the thing you keep talking yourself out of'**
  String get content_bonus_try_the_dare_title;

  /// Seeded bonus task detail (DB code try_the_dare).
  ///
  /// In en, this message translates to:
  /// **'You know the one.'**
  String get content_bonus_try_the_dare_detail;

  /// Seeded bonus task title (DB code milestone_week_one).
  ///
  /// In en, this message translates to:
  /// **'One week in. How has this trip changed you already?'**
  String get content_bonus_milestone_week_one_title;

  /// Seeded bonus task detail (DB code milestone_week_one).
  ///
  /// In en, this message translates to:
  /// **'A photo and a moment of honesty.'**
  String get content_bonus_milestone_week_one_detail;

  /// Seeded bonus task title (DB code milestone_two_weeks).
  ///
  /// In en, this message translates to:
  /// **'Two weeks deep. What do you know now that you didn\'t at the start?'**
  String get content_bonus_milestone_two_weeks_title;

  /// Seeded bonus task detail (DB code milestone_two_weeks).
  ///
  /// In en, this message translates to:
  /// **'Capture the moment it clicked.'**
  String get content_bonus_milestone_two_weeks_detail;

  /// Seeded bonus task title (DB code milestone_three_weeks).
  ///
  /// In en, this message translates to:
  /// **'Three weeks out. What will you miss most when this ends?'**
  String get content_bonus_milestone_three_weeks_title;

  /// Seeded bonus task detail (DB code milestone_three_weeks).
  ///
  /// In en, this message translates to:
  /// **'Say it before you have to.'**
  String get content_bonus_milestone_three_weeks_detail;

  /// Seeded bonus task title (DB code streak_saver_checkin).
  ///
  /// In en, this message translates to:
  /// **'Just check in'**
  String get content_bonus_streak_saver_checkin_title;

  /// Seeded bonus task detail (DB code streak_saver_checkin).
  ///
  /// In en, this message translates to:
  /// **'No pressure, no theme just one photo of wherever you are right now.'**
  String get content_bonus_streak_saver_checkin_detail;

  /// Achievement title (DB code first_adventure).
  ///
  /// In en, this message translates to:
  /// **'First Adventure'**
  String get content_achievement_first_adventure_title;

  /// Achievement description (DB code first_adventure).
  ///
  /// In en, this message translates to:
  /// **'Log your first memory.'**
  String get content_achievement_first_adventure_description;

  /// Achievement title (DB code globetrotter).
  ///
  /// In en, this message translates to:
  /// **'World Wanderer'**
  String get content_achievement_globetrotter_title;

  /// Achievement description (DB code globetrotter).
  ///
  /// In en, this message translates to:
  /// **'Visit 10 countries.'**
  String get content_achievement_globetrotter_description;

  /// Achievement title (DB code century).
  ///
  /// In en, this message translates to:
  /// **'100 Days Deep'**
  String get content_achievement_century_title;

  /// Achievement description (DB code century).
  ///
  /// In en, this message translates to:
  /// **'Capture 100 days of travel.'**
  String get content_achievement_century_description;

  /// Achievement title (DB code star_collector).
  ///
  /// In en, this message translates to:
  /// **'Star Collector'**
  String get content_achievement_star_collector_title;

  /// Achievement description (DB code star_collector).
  ///
  /// In en, this message translates to:
  /// **'Earn 250 stars.'**
  String get content_achievement_star_collector_description;

  /// Achievement title (DB code shutterbug).
  ///
  /// In en, this message translates to:
  /// **'Say Cheese'**
  String get content_achievement_shutterbug_title;

  /// Achievement description (DB code shutterbug).
  ///
  /// In en, this message translates to:
  /// **'Add 50 photos to your memories.'**
  String get content_achievement_shutterbug_description;

  /// Achievement title (DB code storyteller).
  ///
  /// In en, this message translates to:
  /// **'Storyteller'**
  String get content_achievement_storyteller_title;

  /// Achievement description (DB code storyteller).
  ///
  /// In en, this message translates to:
  /// **'Write 20 journal notes.'**
  String get content_achievement_storyteller_description;

  /// Achievement title (DB code jetsetter).
  ///
  /// In en, this message translates to:
  /// **'Wanderlust Certified'**
  String get content_achievement_jetsetter_title;

  /// Achievement description (DB code jetsetter).
  ///
  /// In en, this message translates to:
  /// **'Log 5 memories.'**
  String get content_achievement_jetsetter_description;

  /// Achievement title (DB code legend).
  ///
  /// In en, this message translates to:
  /// **'Legend'**
  String get content_achievement_legend_title;

  /// Achievement description (DB code legend).
  ///
  /// In en, this message translates to:
  /// **'Earn 1000 stars.'**
  String get content_achievement_legend_description;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Passport'**
  String get content_checklist_passport;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Visa documents'**
  String get content_checklist_visa_documents;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Travel insurance'**
  String get content_checklist_travel_insurance;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Boarding passes / tickets'**
  String get content_checklist_boarding_passes_tickets;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'ID card'**
  String get content_checklist_id_card;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Local currency cash'**
  String get content_checklist_local_currency_cash;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Credit / debit cards'**
  String get content_checklist_credit_debit_cards;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Phone charger'**
  String get content_checklist_phone_charger;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Underwear'**
  String get content_checklist_underwear;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Comfortable walking shoes'**
  String get content_checklist_comfortable_walking_shoes;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'T-shirts'**
  String get content_checklist_t_shirts;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Jacket'**
  String get content_checklist_jacket;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Swimsuit'**
  String get content_checklist_swimsuit;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Sleepwear'**
  String get content_checklist_sleepwear;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Sunglasses'**
  String get content_checklist_sunglasses;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Toothbrush & toothpaste'**
  String get content_checklist_toothbrush_toothpaste;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Prescription medications'**
  String get content_checklist_prescription_medications;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'First aid kit'**
  String get content_checklist_first_aid_kit;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Sunscreen'**
  String get content_checklist_sunscreen;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Deodorant'**
  String get content_checklist_deodorant;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Hand sanitizer'**
  String get content_checklist_hand_sanitizer;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Shampoo & conditioner'**
  String get content_checklist_shampoo_conditioner;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Contact lenses or glasses'**
  String get content_checklist_contact_lenses_or_glasses;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get content_checklist_phone;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Charging cables'**
  String get content_checklist_charging_cables;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Power adapter'**
  String get content_checklist_power_adapter;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Portable battery pack'**
  String get content_checklist_portable_battery_pack;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Headphones'**
  String get content_checklist_headphones;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get content_checklist_camera;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'SIM card or eSIM'**
  String get content_checklist_sim_card_or_esim;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Travel pillow'**
  String get content_checklist_travel_pillow;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Reusable water bottle'**
  String get content_checklist_reusable_water_bottle;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get content_checklist_snacks;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Packing cubes'**
  String get content_checklist_packing_cubes;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Earplugs & eye mask'**
  String get content_checklist_earplugs_eye_mask;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Travel journal'**
  String get content_checklist_travel_journal;

  /// Checklist suggestion, written into a new checklist in the UI language.
  ///
  /// In en, this message translates to:
  /// **'Umbrella'**
  String get content_checklist_umbrella;

  /// Eyebrow over the photo viewer's film-pick panel (#294); shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'In the film'**
  String get film_inTheFilm;

  /// Film-pick segment: the generator decides whether the photo is in the film (#294).
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get film_pickAuto;

  /// Film-pick segment: the photo always gets a main moment (#294).
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get film_pickAlways;

  /// Film-pick segment: the photo never appears in the film (#294).
  ///
  /// In en, this message translates to:
  /// **'Leave out'**
  String get film_pickNever;

  /// Film-pick hint: on Auto, and the film gives it a main moment (#294).
  ///
  /// In en, this message translates to:
  /// **'Film chose this one'**
  String get film_hintAutoPicked;

  /// Film-pick hint: on Auto, but not one of the film's main moments (#294).
  ///
  /// In en, this message translates to:
  /// **'Not picked right now'**
  String get film_hintAutoNot;

  /// Film-pick hint for Always (#294).
  ///
  /// In en, this message translates to:
  /// **'Your pick · gets a main moment'**
  String get film_hintAlways;

  /// Film-pick hint for Leave out (#294).
  ///
  /// In en, this message translates to:
  /// **'Won\'t appear anywhere'**
  String get film_hintNever;

  /// Toast after switching a photo to Always (#294).
  ///
  /// In en, this message translates to:
  /// **'Always in the film'**
  String get film_toastAlways;

  /// Toast after switching a photo to Leave out (#294).
  ///
  /// In en, this message translates to:
  /// **'Left out of the film'**
  String get film_toastNever;

  /// Toast after switching a photo back to Auto (#294).
  ///
  /// In en, this message translates to:
  /// **'Film picks this one'**
  String get film_toastAuto;

  /// Pill over a left-out photo in the photo viewer (#294).
  ///
  /// In en, this message translates to:
  /// **'Left out of the film'**
  String get film_leftOutPill;

  /// Journal photo strip, right of the header: that day's photos in the film (#294); shown uppercase.
  ///
  /// In en, this message translates to:
  /// **'{count} in the film'**
  String film_stripCount(int count);

  /// Journal thumbnail badge for an Always photo (#294).
  ///
  /// In en, this message translates to:
  /// **'Your pick'**
  String get film_badgeYourPick;

  /// Journal thumbnail badge for a left-out photo (#294).
  ///
  /// In en, this message translates to:
  /// **'Left out'**
  String get film_badgeLeftOut;

  /// Chip on a kept film after its photos or picks changed; tapping rebuilds it (#294).
  ///
  /// In en, this message translates to:
  /// **'Photos changed · Rebuild film'**
  String get film_outOfDate;
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
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
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
