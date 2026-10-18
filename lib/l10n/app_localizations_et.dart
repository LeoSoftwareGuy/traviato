// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Estonian (`et`).
class AppLocalizationsEt extends AppLocalizations {
  AppLocalizationsEt([String locale = 'et']) : super(locale);

  @override
  String get common_cancel => 'Loobu';

  @override
  String get common_done => 'Valmis';

  @override
  String get common_retry => 'Proovi uuesti';

  @override
  String get common_upgrade => 'Uuenda';

  @override
  String get nav_home => 'Avaleht';

  @override
  String get nav_expenses => 'Kulud';

  @override
  String get datePicker_defaultLabel => 'Vali kuupäev';

  @override
  String placeholder_onItsWay(String title) {
    return '$title on tulekul.';
  }

  @override
  String get error_network => 'Kontrolli internetiühendust.';

  @override
  String get error_permission => 'Sul pole selleks õigust.';

  @override
  String get error_notFound => 'Soovitud andmeid ei leitud.';

  @override
  String get error_unknown => 'Tekkis tundmatu viga. Proovi hiljem uuesti.';

  @override
  String get error_freeTierMemories =>
      'Tasuta paketis saab luua kuni 3 mälestust. Piiranguteta mälestuste jaoks vali Pro.';

  @override
  String get error_freeTierPhotos =>
      'Tasuta paketis on ühe mälestuse kohta kuni 40 fotot. Piiranguteta fotode jaoks vali Pro.';

  @override
  String get error_questPlanningClosed =>
      'See mälestus lisati pärast reisi lõppu, seega pole midagi planeerida.';

  @override
  String get error_authLink =>
      'Link on aegunud või juba kasutatud. Kui oled e-posti juba kinnitanud, logi lihtsalt sisse.';

  @override
  String get error_rateLimitedEmail =>
      'Oleme praegu liiga palju kirju saatnud. Proovi veidi aja pärast uuesti.';

  @override
  String get error_rateLimited =>
      'Liiga palju katseid. Oota veidi ja proovi uuesti.';

