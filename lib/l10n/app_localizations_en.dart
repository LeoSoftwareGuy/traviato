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

  @override
  String get common_today => 'Today';

  @override
  String common_dayOf(int day, int total) {
    return 'Day $day of $total';
  }

  @override
  String common_starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stars',
      one: '1 star',
    );
    return '$_temp0';
  }

  @override
  String get home_defaultName => 'traveler';

  @override
  String home_greeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get home_happeningNow => 'Happening now';

  @override
  String get home_comingUp => 'Coming up';

  @override
  String get home_keptForever => 'Kept forever';

  @override
  String get home_recap => 'Recap';

  @override
  String get home_emptyTitle => 'No memories yet';

  @override
  String get home_emptyBody =>
      'Start your first memory and watch it become a journal you keep forever.';

  @override
  String get home_emptyCta => 'Create your first memory';

  @override
  String get home_keptForeverEmpty =>
      'No memories logged yet — they show up here once a trip wraps.';

  @override
  String home_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'memories',
      one: 'memory',
    );
    return '$_temp0';
  }

  @override
  String home_statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'places',
      one: 'place',
    );
    return '$_temp0';
  }

  @override
  String home_statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String get home_countdownToday => 'today';

  @override
  String home_countdownInDays(int days) {
    return 'in ${days}d';
  }

  @override
  String get home_datesTbd => 'Dates TBD';

  @override
  String home_questsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count quests planned',
      one: '1 quest planned',
    );
    return '$_temp0';
  }

  @override
  String get home_nothingPlanned => 'Nothing planned yet';

  @override
  String get home_planArrow => 'Plan →';

  @override
  String get home_actionPlan => 'Plan';

  @override
  String get home_actionExpenses => 'Expenses';

  @override
  String get home_actionJournal => 'Journal';

  @override
  String get home_checklist => 'Checklist';

  @override
  String home_packedProgress(int packed, int total) {
    return '$packed of $total packed →';
  }

  @override
  String get vibe_romantic => 'Romantic';

  @override
  String get vibe_adventure => 'Adventure';

  @override
  String get vibe_cultural => 'Cultural';

  @override
  String get vibe_chill => 'Chill';

  @override
  String get vibe_foodie => 'Foodie';

  @override
  String get vibe_roadTrip => 'Road trip';

  @override
  String get vibe_wellness => 'Wellness';

  @override
  String get vibe_wildlife => 'Wildlife';

  @override
  String get vibe_nightlife => 'Nightlife';

  @override
  String get vibe_photography => 'Photography';

  @override
  String get trip_newMemory => 'New memory';

  @override
  String get trip_createTitleLead => 'What deserves';

  @override
  String get trip_createTitleEmphasis => 'a memory?';

  @override
  String get trip_nameLabel => 'Name it';

  @override
  String get trip_nameHint => 'e.g. Summer in Tokyo';

  @override
  String get trip_nameRequired => 'Give this memory a name.';

  @override
  String get trip_whereLabel => 'Where did it happen?';

  @override
  String get trip_whereHint => 'Where did this happen?';

  @override
  String get trip_startsLabel => 'Starts';

  @override
  String get trip_endsLabel => 'Ends';

  @override
  String get trip_endBeforeStart => 'End date can\'t be before the start date.';

  @override
  String get trip_vibeLabel => 'The vibe';

  @override
  String trip_vibesChosen(int count) {
    return '$count chosen';
  }

  @override
  String get trip_createCta => 'Create memory';

  @override
  String trip_rewardNudge(String stars) {
    return 'Creating this earns $stars. Log a note each day and you\'ll unlock Storyteller.';
  }

  @override
  String get trip_coverChoose => 'Choose a cover';

  @override
  String get trip_coverChange => 'Change cover';

  @override
  String get trip_coverAutoHint => 'or we\'ll pick one that suits the vibe';

  @override
  String get trip_coverYours => 'Your cover';

  @override
  String trip_coverSuggested(String vibe) {
    return 'Suggested: $vibe';
  }

  @override
  String get trip_coverUploadTitle => 'Upload a cover photo';

  @override
  String get trip_takePhoto => 'Take a photo';

  @override
  String get trip_chooseFromGallery => 'Choose from gallery';

  @override
  String get trip_deleteTitle => 'Delete this memory';

  @override
  String get trip_deleteConfirm => 'Yes — delete it forever';

  @override
  String trip_noteDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days of notes',
      one: '1 day of notes',
    );
    return '$_temp0';
  }

  @override
  String trip_deleteConsequence(String photos, String notes) {
    return 'This removes $photos and $notes. Your earned stars are kept. It can\'t be undone.';
  }

  @override
  String get common_edit => 'Edit';

  @override
  String get common_delete => 'Delete';

  @override
  String get common_save => 'Save';

  @override
  String get toast_questDone => '+1 ✦ · quest done';

  @override
  String get toast_packed => '✦ Packed — nice';

  @override
  String get plan_eyebrow => 'The plan';

  @override
  String plan_daysTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days total',
      one: '1 day total',
    );
    return '$_temp0';
  }

  @override
  String get plan_noDates =>
      'Add dates to this memory to start planning your days.';

  @override
  String plan_dayN(int day) {
    return 'Day $day';
  }

  @override
  String plan_doneCount(int done, int total) {
    return '$done of $total done';
  }

  @override
  String get plan_addQuest => '+ Add a quest';

  @override
  String plan_addQuestToDay(int day) {
    return '+ Add a quest to Day $day';
  }

  @override
  String get plan_addTitle => 'Add plan';

  @override
  String get plan_editTitle => 'Edit plan';

  @override
  String get plan_nameLabel => 'Name this plan';

  @override
  String get plan_nameHint => 'e.g. Pack the car';

  @override
  String get plan_nameRequired => 'Give this plan a name.';

  @override
  String get plan_timeLabel => 'Time (optional)';

  @override
  String get plan_noTime => 'No time set';

  @override
  String get plan_detailLabel => 'Detail (optional)';

  @override
  String get plan_detailHint => 'e.g. Cooler, blankets, hiking boots';

  @override
  String get manage_title => 'Edit this memory';

  @override
  String get manage_nameLabel => 'Name';

  @override
  String get manage_rename => 'Rename';

  @override
  String get manage_shiftHint =>
      'Tap a date to shift it a day forward, hold to shift it back — quests move with it.';

  @override
  String get manage_cover => 'Cover';

  @override
  String get manage_notSet => 'Not set';

  @override
  String get checklist_title => 'Pack for the trip';

  @override
  String get checklist_emptyCategory => 'No items in this category yet.';

  @override
  String get checklist_addHint => 'Add something of your own...';

  @override
  String get checklist_essential => 'Essential';

  @override
  String checklist_packedOf(int checked, int total) {
    return '$checked of $total packed';
  }

  @override
  String get checklist_catTravelEssentials => 'Travel essentials';

  @override
  String get checklist_catClothingShoes => 'Clothing & shoes';

  @override
  String get checklist_catGadgetsTech => 'Gadgets & tech';

  @override
  String get checklist_catToiletriesHealth => 'Toiletries & health';

  @override
  String get checklist_catNiceToHaves => 'Nice-to-haves';
}
