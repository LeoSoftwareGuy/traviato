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

  @override
  String get common_edit => 'Muuda';

  @override
  String get common_delete => 'Kustuta';

  @override
  String get common_save => 'Salvesta';

  @override
  String get toast_questDone => '+1 ✦ · tegevus tehtud';

  @override
  String get toast_packed => '✦ Pakitud — tubli';

  @override
  String get plan_eyebrow => 'Plaan';

  @override
  String plan_daysTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kokku $count päeva',
      one: 'kokku $count päev',
    );
    return '$_temp0';
  }

  @override
  String get plan_noDates =>
      'Lisa mälestusele kuupäevad, et päevi planeerima hakata.';

  @override
  String plan_dayN(int day) {
    return 'Päev $day';
  }

  @override
  String plan_doneCount(int done, int total) {
    return '$done/$total tehtud';
  }

  @override
  String get plan_addQuest => '+ Lisa tegevus';

  @override
  String plan_addQuestToDay(int day) {
    return '+ Lisa tegevus $day. päevale';
  }

  @override
  String get plan_addTitle => 'Lisa tegevus';

  @override
  String get plan_editTitle => 'Muuda tegevust';

  @override
  String get plan_nameLabel => 'Nimi';

  @override
  String get plan_nameHint => 'nt Paki auto';

  @override
  String get plan_nameRequired => 'Anna tegevusele nimi.';

  @override
  String get plan_timeLabel => 'Aeg (valikuline)';

  @override
  String get plan_noTime => 'Aeg määramata';

  @override
  String get plan_detailLabel => 'Üksikasjad (valikuline)';

  @override
  String get plan_detailHint => 'nt Külmakast, tekid, matkasaapad';

  @override
  String get manage_title => 'Muuda mälestust';

  @override
  String get manage_nameLabel => 'Nimi';

  @override
  String get manage_rename => 'Nimeta ümber';

  @override
  String get manage_shiftHint =>
      'Puuduta kuupäeva, et nihutada seda päeva võrra edasi, hoia all, et nihutada tagasi — tegevused liiguvad kaasa.';

  @override
  String get manage_cover => 'Kaanepilt';

  @override
  String get manage_notSet => 'Määramata';

  @override
  String get checklist_title => 'Paki reisiks';

  @override
  String get checklist_emptyCategory => 'Selles kategoorias pole veel midagi.';

  @override
  String get checklist_addHint => 'Lisa midagi omalt poolt…';

  @override
  String get checklist_essential => 'Oluline';

  @override
  String checklist_packedOf(int checked, int total) {
    return '$checked/$total pakitud';
  }

  @override
  String get checklist_catTravelEssentials => 'Reisi põhiasjad';

  @override
  String get checklist_catClothingShoes => 'Riided ja jalanõud';

  @override
  String get checklist_catGadgetsTech => 'Vidinad ja tehnika';

  @override
  String get checklist_catToiletriesHealth => 'Hügieen ja tervis';

  @override
  String get checklist_catNiceToHaves => 'Toredad lisad';

  @override
  String get journal_eyebrow => 'Päevik';

  @override
  String get journal_quietOne => 'Vaikne päev';

  @override
  String journal_dayQuietOne(int day) {
    return 'Päev $day — vaikne päev';
  }

  @override
  String get journal_noEntries => 'Veel pole fotosid ega märkmeid';

  @override
  String journal_questsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tegevust tehtud',
      one: '$count tegevus tehtud',
    );
    return '$_temp0';
  }

  @override
  String journal_dayTitle(int day, String name) {
    return 'Päev $day — $name';
  }

  @override
  String journal_noteStamp(int day, String date) {
    return 'Päev $day · $date';
  }

  @override
  String get journal_noDates =>
      'Lisa mälestusele kuupäevad, et päevikut alustada.';

  @override
  String get journal_dayNotYet => 'See päev pole veel saabunud';

  @override
  String get journal_toDo => 'Tegevused';

  @override
  String get journal_todayToDo => 'Tänased tegevused';

  @override
  String get journal_viewWrapUp => 'Vaata kokkuvõtet';

  @override
  String get journal_photos => 'Fotod';

  @override
  String journal_photosSaved(int count) {
    return 'salvestatud: $count';
  }

  @override
  String get journal_addPhotoTile => 'Lisa ✦2';

  @override
  String journal_wrapUpExplainer(String ask) {
    return 'Filmil on veel vähe materjali. $ask';
  }

  @override
  String journal_wrapUpAskPhotosAndNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lisa veel $count fotot ja üks märge, et film avada.',
      one: 'Lisa veel $count foto ja üks märge, et film avada.',
    );
    return '$_temp0';
  }

  @override
  String journal_wrapUpAskPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lisa veel $count fotot, et film avada.',
      one: 'Lisa veel $count foto, et film avada.',
    );
    return '$_temp0';
  }

  @override
  String get journal_wrapUpAskNote => 'Kirjuta üks märge, et film avada.';

  @override
  String get journal_wrapUpReqPhotos => 'Viis fotot selles mälestuses';

  @override
  String get journal_wrapUpReqNote => 'Vähemalt üks märge kirjutatud';

  @override
  String get journal_wrapUpFree =>
      'Midagi pole vaja osta — see on igas paketis sama.';

  @override
  String get journal_nothingYet => 'Siin pole veel midagi';

  @override
  String journal_nothingFromDay(int day) {
    return '$day. päevast pole veel midagi';
  }

  @override
  String get journal_nudgeBody =>
      'Isegi üks foto aitab kokkuvõtet. Vaiksed päevad jõuavad ka filmi — see lihtsalt vilksatab mööda.';

  @override
  String get journal_addAPhoto => '＋ Lisa foto';

  @override
  String get journal_writeNote => 'Kirjuta märge';

  @override
  String get journal_addNotesToday => '✎ Lisa märkmeid tänase kohta';

  @override
  String get journal_continueEntry => '✎ Jätka sissekannet';

  @override
  String journal_wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sõna',
      one: '$count sõna',
    );
    return '$_temp0';
  }

  @override
  String journal_edited(String time) {
    return 'Muudetud $time';
  }

  @override
  String get toast_noteSaved => '+1 ✦ · märge salvestatud';

  @override
  String get note_discardTitle => 'Kas loobuda lisatust?';

  @override
  String get note_keepWriting => 'Kirjuta edasi';

  @override
  String get note_discard => 'Loobu';

  @override
  String get note_bodyHint =>
      'Jätka — kirjuta või puuduta mikrofoni ja lihtsalt räägi.';

  @override
  String note_wordsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count sõna',
      one: '+$count sõna',
    );
    return '$_temp0';
  }

  @override
  String get note_micOff =>
      'Mikrofon on välja lülitatud. Lülita see seadetes sisse või lihtsalt kirjuta.';

  @override
  String get note_voiceUnavailable =>
      'Häälsisestus pole praegu saadaval — kirjutamine töötab.';

  @override
  String get note_typeSemantics => 'Kirjuta';

  @override
  String get note_dictateSemantics => 'Dikteeri';

  @override
  String get note_stopDictationSemantics => 'Lõpeta dikteerimine';

  @override
  String get dictation_tapToTalk => 'Puuduta ja räägi';

  @override
  String get dictation_tapToStop => 'Puuduta, et lõpetada';

  @override
  String note_listening(String time) {
    return 'Kuulan · $time';
  }

  @override
  String get photo_addTitle => 'Lisa foto';

  @override
  String get photo_detailsTitle => 'Lisa foto';

  @override
  String get photo_captionLabel => 'Allkiri (valikuline)';

  @override
  String get photo_captionHint => 'nt Päikeseloojang sadamas';

  @override
  String get photo_placeLabel => 'Koht (valikuline)';

  @override
  String get photo_placeHint => 'nt Vanalinn';

  @override
  String get toast_photoLogged => '+2 ✦ · foto lisatud';

  @override
  String toast_photosLogged(int points, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count fotot lisatud',
      one: '$count foto lisatud',
    );
    return '+$points ✦ · $_temp0';
  }

  @override
  String get photo_uploadingTitle => 'Laadime fotosid üles';

  @override
  String photo_uploadingProgress(int current, int total) {
    return 'Laadin üles $current/$total…';
  }

  @override
  String get photo_uploadComplete => 'Üleslaadimine lõpetatud';

  @override
  String photo_uploadSummary(int success, int failed) {
    return 'Üles laaditud: $success, ebaõnnestus: $failed.';
  }

  @override
  String photo_retryFailed(int count) {
    return 'Proovi ebaõnnestunuid uuesti ($count)';
  }

  @override
  String get photo_locationTitle => 'Kas lisada fotole asukoht?';

  @override
  String photo_locationBody(String appName) {
    return '$appName saab salvestada, kus foto tehti, et see ilmuks sinu päevikus ja kokkuvõttes. Fotosid saad lisada ka ilma selleta.';
  }

  @override
  String get photo_notNow => 'Mitte praegu';

  @override
  String get photo_allow => 'Luba';

  @override
  String get photo_deleteSemantics => 'Kustuta foto';

  @override
  String get expense_eyebrow => 'Kulud';

  @override
  String get expense_compareLink => 'Võrdle';

  @override
  String get expense_searchHint => 'Otsi mälestusi';

  @override
  String get expense_sortLatest => 'Uuemad enne';

  @override
  String get expense_sortBiggest => 'Suurimad kulud';

  @override
  String get expense_memoriesHeader => 'Mälestused';

  @override
  String expense_visibleOf(int visible, int total) {
    return '$visible/$total';
  }

  @override
  String get expense_noSearchMatch => 'Otsingule ei vasta ükski mälestus.';

  @override
  String get expense_loadThreeMore => 'Näita veel 3';

  @override
  String expense_loadMoreRemaining(int count) {
    return 'Näita veel ($count)';
  }

  @override
  String get expense_addExpense => 'Lisa kulu';

  @override
  String get expense_emptyTitle => 'Kulusid veel pole';

  @override
  String get expense_emptyBody =>
      'Loo esmalt mälestus ja hakka siis kulusid jälgima.';

  @override
  String get expense_byCategory => 'Kategooriate kaupa';

  @override
  String get expense_allExpenses => 'Kõik kulud';

  @override
  String expense_itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kirjet',
      one: '$count kirje',
    );
    return '$_temp0';
  }

  @override
  String expense_durationShort(int days) {
    return '$days p';
  }

  @override
  String get expense_totalSpent => 'Kokku kulutatud';

  @override
  String get expense_perDayAvg => 'Keskmiselt päevas';

  @override
  String get expense_biggestCategory => 'Suurim kategooria';

  @override
  String get expense_pickMemoryTitle => 'Vali ülalt mälestus';

  @override
  String get expense_pickMemoryBody =>
      'Näed kogusummat, kuhu raha läks, ja iga kulu nii, nagu selle kirja panid.';

  @override
  String get expense_newExpense => 'Uus kulu';

  @override
  String get expense_memoryLabel => 'Mälestus';

  @override
  String get expense_memoryRequired =>
      'Vali, millise mälestuse juurde see kuulub.';

  @override
  String get expense_descriptionLabel => 'Kirjeldus';

  @override
  String get expense_descriptionHint => 'Õhtusöök päikeseloojangul';

  @override
  String get expense_descriptionRequired => 'Mille eest?';

  @override
  String get expense_amountLabel => 'Summa';

  @override
  String get expense_amountInvalid => 'Sisesta summa, mis on suurem kui 0.';

  @override
  String get expense_categoryHeader => 'Kategooria';

  @override
  String get expense_spentOn => 'Kuupäev';

  @override
  String expense_todayDate(String date) {
    return 'Täna · $date';
  }

  @override
  String get expense_saveExpense => 'Salvesta kulu';

  @override
  String get expense_catFoodDrinks => 'Söök ja jook';

  @override
  String get expense_catTransport => 'Transport';

  @override
  String get expense_catAccommodation => 'Majutus';

  @override
  String get expense_catActivities => 'Tegevused';

  @override
  String get expense_catShopping => 'Ostlemine';

  @override
  String get expense_catOther => 'Muu';

  @override
  String get compare_eyebrow => 'Võrdlus';

  @override
  String get compare_titleLead => 'Milline reis läks';

  @override
  String get compare_titleEmphasis => 'tegelikult maksma?';

  @override
  String get compare_hintPickTwo =>
      'Vali kaks mälestust, et nende kulusid võrrelda.';

  @override
  String get compare_hintPickSecond => 'Nüüd vali teine.';

  @override
  String compare_hintReady(String a, String b) {
    return '$a vs $b — puuduta kumbagi, et see vahetada.';
  }

  @override
  String get compare_needTwo =>
      'Loo vähemalt kaks mälestust, et kulusid võrrelda.';

  @override
  String get compare_doneComparing => '✕ Lõpeta võrdlus';

  @override
  String get compare_pickTwo => 'Vali kaks';

  @override
  String get compare_tableHeader => 'Kulude võrdlus';

  @override
  String get compare_total => 'Kokku';

  @override
  String get compare_perDay => 'Päevas';

  @override
  String compare_verdictSame(String a, String b) {
    return '$a ja $b läksid kokku umbes sama palju maksma.';
  }

  @override
  String compare_verdictSameButPerDay(
    String a,
    String b,
    String higher,
    String perDay,
    String cheaper,
  ) {
    return '$a ja $b läksid kokku umbes sama palju maksma, kuid $higher puhul kulus päevas $perDay rohkem. $cheaper oli päeva kohta odavam.';
  }

  @override
  String compare_verdictMore(String bigger, String total, String smaller) {
    return '$bigger läks $total rohkem maksma kui $smaller.';
  }

  @override
  String compare_verdictMoreAndPerDay(
    String bigger,
    String total,
    String perDay,
    String cheaper,
  ) {
    return '$bigger läks $total rohkem maksma ja kulus ka päevas $perDay rohkem. $cheaper oli päeva kohta odavam.';
  }

  @override
  String compare_verdictMoreButPerDay(
    String bigger,
    String total,
    String higher,
    String perDay,
    String cheaper,
  ) {
    return '$bigger läks $total rohkem maksma, kuid $higher puhul kulus päevas $perDay rohkem. $cheaper oli päeva kohta odavam.';
  }

  @override
  String get bonus_eyebrow => 'Boonusülesanded';

  @override
  String get bonus_emptyTitle => 'Käimasolevat mälestust veel pole';

  @override
  String get bonus_emptyBody =>
      'Boonusülesanded ilmuvad siia, kui mälestus on alanud.';

  @override
  String get bonus_backHome => 'Avalehele';

  @override
  String toast_dareDone(int points) {
    return '+$points ✦ · ülesanne tehtud';
  }

  @override
  String get bonus_streakSaverHeader => 'Pole kiiret · ootab sind';

  @override
  String get bonus_completed => 'Tehtud';

  @override
  String bonus_completedDay(int day) {
    return 'Tehtud · päev $day';
  }

  @override
  String get bonus_openCamera => 'Ava kaamera';

  @override
  String get bonus_maybeLater => 'Võib-olla hiljem';

  @override
  String get bonus_stretchUnlocked => 'Avatud · valikuline';

  @override
  String bonus_bothDone(int stars) {
    return 'Mõlemad tehtud · ✦$stars täna';
  }

  @override
  String get bonus_newOnesTomorrow => 'Uued tulevad homme.';

  @override
  String get notif_promptTitle =>
      'Kas soovid igapäevaste ülesannete kohta õrna meeldetuletust?';

  @override
  String notif_promptBody(String appName) {
    return '$appName saab sulle meelde tuletada hommikul ja õhtul, kui boonusülesanne on veel tegemata — mitte rohkem ja seda on hiljem lihtne välja lülitada.';
  }

  @override
  String get profile_eyebrow => 'Profiil';

  @override
  String get profile_defaultName => 'Rändur';

  @override
  String profile_joined(String date) {
    return 'Liitus $date';
  }

  @override
  String get profile_logOut => 'Logi välja';

  @override
  String get profile_achievements => 'Saavutused';

  @override
  String profile_achievementsEarned(int earned, int total) {
    return '$earned/$total teenitud';
  }

  @override
  String get profile_updatePhoto => 'Uuenda oma fotot';

  @override
  String get profile_editTitle => 'Muuda profiili';

  @override
  String get profile_nameLabel => 'Nimi';

  @override
  String get profile_bioLabel => 'Tutvustus';

  @override
  String get profile_bioHint => 'Üks lause sinu reisidest';

  @override
  String profile_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mälestust',
      one: 'mälestus',
    );
    return '$_temp0';
  }

  @override
  String profile_statCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'riiki',
      one: 'riik',
    );
    return '$_temp0';
  }

  @override
  String profile_statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'päeva',
      one: 'päev',
    );
    return '$_temp0';
  }

  @override
  String profile_statStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tähte',
      one: 'täht',
    );
    return '$_temp0';
  }

  @override
  String get sub_periodAnnual => 'Aastane';

  @override
  String get sub_periodMonthly => 'Kuine';

  @override
  String get sub_freePlanPill => 'Tasuta pakett';

  @override
  String get sub_proPill => 'Pro';

  @override
  String get sub_header => 'Tellimus';

  @override
  String sub_proName(String appName) {
    return '$appName Pro';
  }

  @override
  String get sub_freePlan => 'Tasuta pakett';

  @override
  String sub_memoriesKeptMeta(int kept, int cap) {
    return 'Hoitud mälestusi: $kept/$cap. Vali Pro, et jätkata.';
  }

  @override
  String get sub_renewsSoon => 'varsti';

  @override
  String sub_renews(String date) {
    return 'Uueneb $date';
  }

  @override
  String sub_renewsYearly(String date, String price) {
    return 'Uueneb $date · $price/aastas';
  }

  @override
  String sub_renewsMonthly(String date, String price) {
    return 'Uueneb $date · $price/kuus';
  }

  @override
  String get sub_trialTerms =>
      '7 päeva tasuta, siis tellimus. Saad igal ajal tühistada.';

  @override
  String sub_trialTermsYearly(String price) {
    return '7 päeva tasuta, siis $price/aastas. Saad igal ajal tühistada.';
  }

  @override
  String get sub_memoriesKept => 'Hoitud mälestused';

  @override
  String get sub_unlimited => 'Piiramatu';

  @override
  String sub_ofCap(int used, int cap) {
    return '$used/$cap';
  }

  @override
  String get sub_photosInMemory => 'Fotod selles mälestuses';

  @override
  String sub_noLimit(int count) {
    return '$count · piiranguta';
  }

  @override
  String get sub_manageHint =>
      'Avab poe tellimuse seaded. Muudatused ja tühistamine käivad seal.';

  @override
  String get sub_restore => 'Taasta ostud';

  @override
  String get sub_restored => 'Ostud taastatud';

  @override
  String get sub_nothingToRestore => 'Selle kontoga pole midagi taastada';

  @override
  String get sub_upgradeToPro => 'Vali Pro';

  @override
  String get sub_manage => 'Halda tellimust';

  @override
  String get sub_noSubscription => 'Hallatavat tellimust ei leitud.';

  @override
  String get sub_cantOpenSettings => 'Tellimuse seadeid ei õnnestunud avada.';

  @override
  String get paywall_subMemoryCap =>
      'Kolm tasuta mälestust on täis. Vali Pro, et hoida iga reisi, mitte ainult kolme.';

  @override
  String get paywall_subPhotoCap =>
      'Selles mälestuses on juba 40 fotot. Vali Pro, et lisada piiramatult fotosid.';

  @override
  String get paywall_subProfile =>
      'Iga mälestus väärib oma kohta. Vali Pro millal tahes ja ruumi jätkub kõigeks.';

  @override
  String get paywall_trialStarted => 'Prooviperiood algas · 7 päeva tasuta';

  @override
  String paywall_brandEyebrow(String appName) {
    return '$appName Pro';
  }

  @override
  String get paywall_titleLead => 'Ruumi igale';

  @override
  String get paywall_titleEmphasis => 'sinu mälestusele';

  @override
  String get paywall_perkMemories => 'Piiramatult mälestusi';

  @override
  String get paywall_perkMemoriesDetail =>
      'Hoia iga reisi, selle asemel et valida kolm.';

  @override
  String get paywall_perkPhotos => 'Piiramatult fotosid mälestuse kohta';

  @override
  String get paywall_perkPhotosDetail => 'Heal nädalal pole 40 foto piirangut.';

  @override
  String get paywall_perkExport => 'Filmi HD-eksport';

  @override
  String get paywall_perkExportDetail =>
      'Salvesta kokkuvõte täiskvaliteedis. Tulekul.';

  @override
  String get paywall_perkPriority => 'Kokkuvõtte eelisloomine';

  @override
  String get paywall_perkPriorityDetail =>
      'Sinu film läheb järjekorrast mööda.';

  @override
  String get paywall_planAnnual => 'Aasta';

  @override
  String get paywall_planMonthly => 'Kuu';

  @override
  String get paywall_perYear => 'aastas';

  @override
  String get paywall_perMonth => 'kuus';

  @override
  String paywall_perMonthEquivalent(String price) {
    return '$price kuus';
  }

  @override
  String paywall_savePercent(int percent) {
    return 'Säästa $percent%';
  }

  @override
  String get paywall_termsPrivacy => 'Tingimused · Privaatsus';

  @override
  String paywall_trialTermsYearly(String price) {
    return '7 päeva tasuta, siis $price/aastas. Tühista igal ajal seadetes.';
  }

  @override
  String paywall_trialTermsMonthly(String price) {
    return '7 päeva tasuta, siis $price/kuus. Tühista igal ajal seadetes.';
  }

  @override
  String get paywall_startTrial => 'Alusta 7-päevast tasuta prooviperioodi';

  @override
  String get paywall_reassurance =>
      'Sinu kolm tasuta mälestust jäävad sulle igal juhul — kui Pro-d ei vali, ei kustutata ega lukustata midagi.';

  @override
  String get wrapUp_openJournal => 'Ava päevik';

  @override
  String get wrapUp_keepForever => 'Hoia igavesti';

  @override
  String wrapUp_photographs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'fotot',
      one: 'foto',
    );
    return '$_temp0';
  }

  @override
  String wrapUp_bonusTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'boonusülesannet',
      one: 'boonusülesanne',
    );
    return '$_temp0';
  }

  @override
  String wrapUp_stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'tähte',
      one: 'täht',
    );
    return '$_temp0';
  }

  @override
  String get wrapUp_footnoteClosing =>
      'Kuid mitte sellepärast ei jää see sulle meelde.';

  @override
  String get wrapUp_generating1 => 'Elame reisi uuesti läbi…';

  @override
  String get wrapUp_generating2 => 'Otsime parimaid hetki…';

  @override
  String get wrapUp_generating3 => 'Kirjutame lugu…';

  @override
  String get wrapUp_generating4 => 'Peaaegu valmis…';
}