  @override
  String error_rateLimitedSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Liiga palju katseid. Oota $count sekundit ja proovi uuesti.',
      one: 'Liiga palju katseid. Oota $count sekund ja proovi uuesti.',
    );
    return '$_temp0';
  }

  @override
  String get common_back => 'Tagasi';

  @override
  String common_dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count päeva',
      one: '$count päev',
    );
    return '$_temp0';
  }

  @override
  String common_photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotot',
      one: '$count foto',
    );
    return '$_temp0';
  }

  @override
  String get auth_logIn => 'Logi sisse';

  @override
  String get auth_createAccount => 'Loo konto';

  @override
  String get auth_createMyAccount => 'Loo minu konto';

  @override
  String get auth_titleLead => 'Alusta oma';

  @override
  String get auth_titleEmphasis => 'kogumikku.';

  @override
  String get auth_nameLabel => 'Nimi';

  @override
  String get auth_nameHint => 'Mari Tamm';

  @override
  String get auth_emailLabel => 'E-post';

  @override
  String get auth_emailHint => 'mari@example.com';

  @override
  String get auth_passwordLabel => 'Parool';

  @override
  String get auth_confirmPasswordLabel => 'Korda parooli';

  @override
  String get auth_nameRequired => 'Sisesta oma nimi.';

  @override
  String get auth_emailRequired => 'Sisesta oma e-post.';

  @override
  String get auth_emailInvalid => 'Sisesta kehtiv e-posti aadress.';

  @override
  String get auth_passwordRequiredSignup => 'Sisesta parool.';

  @override
  String get auth_passwordRequiredLogin => 'Sisesta oma parool.';

  @override
  String get auth_passwordTooShort => 'Vähemalt 6 tähemärki.';

  @override
  String get auth_passwordsMismatch => 'Paroolid ei ühti.';

  @override
  String get auth_showPassword => 'Näita';

  @override
  String get auth_hidePassword => 'Peida';

  @override
  String get auth_strengthWeak => 'Nõrk';

  @override
  String get auth_strengthGood => 'Hea';

  @override
  String get auth_strengthStrong => 'Tugev';

  @override
  String get auth_privacyNote =>
      'Sinu mälestused jäävad sulle — midagi ei avaldata.';

  @override
  String auth_rewardTease(String stars) {
    return 'Esimene mälestus toob $stars — ja Jutustaja märgini on vaid kolm märget.';
  }

  @override
  String get auth_rewardTeaseStars => '10 tähte';

  @override
  String get auth_or => 'või';

  @override
  String get auth_signInWithApple => 'Logi sisse Apple\'iga';

  @override
  String get auth_continueWithGoogle => 'Jätka Google\'iga';

  @override
  String get auth_checkInbox => 'Vaata oma postkasti';

  @override
  String auth_confirmationSent(String email) {
    return 'Saatsime kinnituslingi aadressile $email. Ava see selles telefonis ja sind logitakse kohe sisse või kinnita mujal ja logi siin sisse.';
  }

  @override
  String get auth_backToLogin => 'Tagasi sisselogimisse';

  @override
  String auth_resendIn(int seconds) {
    return 'Saada uuesti $seconds s pärast';
  }

  @override
  String get auth_resendEmail => 'Saada kiri uuesti';

  @override
  String get auth_sentAgain => 'Saadetud uuesti ✓';

  @override
  String get auth_useDifferentEmail => 'Kasuta teist e-posti';

  @override
  String get guest_eyebrow => 'Sinu mälestuste kaaslane';

  @override
  String get guest_headlineLead => 'Iga mälestus,';

  @override
  String get guest_headlineEmphasis => 'kaunilt talletatud.';

  @override
  String get guest_body =>
      'Suurtest pidustustest spontaansete väikeste seiklusteni — mõned hetked on liiga head, et unustada. Planeeri neid, ela need läbi ja lase meil muuta parimad palad lugudeks, mille juurde tahad ikka ja jälle naasta.';

  @override
  String get guest_occasionWeddings => 'Pulmad';

  @override
  String get guest_occasionTrips => 'Reisid';

  @override
  String get guest_occasionBirthdays => 'Sünnipäevad';

  @override
  String get guest_occasionMilestones => 'Verstapostid';

  @override
  String get guest_cta => 'Hakka oma hetki talletama';

  @override
  String get guest_howTitle => 'Tee plaane. Loo mälestusi. Hoia neid alles.';

  @override
  String get guest_stepBeforeEyebrow => 'Enne';

  @override
  String get guest_stepBeforeTitle => 'Planeeri lõbu. Detailid jäta meile.';

  @override
  String get guest_stepBeforeBody =>
      'Suur nädalavahetus? Väike seiklus? Või lihtsalt meeldejääv teisipäev? Pane plaanid ja nimekirjad kirja ning hoia kõike ühes toredas kohas.';

  @override
  String get guest_stepDuringEyebrow => 'Ajal';

  @override
  String get guest_stepDuringTitle => 'Ela täiel rinnal. Pane kirja.';

  @override
  String get guest_stepDuringBody =>
      'Tee fotosid, kirjuta väikesi märkmeid ja võta teel vastu üllatusväljakutseid. Parimad mälestused pole alati need, mida planeerisid.';

  @override
  String get guest_stepAfterEyebrow => 'Pärast';

  @override
  String get guest_stepAfterTitle => 'Head hetked väärivad kordust.';

  @override
  String get guest_stepAfterBody =>
      'Kui seiklus lõpeb, saavad sinu hetked kokku isiklikus filmis. Ela võlu uuesti läbi ja hoia mälestused alles.';

  @override
  String get guest_sampleMemoriesEyebrow => 'Mõned talletatud mälestused';

  @override
  String get guest_sampleTokyo => 'Perereis Tokyosse';

  @override
  String get guest_sampleSolo => 'Üksi puhkusele';

  @override
  String get guest_sampleAnniversary => 'Meie aastapäev';

  @override
  String get guest_sampleGraduation => 'Lõpetamine';

  @override
  String get guest_sampleFood => 'Gurmaani nädalavahetus';

  @override
  String get guest_sampleBucketList => 'Unistuste hetk';

  @override
  String get common_today => 'Täna';

  @override
  String common_dayOf(int day, int total) {
    return 'Päev $day/$total';
  }

  @override
  String common_starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tähte',
      one: '$count täht',
    );
    return '$_temp0';
  }

  @override
  String get home_defaultName => 'rändur';

  @override
  String home_greeting(String name) {
    return 'Tere, $name';
  }

  @override
  String get home_happeningNow => 'Praegu käimas';

  @override
  String get home_comingUp => 'Tulekul';

  @override
  String get home_keptForever => 'Igaveseks hoitud';

  @override
  String get home_recap => 'Kokkuvõte';

  @override
  String get home_emptyTitle => 'Mälestusi veel pole';

  @override
  String get home_emptyBody =>
      'Alusta oma esimest mälestust ja vaata, kuidas sellest saab päevik, mida hoiad igavesti.';

  @override
  String get home_emptyCta => 'Loo oma esimene mälestus';

  @override
  String get home_keptForeverEmpty =>
      'Siin pole veel midagi — mälestused ilmuvad siia, kui reis lõpeb.';

  @override
  String home_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mälestust',
      one: 'mälestus',
    );
    return '$_temp0';
  }

  @override
  String home_statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kohta',
      one: 'koht',
    );
    return '$_temp0';
  }

  @override
  String home_statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'päeva',
      one: 'päev',
    );
    return '$_temp0';
  }

  @override
  String get home_countdownToday => 'täna';

  @override
  String home_countdownInDays(int days) {
    return '$days p pärast';
  }

  @override
  String get home_datesTbd => 'Kuupäevad täpsustamata';

  @override
  String home_questsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegevust plaanis',
      one: '$count tegevus plaanis',
    );
    return '$_temp0';
  }

  @override
  String get home_nothingPlanned => 'Veel pole midagi planeeritud';

  @override
  String get home_planArrow => 'Plaan →';

  @override
  String get home_actionPlan => 'Plaan';

  @override
  String get home_actionExpenses => 'Kulud';

  @override
  String get home_actionJournal => 'Päevik';

  @override
  String get home_checklist => 'Nimekiri';

  @override
  String home_packedProgress(int packed, int total) {
    return '$packed/$total pakitud →';
  }

  @override
  String get vibe_romantic => 'Romantika';

  @override
  String get vibe_adventure => 'Seiklus';

  @override
  String get vibe_cultural => 'Kultuur';

  @override
  String get vibe_chill => 'Rahulik';

  @override
  String get vibe_foodie => 'Gurmee';

  @override
  String get vibe_roadTrip => 'Autoreis';

  @override
  String get vibe_wellness => 'Heaolu';

  @override
  String get vibe_wildlife => 'Loodus';

  @override
  String get vibe_nightlife => 'Ööelu';

  @override
  String get vibe_photography => 'Fotograafia';

  @override
  String get trip_newMemory => 'Uus mälestus';

  @override
  String get trip_createTitleLead => 'Mis väärib';

  @override
  String get trip_createTitleEmphasis => 'mälestust?';

  @override
  String get trip_nameLabel => 'Nimi';

  @override
  String get trip_nameHint => 'nt Suvi Tokyos';

  @override
  String get trip_nameRequired => 'Anna mälestusele nimi.';

  @override
  String get trip_whereLabel => 'Kus see toimus?';

  @override
  String get trip_whereHint => 'Kus see aset leidis?';

  @override
  String get trip_startsLabel => 'Algus';

  @override
  String get trip_endsLabel => 'Lõpp';

  @override
  String get trip_endBeforeStart =>
      'Lõppkuupäev ei saa olla enne alguskuupäeva.';

  @override
  String get trip_vibeLabel => 'Meeleolu';

  @override
  String trip_vibesChosen(int count) {
    return 'valitud: $count';
  }

  @override
  String get trip_createCta => 'Loo mälestus';

  @override
  String trip_rewardNudge(String stars) {
    return 'Loomise eest saad $stars. Kirjuta iga päev märge ja avad Jutustaja märgi.';
  }

  @override
  String get trip_coverChoose => 'Vali kaanepilt';

  @override
  String get trip_coverChange => 'Muuda kaanepilti';

  @override
  String get trip_coverAutoHint => 'või valime meeleoluga sobiva';

  @override
  String get trip_coverYours => 'Sinu kaanepilt';

  @override
  String trip_coverSuggested(String vibe) {
    return 'Soovitus: $vibe';
  }

  @override
  String get trip_coverUploadTitle => 'Laadi kaanepilt üles';

  @override
  String get trip_takePhoto => 'Tee foto';

  @override
  String get trip_chooseFromGallery => 'Vali galeriist';

  @override
  String get trip_deleteTitle => 'Kustuta see mälestus';

  @override
  String get trip_deleteConfirm => 'Jah — kustuta jäädavalt';

  @override
  String trip_noteDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count päeva märkmed',
      one: '$count päeva märkmed',
    );
    return '$_temp0';
  }

  @override
  String trip_deleteConsequence(String photos, String notes) {
    return 'See eemaldab $photos ja $notes. Teenitud tähed jäävad alles. Seda ei saa tagasi võtta.';
  }
}
