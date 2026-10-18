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

  /// Greeting name when the profile has no username.
  ///
  /// In en, this message translates to:
  /// **'traveler'**
  String get home_defaultName;

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
  /// **'Yes — delete it forever'**
  String get trip_deleteConfirm;

  /// No description provided for @trip_noteDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day of notes} other{{count} days of notes}}'**
  String trip_noteDays(int count);

  /// {photos} is common_photoCount, {notes} is trip_noteDays.
  ///
  /// In en, this message translates to:
  /// **'This removes {photos} and {notes}. Your earned stars are kept. It can\'t be undone.'**
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

  /// No description provided for @manage_shiftHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a date to shift it a day forward, hold to shift it back — quests move with it.'**
  String get manage_shiftHint;

  /// Mono eyebrow, uppercased in code.
  ///
  /// In en, this message translates to:
  /// **'Cover'**
  String get manage_cover;

  /// No description provided for @manage_notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get manage_notSet;

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
