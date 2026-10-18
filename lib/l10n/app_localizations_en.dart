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

  @override
  String get common_back => 'Back';

  @override
  String common_dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String common_photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count photos',
      one: '1 photo',
    );
    return '$_temp0';
  }

  @override
  String get auth_logIn => 'Log in';

  @override
  String get auth_createAccount => 'Create account';

  @override
  String get auth_createMyAccount => 'Create my account';

  @override
  String get auth_titleLead => 'Begin your';

  @override
  String get auth_titleEmphasis => 'collection.';

  @override
  String get auth_nameLabel => 'Name';

  @override
  String get auth_nameHint => 'Ada Wong';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'ada@example.com';

  @override
  String get auth_passwordLabel => 'Password';

  @override
  String get auth_confirmPasswordLabel => 'Confirm password';

  @override
  String get auth_nameRequired => 'Enter your name.';

  @override
  String get auth_emailRequired => 'Enter your email.';

  @override
  String get auth_emailInvalid => 'Enter a valid email.';

  @override
  String get auth_passwordRequiredSignup => 'Enter a password.';

  @override
  String get auth_passwordRequiredLogin => 'Enter your password.';

  @override
  String get auth_passwordTooShort => 'At least 6 characters.';

  @override
  String get auth_passwordsMismatch => 'Passwords do not match.';

  @override
  String get auth_showPassword => 'Show';

  @override
  String get auth_hidePassword => 'Hide';

  @override
  String get auth_strengthWeak => 'Weak';

  @override
  String get auth_strengthGood => 'Good';

  @override
  String get auth_strengthStrong => 'Strong';

  @override
  String get auth_privacyNote =>
      'Your memories stay yours — nothing is ever published.';

  @override
  String auth_rewardTease(String stars) {
    return 'Your first memory earns $stars — and the Storyteller badge is only three notes away.';
  }

  @override
  String get auth_rewardTeaseStars => '10 stars';

  @override
  String get auth_or => 'or';

  @override
  String get auth_signInWithApple => 'Sign in with Apple';

  @override
  String get auth_continueWithGoogle => 'Continue with Google';

  @override
  String get auth_checkInbox => 'Check your inbox';

  @override
  String auth_confirmationSent(String email) {
    return 'We sent a confirmation link to $email. Open it on this phone and you\'ll be signed straight in, or confirm anywhere and log in here.';
  }

  @override
  String get auth_backToLogin => 'Back to log in';

  @override
  String auth_resendIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get auth_resendEmail => 'Resend email';

  @override
  String get auth_sentAgain => 'Sent again ✓';

  @override
  String get auth_useDifferentEmail => 'Use a different email';

  @override
  String get guest_eyebrow => 'Your memory companion';

  @override
  String get guest_headlineLead => 'Every memory,';

  @override
  String get guest_headlineEmphasis => 'beautifully captured.';

  @override
  String get guest_body =>
      'From big celebrations to spontaneous little adventures, some moments are just too good to forget. Plan them, live them, and let us turn the best bits into stories you\'ll want to revisit again and again.';

  @override
  String get guest_occasionWeddings => 'Weddings';

  @override
  String get guest_occasionTrips => 'Trips';

  @override
  String get guest_occasionBirthdays => 'Birthdays';

  @override
  String get guest_occasionMilestones => 'Milestones';

  @override
  String get guest_cta => 'Start capturing your moments';

  @override
  String get guest_howTitle => 'Make plans. Make memories. Make them last.';

  @override
  String get guest_stepBeforeEyebrow => 'The before';

  @override
  String get guest_stepBeforeTitle =>
      'Plan the fun. We\'ll handle the details.';

  @override
  String get guest_stepBeforeBody =>
      'Big weekend? Little adventure? Just a Tuesday worth remembering? Map out your plans, make your lists, and keep everything in one happy place.';

  @override
  String get guest_stepDuringEyebrow => 'The during';

  @override
  String get guest_stepDuringTitle => 'Live it up. Jot it down.';

  @override
  String get guest_stepDuringBody =>
      'Snap photos, drop little notes, and take on surprise challenges along the way. The best memories aren\'t always the ones you planned.';

  @override
  String get guest_stepAfterEyebrow => 'The after';

  @override
  String get guest_stepAfterTitle => 'Good times deserve a replay.';

  @override
  String get guest_stepAfterBody =>
      'When the adventure ends, watch your moments come together in a personal highlight film. Relive the magic and keep the memories.';

  @override
  String get guest_sampleMemoriesEyebrow => 'A few memories, kept';

  @override
  String get guest_sampleTokyo => 'Family trip to Tokyo';

  @override
  String get guest_sampleSolo => 'A solo getaway';

  @override
  String get guest_sampleAnniversary => 'Our anniversary';

  @override
  String get guest_sampleGraduation => 'Graduation';

  @override
  String get guest_sampleFood => 'A food lover\'s weekend';

  @override
  String get guest_sampleBucketList => 'A bucket-list moment';
}
