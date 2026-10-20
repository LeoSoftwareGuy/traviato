// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_done => 'Готово';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_upgrade => 'Улучшить';

  @override
  String get nav_home => 'Главная';

  @override
  String get nav_expenses => 'Расходы';

  @override
  String get datePicker_defaultLabel => 'Выберите дату';

  @override
  String placeholder_onItsWay(String title) {
    return '$title — скоро будет.';
  }

  @override
  String get error_network => 'Проверьте подключение к интернету.';

  @override
  String get error_permission => 'У вас нет доступа.';

  @override
  String get error_notFound => 'Запрошенные данные не найдены.';

  @override
  String get error_unknown => 'Произошла неизвестная ошибка. Попробуйте позже.';

  @override
  String get error_freeTierMemories =>
      'В бесплатном тарифе можно создать до 3 событий. Перейдите на Pro, чтобы снять ограничение.';

  @override
  String get error_freeTierPhotos =>
      'В бесплатном тарифе до 40 фото на одно событие. Перейдите на Pro, чтобы снять ограничение.';

  @override
  String get error_questPlanningClosed =>
      'Это событие добавлено после окончания поездки, поэтому планировать нечего.';

  @override
  String get error_authLink =>
      'Ссылка устарела или уже использована. Если вы уже подтвердили почту, просто войдите.';

  @override
  String get error_rateLimitedEmail =>
      'Мы отправили слишком много писем. Попробуйте чуть позже.';

  @override
  String get error_rateLimited =>
      'Слишком много попыток. Подождите немного и попробуйте снова.';

  @override
  String error_rateLimitedSeconds(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Слишком много попыток. Подождите $count секунды и попробуйте снова.',
      many:
          'Слишком много попыток. Подождите $count секунд и попробуйте снова.',
      few:
          'Слишком много попыток. Подождите $count секунды и попробуйте снова.',
      one:
          'Слишком много попыток. Подождите $count секунду и попробуйте снова.',
    );
    return '$_temp0';
  }

  @override
  String get common_back => 'Назад';

  @override
  String common_dayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String common_photoCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото',
    );
    return '$_temp0';
  }

  @override
  String get auth_logIn => 'Войти';

  @override
  String get auth_createAccount => 'Регистрация';

  @override
  String get auth_createMyAccount => 'Создать аккаунт';

  @override
  String get auth_titleLead => 'Начните свою';

  @override
  String get auth_titleEmphasis => 'коллекцию.';

  @override
  String get auth_nameLabel => 'Имя';

  @override
  String get auth_nameHint => 'Анна Смирнова';

  @override
  String get auth_emailLabel => 'Email';

  @override
  String get auth_emailHint => 'anna@example.com';

  @override
  String get auth_passwordLabel => 'Пароль';

  @override
  String get auth_confirmPasswordLabel => 'Повторите пароль';

  @override
  String get auth_nameRequired => 'Введите имя.';

  @override
  String get auth_emailRequired => 'Введите email.';

  @override
  String get auth_emailInvalid => 'Введите корректный email.';

  @override
  String get auth_passwordRequiredSignup => 'Придумайте пароль.';

  @override
  String get auth_passwordRequiredLogin => 'Введите пароль.';

  @override
  String get auth_passwordTooShort => 'Не менее 6 символов.';

  @override
  String get auth_passwordsMismatch => 'Пароли не совпадают.';

  @override
  String get auth_showPassword => 'Показать';

  @override
  String get auth_hidePassword => 'Скрыть';

  @override
  String get auth_strengthWeak => 'Слабый';

  @override
  String get auth_strengthGood => 'Хороший';

  @override
  String get auth_strengthStrong => 'Надёжный';

  @override
  String get auth_privacyNote =>
      'Ваши воспоминания принадлежат только вам, мы ничего не публикуем.';

  @override
  String auth_rewardTease(String stars) {
    return 'Первое событие принесёт $stars, а до значка «Рассказчик» всего три заметки.';
  }

  @override
  String get auth_rewardTeaseStars => '10 звёзд';

  @override
  String get auth_or => 'или';

  @override
  String get auth_signInWithApple => 'Вход с Apple';

  @override
  String get auth_continueWithGoogle => 'Продолжить с Google';

  @override
  String get auth_checkInbox => 'Проверьте почту';

  @override
  String auth_confirmationSent(String email) {
    return 'Мы отправили ссылку для подтверждения на $email. Откройте её на этом телефоне и вы сразу войдёте, или подтвердите на другом устройстве и войдите здесь.';
  }

  @override
  String get auth_backToLogin => 'Вернуться ко входу';

  @override
  String auth_resendIn(int seconds) {
    return 'Отправить снова через $seconds с';
  }

  @override
  String get auth_resendEmail => 'Отправить письмо снова';

  @override
  String get auth_sentAgain => 'Отправлено ✓';

  @override
  String get auth_useDifferentEmail => 'Указать другой email';

  @override
  String get guest_eyebrow => 'Хранитель ваших воспоминаний';

  @override
  String get guest_headlineLead => 'Каждое воспоминание ';

  @override
  String get guest_headlineEmphasis => 'бережно сохранено.';

  @override
  String get guest_body =>
      'От больших праздников до спонтанных маленьких приключений, некоторые моменты слишком хороши, чтобы их забыть. Планируйте их, проживайте, а мы превратим лучшее в истории, к которым захочется возвращаться снова и снова.';

  @override
  String get guest_occasionWeddings => 'Свадьбы';

  @override
  String get guest_occasionTrips => 'Поездки';

  @override
  String get guest_occasionBirthdays => 'Дни рождения';

  @override
  String get guest_occasionMilestones => 'Важные события';

  @override
  String get guest_cta => 'Начните сохранять свои моменты';

  @override
  String get guest_howTitle => 'Планируйте. Вспоминайте. Сохраняйте навсегда.';

  @override
  String get guest_stepBeforeEyebrow => 'До';

  @override
  String get guest_stepBeforeTitle => 'Планируйте веселье. Детали на нас.';

  @override
  String get guest_stepBeforeBody =>
      'Большие выходные? Маленькое приключение? Или просто вторник, который хочется запомнить? Составляйте планы и ведите дневник — всё в одном уютном месте.';

  @override
  String get guest_stepDuringEyebrow => 'Во время';

  @override
  String get guest_stepDuringTitle => 'Проживайте. Записывайте.';

  @override
  String get guest_stepDuringBody =>
      'Снимайте фото, оставляйте короткие заметки и принимайте неожиданные вызовы по пути. Лучшие воспоминания не всегда те, что вы планировали.';

  @override
  String get guest_stepAfterEyebrow => 'После';

  @override
  String get guest_stepAfterTitle => 'Хорошие моменты стоит пересмотреть.';

  @override
  String get guest_stepAfterBody =>
      'Когда приключение закончится, ваши моменты соберутся в личный фильм. Переживите волшебство снова и сохраните воспоминания.';

  @override
  String get guest_sampleMemoriesEyebrow =>
      'Несколько сохранённых воспоминаний';

  @override
  String get guest_sampleTokyo => 'Семейная поездка в Токио';

  @override
  String get guest_sampleSolo => 'Путешествие в одиночку';

  @override
  String get guest_sampleAnniversary => 'Наша годовщина';

  @override
  String get guest_sampleGraduation => 'Выпускной';

  @override
  String get guest_sampleFood => 'Выходные гурмана';

  @override
  String get guest_sampleBucketList => 'Мечта, ставшая явью';

  @override
  String get common_today => 'Сегодня';

  @override
  String common_dayOf(int day, int total) {
    return 'День $day из $total';
  }

  @override
  String common_starCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count звезды',
      many: '$count звёзд',
      few: '$count звезды',
      one: '$count звезда',
    );
    return '$_temp0';
  }

  @override
  String get home_defaultName => 'путешественник';

  @override
  String home_greeting(String name) {
    return 'Привет, $name';
  }

  @override
  String get home_happeningNow => 'Сейчас';

  @override
  String get home_comingUp => 'Скоро';

  @override
  String get home_keptForever => 'Сохранено навсегда';

  @override
  String get home_recap => 'Итоги';

  @override
  String get home_emptyTitle => 'Пока нет событий';

  @override
  String get home_emptyBody =>
      'Создайте событие, и оно превратится в дневник, который останется с вами навсегда.';

  @override
  String get home_emptyCta => 'Создать первое событие';

  @override
  String get home_keptForeverEmpty =>
      'Пока ничего нет. Завершённые события появятся здесь.';

  @override
  String home_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'события',
      many: 'событий',
      few: 'события',
      one: 'событие',
    );
    return '$_temp0';
  }

  @override
  String home_statPlaces(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'места',
      many: 'мест',
      few: 'места',
      one: 'место',
    );
    return '$_temp0';
  }

  @override
  String home_statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня',
      many: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String get home_countdownToday => 'сегодня';

  @override
  String home_countdownInDays(int days) {
    return 'через $days дн.';
  }

  @override
  String get home_datesTbd => 'Даты не выбраны';

  @override
  String home_questsPlanned(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дела в плане',
      many: '$count дел в плане',
      few: '$count дела в плане',
      one: '$count дело в плане',
    );
    return '$_temp0';
  }

  @override
  String get home_nothingPlanned => 'Пока ничего не запланировано';

  @override
  String get home_planArrow => 'План →';

  @override
  String get home_actionPlan => 'План';

  @override
  String get home_actionExpenses => 'Расходы';

  @override
  String get home_actionJournal => 'Дневник';

  @override
  String get home_checklist => 'Чек-лист';

  @override
  String home_packedProgress(int packed, int total) {
    return 'Собрано $packed из $total →';
  }

  @override
  String get vibe_romantic => 'Романтика';

  @override
  String get vibe_adventure => 'Приключения';

  @override
  String get vibe_cultural => 'Культура';

  @override
  String get vibe_chill => 'Отдых';

  @override
  String get vibe_foodie => 'Гастрономия';

  @override
  String get vibe_roadTrip => 'Автопутешествие';

  @override
  String get vibe_wellness => 'Велнес';

  @override
  String get vibe_wildlife => 'Дикая природа';

  @override
  String get vibe_nightlife => 'Ночная жизнь';

  @override
  String get vibe_photography => 'Фотография';

  @override
  String get trip_newMemory => 'Новое событие';

  @override
  String get trip_createTitleLead => 'Что за';

  @override
  String get trip_createTitleEmphasis => 'событие?';

  @override
  String get trip_nameLabel => 'Название';

  @override
  String get trip_nameHint => 'например, Лето в Токио';

  @override
  String get trip_nameRequired => 'Дайте событию название.';

  @override
  String get trip_whereLabel => 'Где это было?';

  @override
  String get trip_whereHint => 'Где это происходило?';

  @override
  String get trip_startsLabel => 'Начало';

  @override
  String get trip_endsLabel => 'Конец';

  @override
  String get trip_endBeforeStart =>
      'Дата окончания не может быть раньше даты начала.';

  @override
  String get trip_vibeLabel => 'Настроение';

  @override
  String trip_vibesChosen(int count) {
    return 'выбрано: $count';
  }

  @override
  String get trip_createCta => 'Создать событие';

  @override
  String trip_rewardNudge(String stars) {
    return 'Пишите заметки, чтобы заработать $stars и открыть значок «Рассказчик».';
  }

  @override
  String get trip_coverChoose => 'Выберите обложку';

  @override
  String get trip_coverChange => 'Сменить обложку';

  @override
  String get trip_coverAutoHint => 'или мы подберём её под настроение';

  @override
  String get trip_coverYours => 'Ваша обложка';

  @override
  String trip_coverSuggested(String vibe) {
    return 'Предложено: $vibe';
  }

  @override
  String get trip_coverUploadTitle => 'Загрузить фото обложки';

  @override
  String get trip_takePhoto => 'Сделать фото';

  @override
  String get trip_chooseFromGallery => 'Выбрать из галереи';

  @override
  String get trip_deleteTitle => 'Удалить событие';

  @override
  String get trip_deleteConfirm => 'Да! Удалить навсегда';

  @override
  String trip_noteDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня заметок',
      many: '$count дней заметок',
      few: '$count дня заметок',
      one: '$count день заметок',
    );
    return '$_temp0';
  }

  @override
  String trip_deleteConsequence(String photos, String notes) {
    return 'Будут удалены $photos и $notes. Заработанные звёзды исчезнут. Отменить это нельзя.';
  }

  @override
  String get common_edit => 'Изменить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_save => 'Сохранить';

  @override
  String get toast_questDone => '+1 ✦ · дело сделано';

  @override
  String get toast_packed => '✦ Собрано отлично';

  @override
  String get plan_eyebrow => 'План';

  @override
  String plan_daysTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'всего $count дня',
      many: 'всего $count дней',
      few: 'всего $count дня',
      one: 'всего $count день',
    );
    return '$_temp0';
  }

  @override
  String get plan_noDates => 'Добавьте даты, чтобы начать планировать дни.';

  @override
  String plan_dayN(int day) {
    return 'День $day';
  }

  @override
  String plan_doneCount(int done, int total) {
    return 'готово $done из $total';
  }

  @override
  String get plan_addQuest => '+ Добавить дело';

  @override
  String plan_addQuestToDay(int day) {
    return '+ Добавить дело на день $day';
  }

  @override
  String get plan_addTitle => 'Новое дело';

  @override
  String get plan_editTitle => 'Изменить дело';

  @override
  String get plan_nameLabel => 'Название';

  @override
  String get plan_nameHint => 'например, Собрать машину';

  @override
  String get plan_nameRequired => 'Дайте делу название.';

  @override
  String get plan_timeLabel => 'Время (необязательно)';

  @override
  String get plan_noTime => 'Время не задано';

  @override
  String get plan_detailLabel => 'Подробности (необязательно)';

  @override
  String get plan_detailHint => 'например, Холодильник, пледы, ботинки';

  @override
  String get manage_title => 'Изменить событие';

  @override
  String get manage_nameLabel => 'Название';

  @override
  String get manage_rename => 'Переименовать';

  @override
  String get manage_shiftHint =>
      'Нажмите на дату, чтобы сдвинуть её на день вперёд, удерживайте чтобы назад. Дела сдвинутся вместе с ней.';

  @override
  String get manage_cover => 'Обложка';

  @override
  String get manage_notSet => 'Не задано';

  @override
  String get checklist_title => 'Соберитесь в поездку';

  @override
  String get checklist_emptyCategory => 'В этой категории пока ничего нет.';

  @override
  String get checklist_addHint => 'Добавьте что-то своё…';

  @override
  String get checklist_essential => 'Важное';

  @override
  String checklist_packedOf(int checked, int total) {
    return 'Собрано $checked из $total';
  }

  @override
  String get checklist_catTravelEssentials => 'Самое нужное';

  @override
  String get checklist_catClothingShoes => 'Одежда и обувь';

  @override
  String get checklist_catGadgetsTech => 'Гаджеты и техника';

  @override
  String get checklist_catToiletriesHealth => 'Гигиена и здоровье';

  @override
  String get checklist_catNiceToHaves => 'Приятные мелочи';

  @override
  String get journal_eyebrow => 'Дневник';

  @override
  String get journal_quietOne => 'День 1';

  @override
  String journal_dayQuietOne(int day) {
    return 'День $day';
  }

  @override
  String get journal_noEntries => 'Пока ни фото, ни заметок';

  @override
  String journal_questsDone(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сделано $count дела',
      many: 'сделано $count дел',
      few: 'сделано $count дела',
      one: 'сделано $count дело',
    );
    return '$_temp0';
  }

  @override
  String journal_dayTitle(int day, String name) {
    return 'День $day — $name';
  }

  @override
  String journal_noteStamp(int day, String date) {
    return 'День $day · $date';
  }

  @override
  String get journal_noDates => 'Добавьте даты, чтобы начать дневник.';

  @override
  String get journal_dayNotYet => 'Этот день ещё не наступил';

  @override
  String get journal_toDo => 'Дела';

  @override
  String get journal_todayToDo => 'Дела на сегодня';

  @override
  String get journal_viewWrapUp => 'Смотреть итоги';

  @override
  String get journal_photos => 'Фото';

  @override
  String journal_photosSaved(int count) {
    return 'сохранено: $count';
  }

  @override
  String get journal_addPhotoTile => 'Добавить ✦2';

  @override
  String journal_wrapUpExplainer(String ask) {
    return 'Фильму пока не хватает материала. $ask';
  }

  @override
  String journal_wrapUpAskPhotosAndNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавьте ещё $count фото и одну заметку, чтобы открыть фильм.',
    );
    return '$_temp0';
  }

  @override
  String journal_wrapUpAskPhotos(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Добавьте ещё $count фото, чтобы открыть фильм.',
    );
    return '$_temp0';
  }

  @override
  String get journal_wrapUpAskNote =>
      'Напишите одну заметку, чтобы открыть фильм.';

  @override
  String get journal_wrapUpReqPhotos => 'Пять фото в этом событии';

  @override
  String get journal_wrapUpReqNote => 'Хотя бы одна заметка';

  @override
  String get journal_wrapUpFree =>
      'Ничего покупать не нужно — на любом тарифе всё одинаково.';

  @override
  String get journal_nothingYet => 'Как прошёл день?';

  @override
  String journal_nothingFromDay(int day) {
    return 'Как прошёл день?';
  }

  @override
  String get journal_nudgeBody =>
      'Каждое фото и заметка помогут сделать финальный фильм красочнее.';

  @override
  String get journal_addAPhoto => '＋ Добавить фото';

  @override
  String get journal_writeNote => 'Написать заметку';

  @override
  String get journal_addNotesToday => '✎ Добавить заметку о сегодняшнем дне';

  @override
  String get journal_continueEntry => '✎ Продолжить запись';

  @override
  String journal_wordCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count слова',
      many: '$count слов',
      few: '$count слова',
      one: '$count слово',
    );
    return '$_temp0';
  }

  @override
  String journal_edited(String time) {
    return 'Изменено $time';
  }

  @override
  String get toast_noteSaved => '+1 ✦ · заметка сохранена';

  @override
  String get note_discardTitle => 'Удалить добавленное?';

  @override
  String get note_keepWriting => 'Продолжить';

  @override
  String get note_discard => 'Удалить';

  @override
  String get note_bodyHint =>
      'Продолжайте: печатайте или нажмите на микрофон и просто говорите.';

  @override
  String get note_micOff =>
      'Микрофон выключен. Включите его в Настройках или просто печатайте.';

  @override
  String get note_voiceUnavailable =>
      'Голосовой ввод сейчас недоступен но можно печатать.';

  @override
  String get note_typeSemantics => 'Печатать';

  @override
  String get note_dictateSemantics => 'Диктовать';

  @override
  String get note_stopDictationSemantics => 'Остановить диктовку';

  @override
  String get dictation_tapToTalk => 'Нажмите, чтобы говорить';

  @override
  String get dictation_tapToStop => 'Нажмите, чтобы остановить';

  @override
  String get photo_addTitle => 'Добавить фото';

  @override
  String get photo_detailsTitle => 'Новое фото';

  @override
  String get photo_captionLabel => 'Подпись (необязательно)';

  @override
  String get photo_captionHint => 'например, Закат в гавани';

  @override
  String get photo_placeLabel => 'Место (необязательно)';

  @override
  String get photo_placeHint => 'например, Старый город';

  @override
  String get toast_photoLogged => '+2 ✦ · фото добавлено';

  @override
  String toast_photosLogged(int points, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count фото добавлено',
    );
    return '+$points ✦ · $_temp0';
  }

  @override
  String get photo_uploadingTitle => 'Загружаем фото';

  @override
  String photo_uploadingProgress(int current, int total) {
    return 'Загрузка $current из $total…';
  }

  @override
  String get photo_uploadComplete => 'Загрузка завершена';

  @override
  String photo_uploadSummary(int success, int failed) {
    return 'Загружено: $success, с ошибкой: $failed.';
  }

  @override
  String photo_retryFailed(int count) {
    return 'Повторить неудачные ($count)';
  }

  @override
  String get photo_locationTitle => 'Отметить место съёмки?';

  @override
  String photo_locationBody(String appName) {
    return '$appName может сохранять место съёмки, чтобы оно появилось в дневнике и итогах. Фото можно добавлять и без этого.';
  }

  @override
  String get photo_notNow => 'Не сейчас';

  @override
  String get photo_allow => 'Разрешить';

  @override
  String get photo_deleteSemantics => 'Удалить фото';

  @override
  String get expense_eyebrow => 'Расходы';

  @override
  String get expense_compareLink => 'Сравнить';

  @override
  String get expense_searchHint => 'Поиск событий';

  @override
  String get expense_sortLatest => 'Сначала новые';

  @override
  String get expense_sortBiggest => 'Самые затратные';

  @override
  String get expense_memoriesHeader => 'События';

  @override
  String expense_visibleOf(int visible, int total) {
    return '$visible из $total';
  }

  @override
  String get expense_noSearchMatch => 'Ничего не найдено.';

  @override
  String get expense_loadThreeMore => 'Показать ещё 3';

  @override
  String expense_loadMoreRemaining(int count) {
    return 'Показать ещё ($count)';
  }

  @override
  String get expense_addExpense => 'Добавить расход';

  @override
  String get expense_emptyTitle => 'Пока нет расходов';

  @override
  String get expense_emptyBody =>
      'Сначала создайте событие, а потом отмечайте, сколько тратите.';

  @override
  String get expense_byCategory => 'По категориям';

  @override
  String get expense_allExpenses => 'Все расходы';

  @override
  String expense_itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count записи',
      many: '$count записей',
      few: '$count записи',
      one: '$count запись',
    );
    return '$_temp0';
  }

  @override
  String expense_durationShort(int days) {
    return '$days дн.';
  }

  @override
  String get expense_totalSpent => 'Всего потрачено';

  @override
  String get expense_perDayAvg => 'В среднем в день';

  @override
  String get expense_biggestCategory => 'Главная статья';

  @override
  String get expense_pickMemoryTitle => 'Выберите событие выше';

  @override
  String get expense_pickMemoryBody =>
      'Вы увидите итог, на что ушли деньги, и каждый расход так, как вы его записали.';

  @override
  String get expense_newExpense => 'Новый расход';

  @override
  String get expense_memoryLabel => 'Событие';

  @override
  String get expense_memoryRequired =>
      'Выберите, к какому событию это относится.';

  @override
  String get expense_descriptionLabel => 'Описание';

  @override
  String get expense_descriptionHint => 'Ужин на закате';

  @override
  String get expense_descriptionRequired => 'На что потратили?';

  @override
  String get expense_amountLabel => 'Сумма';

  @override
  String get expense_amountInvalid => 'Введите сумму больше 0.';

  @override
  String get expense_categoryHeader => 'Категория';

  @override
  String get expense_spentOn => 'Дата';

  @override
  String expense_todayDate(String date) {
    return 'Сегодня · $date';
  }

  @override
  String get expense_saveExpense => 'Сохранить расход';

  @override
  String get expense_catFoodDrinks => 'Еда и напитки';

  @override
  String get expense_catTransport => 'Транспорт';

  @override
  String get expense_catAccommodation => 'Жильё';

  @override
  String get expense_catActivities => 'Развлечения';

  @override
  String get expense_catShopping => 'Покупки';

  @override
  String get expense_catOther => 'Другое';

  @override
  String get compare_eyebrow => 'Сравнение';

  @override
  String get compare_titleLead => 'Какая поездка обошлась';

  @override
  String get compare_titleEmphasis => 'дороже на самом деле?';

  @override
  String get compare_hintPickTwo =>
      'Выберите два события, чтобы сравнить расходы.';

  @override
  String get compare_hintPickSecond => 'Теперь выберите второе.';

  @override
  String compare_hintReady(String a, String b) {
    return '«$a» и «$b» — нажмите на любое, чтобы заменить.';
  }

  @override
  String get compare_needTwo =>
      'Создайте хотя бы два события, чтобы сравнить расходы.';

  @override
  String get compare_doneComparing => '✕ Закончить';

  @override
  String get compare_pickTwo => 'Выберите два';

  @override
  String get compare_tableHeader => 'Сравнение расходов';

  @override
  String get compare_total => 'Итого';

  @override
  String get compare_perDay => 'В день';

  @override
  String compare_verdictSame(String a, String b) {
    return 'Поездки «$a» и «$b» обошлись примерно одинаково.';
  }

  @override
  String compare_verdictSameButPerDay(
    String a,
    String b,
    String higher,
    String perDay,
    String cheaper,
  ) {
    return 'Поездки «$a» и «$b» обошлись примерно одинаково, но в «$higher» в день уходило на $perDay больше. «$cheaper» — дешевле в пересчёте на день.';
  }

  @override
  String compare_verdictMore(String bigger, String total, String smaller) {
    return 'Поездка «$bigger» обошлась на $total дороже, чем «$smaller».';
  }

  @override
  String compare_verdictMoreAndPerDay(
    String bigger,
    String total,
    String perDay,
    String cheaper,
  ) {
    return 'Поездка «$bigger» обошлась на $total дороже, и в день тоже уходило на $perDay больше. «$cheaper» — дешевле в пересчёте на день.';
  }

  @override
  String compare_verdictMoreButPerDay(
    String bigger,
    String total,
    String higher,
    String perDay,
    String cheaper,
  ) {
    return 'Поездка «$bigger» обошлась на $total дороже, но в «$higher» в день уходило на $perDay больше. «$cheaper» — дешевле в пересчёте на день.';
  }

  @override
  String get bonus_eyebrow => 'Бонусные задания';

  @override
  String get bonus_nextMemory => 'Следующее событие';

  @override
  String get bonus_upcomingLead => 'Новые задания —';

  @override
  String bonus_upcomingEmphasis(String weekday, String date) {
    String _temp0 = intl.Intl.selectLogic(
      weekday,
      {
        'mon': 'в понедельник',
        'tue': 'во вторник',
        'wed': 'в среду',
        'thu': 'в четверг',
        'fri': 'в пятницу',
        'sat': 'в субботу',
        'other': 'в воскресенье',
      },
    );
    return '$_temp0, $date';
  }

  @override
  String bonus_upcomingBody(int days, String title) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'Через $days дня, когда начнётся $title.',
      many: 'Через $days дней, когда начнётся $title.',
      few: 'Через $days дня, когда начнётся $title.',
      one: 'Через $days день, когда начнётся $title.',
    );
    return '$_temp0 До тех пор ничего делать не нужно.';
  }

  @override
  String bonus_upcomingBodyTomorrow(String title) {
    return 'Завтра, когда начнётся $title. До тех пор ничего делать не нужно.';
  }

  @override
  String get bonus_trayPreview => 'Как выглядят задания';

  @override
  String get bonus_trayCaption =>
      'Два маленьких вызова в день. Одно, оба или ни одного — это не домашка.';

  @override
  String get bonus_nothingEyebrow => 'Ничего не запланировано';

  @override
  String get bonus_nothingLead => 'Бонусные задания начнутся';

  @override
  String get bonus_nothingEmphasisNext => 'с вашим следующим событием';

  @override
  String get bonus_nothingEmphasisFirst => 'с вашим первым событием';

  @override
  String get bonus_nothingBody =>
      'Добавьте хотя бы черновик. Задания появятся в первый день.';

  @override
  String get bonus_brandNewBody =>
      'Свадьба, поездка на выходные, ужин в день рождения. Всё, что хочется сохранить.';

  @override
  String get bonus_createMemory => 'Создать событие';

  @override
  String get stars_yourStars => 'Ваши звёзды';

  @override
  String stars_acrossMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'в $count событиях',
      many: 'в $count событиях',
      few: 'в $count событиях',
      one: 'в $count событии',
    );
    return '$_temp0';
  }

  @override
  String get stars_photos => 'Фото';

  @override
  String get stars_notes => 'Заметки';

  @override
  String get stars_quests => 'Квесты';

  @override
  String get stars_bonusTasks => 'Бонусные задания';

  @override
  String stars_bonusCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count шт.',
    );
    return '$_temp0';
  }

  @override
  String get stars_byMemory => 'По событиям';

  @override
  String get stars_allMemories => 'Все события ›';

  @override
  String get stars_allMemoriesTitle => 'Все события';

  @override
  String get stars_earlierMemories => 'Прошлые события';

  @override
  String get stars_statusKept => 'Сохранено';

  @override
  String get stars_statusNow => 'Сейчас';

  @override
  String get stars_statusUpcoming => 'Скоро';

  @override
  String get stars_howCollect => 'Как копятся звёзды';

  @override
  String get stars_guideIntro =>
      'Каждая звезда появится здесь — по тому, откуда она.';

  @override
  String get stars_guidePhoto => 'Фото';

  @override
  String get stars_guideNote => 'Заметка';

  @override
  String get stars_guideQuest => 'Выполненный квест';

  @override
  String get stars_guideBonus => 'Бонусное задание';

  @override
  String get stars_footer =>
      'Звёзды считают то, что вы сохранили. Их не тратят — это просто след ваших воспоминаний.';

  @override
  String toast_dareDone(int points) {
    return '+$points ✦ · задание выполнено';
  }

  @override
  String get bonus_streakSaverHeader => 'Не спешите · подождёт';

  @override
  String get bonus_completed => 'Выполнено';

  @override
  String bonus_completedDay(int day) {
    return 'Выполнено · день $day';
  }

  @override
  String get bonus_openCamera => 'Открыть камеру';

  @override
  String get bonus_maybeLater => 'Может, позже';

  @override
  String get bonus_stretchUnlocked => 'Открыто · по желанию';

  @override
  String bonus_bothDone(int stars) {
    return 'Оба выполнены · ✦$stars сегодня';
  }

  @override
  String get bonus_newOnesTomorrow => 'Новые завтра.';

  @override
  String get notif_promptTitle => 'Напоминать о ежедневных заданиях?';

  @override
  String notif_promptBody(String appName) {
    return '$appName может напомнить утром и вечером, если бонусное задание ещё не выполнено, не чаще, и это легко отключить.';
  }

  @override
  String get notif_morningTitle => 'Два маленьких задания на сегодня ✦';

  @override
  String get notif_morningBody =>
      'Загляните — посмотрите, что приготовил сегодняшний день.';

  @override
  String get notif_eveningTitle => 'Ещё есть время для задания';

  @override
  String get notif_eveningBody => 'Сегодняшние бонусные задания ждут вас.';

  @override
  String get notif_arrivalTitle => 'Ваша поездка начинается сегодня ✦';

  @override
  String get notif_arrivalBody =>
      'Сохраните первый момент и посмотрите, что вас ждёт.';

  @override
  String get notif_channelName => 'Бонусные задания';

  @override
  String get notif_channelDescription =>
      'Ежедневные напоминания о бонусных заданиях поездки.';

  @override
  String get profile_eyebrow => 'Профиль';

  @override
  String get profile_defaultName => 'Путешественник';

  @override
  String profile_joined(String date) {
    return 'С нами с $date';
  }

  @override
  String get profile_logOut => 'Выйти';

  @override
  String get profile_achievements => 'Достижения';

  @override
  String profile_achievementsEarned(int earned, int total) {
    return 'получено $earned/$total';
  }

  @override
  String get profile_updatePhoto => 'Обновить фото';

  @override
  String get profile_editTitle => 'Редактировать профиль';

  @override
  String get profile_nameLabel => 'Имя';

  @override
  String get profile_bioLabel => 'О себе';

  @override
  String get profile_bioHint => 'Пара слов о ваших путешествиях';

  @override
  String profile_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'события',
      many: 'событий',
      few: 'события',
      one: 'событие',
    );
    return '$_temp0';
  }

  @override
  String profile_statCountries(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'страны',
      many: 'стран',
      few: 'страны',
      one: 'страна',
    );
    return '$_temp0';
  }

  @override
  String profile_statDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'дня',
      many: 'дней',
      few: 'дня',
      one: 'день',
    );
    return '$_temp0';
  }

  @override
  String profile_statStars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'звезды',
      many: 'звёзд',
      few: 'звезды',
      one: 'звезда',
    );
    return '$_temp0';
  }

  @override
  String get sub_periodAnnual => 'Годовая';

  @override
  String get sub_periodMonthly => 'Месячная';

  @override
  String get sub_freePlanPill => 'Бесплатный тариф';

  @override
  String get sub_proPill => 'Pro';

  @override
  String get sub_header => 'Подписка';

  @override
  String sub_proName(String appName) {
    return '$appName Pro';
  }

  @override
  String get sub_freePlan => 'Бесплатный тариф';

  @override
  String sub_memoriesKeptMeta(int kept, int cap) {
    return 'Сохранено событий: $kept из $cap. Перейдите на Pro, чтобы сохранять больше.';
  }

  @override
  String get sub_renewsSoon => 'скоро';

  @override
  String sub_renews(String date) {
    return 'Продление $date';
  }

  @override
  String sub_renewsYearly(String date, String price) {
    return 'Продление $date · $price/год';
  }

  @override
  String sub_renewsMonthly(String date, String price) {
    return 'Продление $date · $price/мес.';
  }

  @override
  String get sub_trialTerms =>
      '7 дней бесплатно, потом уже по подписке. Отменить можно в любой момент.';

  @override
  String sub_trialTermsYearly(String price) {
    return '7 дней бесплатно, затем $price/год. Отменить можно в любой момент.';
  }

  @override
  String get sub_memoriesKept => 'Сохранено событий';

  @override
  String get sub_unlimited => 'Без ограничений';

  @override
  String sub_ofCap(int used, int cap) {
    return '$used из $cap';
  }

  @override
  String get sub_photosInMemory => 'Фото в этом событии';

  @override
  String sub_noLimit(int count) {
    return '$count · без лимита';
  }

  @override
  String get sub_manageHint =>
      'Откроются настройки подписки в магазине приложений. Изменить или отменить её можно там.';

  @override
  String get sub_restore => 'Восстановить покупки';

  @override
  String get sub_restored => 'Покупки восстановлены';

  @override
  String get sub_nothingToRestore =>
      'Для этого аккаунта нечего восстанавливать';

  @override
  String get sub_upgradeToPro => 'Перейти на Pro';

  @override
  String get sub_manage => 'Управление подпиской';

  @override
  String get sub_noSubscription => 'Подписка не найдена.';

  @override
  String get sub_cantOpenSettings => 'Не удалось открыть настройки подписки.';

  @override
  String get paywall_subMemoryCap =>
      'Три бесплатных события заняты. Перейдите на Pro, чтобы сохранять каждую поездку, а не только три.';

  @override
  String get paywall_subPhotoCap =>
      'В этом событии уже 40 фото. Перейдите на Pro, чтобы добавлять фото без ограничений.';

  @override
  String get paywall_subProfile =>
      'Каждому событию нужно место. Перейдите на Pro в любой момент и места хватит на всё.';

  @override
  String get paywall_trialStarted => 'Пробный период начат · 7 дней бесплатно';

  @override
  String paywall_brandEyebrow(String appName) {
    return '$appName Pro';
  }

  @override
  String get paywall_titleLead => 'Место для каждого';

  @override
  String get paywall_titleEmphasis => 'вашего воспоминания';

  @override
  String get paywall_perkMemories => 'Безлимит событий';

  @override
  String get paywall_perkMemoriesDetail =>
      'Сохраняйте каждую поездку, а не выбирайте три.';

  @override
  String get paywall_perkPhotos => 'Безлимит фото в событии';

  @override
  String get paywall_perkPhotosDetail =>
      'Никакого потолка в 40 фото за удачную неделю.';

  @override
  String get paywall_perkExport => 'Экспорт фильма в HD';

  @override
  String get paywall_perkExportDetail =>
      'Сохраняйте итоги в полном качестве. Скоро.';

  @override
  String get paywall_perkPriority => 'Приоритетная сборка итогов';

  @override
  String get paywall_perkPriorityDetail => 'Ваш фильм соберётся без очереди.';

  @override
  String get paywall_planAnnual => 'Год';

  @override
  String get paywall_planMonthly => 'Месяц';

  @override
  String get paywall_perYear => 'в год';

  @override
  String get paywall_perMonth => 'в месяц';

  @override
  String paywall_perMonthEquivalent(String price) {
    return '$price в месяц';
  }

  @override
  String paywall_savePercent(int percent) {
    return 'Выгода $percent%';
  }

  @override
  String get paywall_termsPrivacy => 'Условия · Конфиденциальность';

  @override
  String paywall_trialTermsYearly(String price) {
    return '7 дней бесплатно, затем $price/год. Отменить можно в Настройках в любой момент.';
  }

  @override
  String paywall_trialTermsMonthly(String price) {
    return '7 дней бесплатно, затем $price/мес. Отменить можно в Настройках в любой момент.';
  }

  @override
  String get paywall_startTrial => 'Начать 7 дней бесплатно';

  @override
  String get paywall_reassurance =>
      'Три бесплатных события останутся с вами в любом случае — без Pro ничего не удалится и не заблокируется.';

  @override
  String get wrapUp_openJournal => 'Открыть дневник';

  @override
  String get wrapUp_keepForever => 'Сохранить навсегда';

  @override
  String wrapUp_photographs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'фотографии',
      many: 'фотографий',
      few: 'фотографии',
      one: 'фотография',
    );
    return '$_temp0';
  }

  @override
  String wrapUp_bonusTasks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'бонусных задания',
      many: 'бонусных заданий',
      few: 'бонусных задания',
      one: 'бонусное задание',
    );
    return '$_temp0';
  }

  @override
  String wrapUp_stars(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'звезды',
      many: 'звёзд',
      few: 'звезды',
      one: 'звезда',
    );
    return '$_temp0';
  }

  @override
  String get wrapUp_footnoteClosing => 'Но запомните вы её совсем не поэтому.';

  @override
  String get wrapUp_generating1 => 'Переживаем поездку заново…';

  @override
  String get wrapUp_generating2 => 'Ищем лучшие моменты…';

  @override
  String get wrapUp_generating3 => 'Пишем историю…';

  @override
  String get wrapUp_generating4 => 'Почти готово…';

  @override
  String get settings_header => 'Настройки';

  @override
  String get settings_language => 'Язык';

  @override
  String get language_systemDefault => 'Как в системе';

  @override
  String get language_sheetSubtitle => 'Изменения применяются сразу.';

  @override
  String get language_footer =>
      'Меняются только надписи в приложении. Ваши заметки, названия и подписи остаются такими, как вы их написали.';

  @override
  String language_toast(String name) {
    return 'Язык: $name';
  }

  @override
  String get language_selfName => 'русский';

  @override
  String language_name(String lang) {
    String _temp0 = intl.Intl.selectLogic(
      lang,
      {
        'en': 'Английский',
        'ru': 'Русский',
        'et': 'Эстонский',
        'other': 'Английский',
      },
    );
    return '$_temp0';
  }

  @override
  String language_systemFollows(String platform, String lang) {
    String _temp0 = intl.Intl.selectLogic(
      platform,
      {
        'ios': 'Как на iPhone',
        'android': 'Как на Android',
        'other': 'Как на устройстве',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      lang,
      {
        'en': 'английский',
        'ru': 'русский',
        'et': 'эстонский',
        'other': 'английский',
      },
    );
    return '$_temp0 — сейчас $_temp1';
  }

  @override
  String get dictation_title => 'Говорить на…';

  @override
  String dictation_sheetSubtitle(String lang) {
    String _temp0 = intl.Intl.selectLogic(
      lang,
      {
        'en': 'английском',
        'ru': 'русском',
        'et': 'эстонском',
        'other': 'английском',
      },
    );
    return 'Меняется только язык диктовки. Приложение останется на $_temp0.';
  }

  @override
  String dictation_unavailableRow(String lang, String platform) {
    String _temp0 = intl.Intl.selectLogic(
      lang,
      {
        'en': 'Английский',
        'ru': 'Русский',
        'et': 'Эстонский',
        'other': 'Английский',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      platform,
      {
        'ios': 'iPhone',
        'android': 'телефоне',
        'other': 'устройстве',
      },
    );
    return '$_temp0 — распознавание речи недоступно на этом $_temp1. Печатать можно как обычно.';
  }

  @override
  String get dictation_remember => 'Запомним для следующей заметки.';

  @override
  String get dictation_notAvailable => 'Недоступно';

  @override
  String dictation_unavailableWarning(String lang, String platform) {
    String _temp0 = intl.Intl.selectLogic(
      lang,
      {
        'en': 'английском',
        'ru': 'русском',
        'et': 'эстонском',
        'other': 'английском',
      },
    );
    String _temp1 = intl.Intl.selectLogic(
      platform,
      {
        'ios': 'iPhone',
        'android': 'телефоне',
        'other': 'устройстве',
      },
    );
    return 'Распознавание речи на $_temp0 недоступно на этом $_temp1.';
  }

  @override
  String get dictation_chooseAnother => 'Выбрать другой язык';

  @override
  String dictation_languageSemantics(String name) {
    return 'Язык диктовки: $name';
  }

  @override
  String get note_bodyHintUnavailable =>
      'Продолжайте печатать или выберите другой язык и говорите.';

  @override
  String note_listeningIn(String code, String time) {
    return 'Слушаю · $code · $time';
  }

  @override
  String note_wordCountShort(int count) {
    return '$count сл.';
  }

  @override
  String get content_bonus_worst_photo_of_day_title => 'Худшее фото дня';

  @override
  String get content_bonus_worst_photo_of_day_detail =>
      'Не лучший ракурс. Не лучший момент. В этом и смысл.';

  @override
  String get content_bonus_something_free_title => 'Найдите что-то бесплатное';

  @override
  String get content_bonus_something_free_detail =>
      'Вид, улыбка, уличный артист: снимите то, что сегодня ничего вам не стоило.';

  @override
  String get content_bonus_local_snack_title =>
      'Попробуйте перекус, которого нет дома';

  @override
  String get content_bonus_local_snack_detail =>
      'Бонус, если не можете выговорить название.';

  @override
  String get content_bonus_menu_mystery_title =>
      'Закажите то, что не можете перевести';

  @override
  String get content_bonus_menu_mystery_detail =>
      'Ткните в меню и без отступлений.';

  @override
  String get content_bonus_stranger_kindness_title =>
      'Запечатлейте маленькую доброту незнакомца';

  @override
  String get content_bonus_stranger_kindness_detail =>
      'Взмах рукой, улыбка, подсказка, когда вы заблудились.';

  @override
  String get content_bonus_overheard_title => 'Сфотографируйте то, что слышите';

  @override
  String get content_bonus_overheard_detail =>
      'Уличная музыка, незнакомый язык, звуки нового места.';

  @override
  String get content_bonus_souvenir_hunt_title =>
      'Сфотографируйте самый безвкусный сувенир';

  @override
  String get content_bonus_souvenir_hunt_detail =>
      'Покупать не обязательно. Просто полюбуйтесь.';

  @override
  String get content_bonus_sky_moment_title => 'Поймайте небо в деле';

  @override
  String get content_bonus_sky_moment_detail =>
      'Закат, грозовые тучи, неприлично много звёзд.';

  @override
  String get content_bonus_local_transport_title =>
      'Покажите, как вы сегодня передвигались';

  @override
  String get content_bonus_local_transport_detail =>
      'Автобус, велосипед, лодка, стёртые ноги — всё считается.';

  @override
  String get content_bonus_unexpected_detour_title =>
      'Снимите незапланированный крюк';

  @override
  String get content_bonus_unexpected_detour_detail =>
      'Не тот поворот, который оказался тем самым.';

  @override
  String get content_bonus_color_hunt_title => 'Найдите самое яркое вокруг';

  @override
  String get content_bonus_color_hunt_detail =>
      'Стена, прилавок на рынке, чей-то сомнительный наряд.';

  @override
  String get content_bonus_closeup_texture_title =>
      'Снимите текстуру крупным планом';

  @override
  String get content_bonus_closeup_texture_detail =>
      'Брусчатка, кора дерева, странный узор на покрывале в отеле.';

  @override
  String get content_bonus_reflection_shot_title => 'Поймайте отражение';

  @override
  String get content_bonus_reflection_shot_detail =>
      'Вода, стекло, подозрительно блестящая ложка.';

  @override
  String get content_bonus_halfway_selfie_title => 'Селфи на полпути';

  @override
  String get content_bonus_halfway_selfie_detail =>
      'Уставшие глаза — по желанию. Широкая улыбка — обязательно.';

  @override
  String get content_bonus_local_hangout_title =>
      'Сфотографируйте, где на самом деле проводят время местные';

  @override
  String get content_bonus_local_hangout_detail =>
      'Не открыточное место а настоящее.';

  @override
  String get content_bonus_comfort_food_title =>
      'Снимите еду, которая напомнила о доме';

  @override
  String get content_bonus_comfort_food_detail =>
      'Даже за тысячи километров от него.';

  @override
  String get content_bonus_new_skill_title =>
      'Попробуйте то, чего никогда не делали';

  @override
  String get content_bonus_new_skill_detail =>
      'Танцевальное движение, блюдо, язык, который вы нарочно коверкаете.';

  @override
  String get content_bonus_market_haul_title =>
      'Сфотографируйте поход на рынок или в магазин';

  @override
  String get content_bonus_market_haul_detail =>
      'Что вы чуть не купили, но передумали?';

  @override
  String get content_bonus_quiet_moment_title =>
      'Запечатлейте тихий момент посреди поездки';

  @override
  String get content_bonus_quiet_moment_detail =>
      'Не всё должно быть лучшими кадрами.';

  @override
  String get content_bonus_view_from_bed_title =>
      'Сфотографируйте вид оттуда, где вы живёте';

  @override
  String get content_bonus_view_from_bed_detail =>
      'Балкон, окно или просто очень честный потолок.';

  @override
  String get content_bonus_unplanned_friend_title =>
      'Снимите того, с кем познакомились в пути';

  @override
  String get content_bonus_unplanned_friend_detail =>
      'Новый друг, попутчик, очень своенравный местный кот.';

  @override
  String get content_bonus_touchdown_title => 'Отметьте момент прибытия';

  @override
  String get content_bonus_touchdown_detail =>
      'Табличка в аэропорту, перрон, первый вдох нового воздуха.';

  @override
  String get content_bonus_first_impression_title =>
      'Снимите самое первое впечатление';

  @override
  String get content_bonus_first_impression_detail =>
      'Вид, запах, суматоха — поймайте их, пока они не стали привычными.';

  @override
  String get content_bonus_unpacking_ritual_title =>
      'Сфотографируйте свой ритуал распаковки';

  @override
  String get content_bonus_unpacking_ritual_detail =>
      'Каким бы хаотичным он ни был. Каким бы быстрым.';

  @override
  String get content_bonus_last_look_title =>
      'Взгляните в последний раз перед отъездом';

  @override
  String get content_bonus_last_look_detail =>
      'Вид, комната, место, по которому будете скучать больше всего.';

  @override
  String get content_bonus_farewell_meal_title =>
      'Сфотографируйте последнюю трапезу здесь';

  @override
  String get content_bonus_farewell_meal_detail =>
      'Пусть она запомнится или будет тем, что осталось в холодильнике.';

  @override
  String get content_bonus_souvenir_final_title =>
      'Сфотографируйте то, что увозите домой';

  @override
  String get content_bonus_souvenir_final_detail => 'В прямом смысле или нет.';

  @override
  String get content_bonus_snap_anything_title => 'Снимите что угодно';

  @override
  String get content_bonus_snap_anything_detail =>
      'Серьёзно. Что угодно. Это просто чтобы начать.';

  @override
  String get content_bonus_snap_suitecase_title =>
      'Сфотографируйте, как вы собираетесь';

  @override
  String get content_bonus_snap_suitecase_detail =>
      'Запечатлейте хаос сборов в поездку.';

  @override
  String get content_bonus_stranger_portrait_title =>
      'Спросите незнакомца, можно ли его сфотографировать';

  @override
  String get content_bonus_stranger_portrait_detail =>
      'Бонус за смелость. Скорее всего, вам скажут «да».';

  @override
  String get content_bonus_no_phone_hour_title =>
      'Проведите час без телефона, а потом расскажите, что заметили';

  @override
  String get content_bonus_no_phone_hour_detail =>
      'Запишите, а не просто запомните.';

  @override
  String get content_bonus_try_the_dare_title =>
      'Сделайте то, от чего себя всё время отговариваете';

  @override
  String get content_bonus_try_the_dare_detail => 'Вы знаете, о чём речь.';

  @override
  String get content_bonus_milestone_week_one_title =>
      'Неделя позади! Как эта поездка уже изменила вас?';

  @override
  String get content_bonus_milestone_week_one_detail =>
      'Фото и минута честности.';

  @override
  String get content_bonus_milestone_two_weeks_title =>
      'Две недели в пути! Что вы знаете теперь, чего не знали в начале?';

  @override
  String get content_bonus_milestone_two_weeks_detail =>
      'Поймайте момент, когда всё сложилось.';

  @override
  String get content_bonus_milestone_three_weeks_title =>
      'Три недели в пути! По чему вы будете скучать больше всего, когда всё закончится?';

  @override
  String get content_bonus_milestone_three_weeks_detail =>
      'Скажите это, пока не пришлось.';

  @override
  String get content_bonus_streak_saver_checkin_title => 'Просто отметьтесь';

  @override
  String get content_bonus_streak_saver_checkin_detail =>
      'Без давления и без темы просто одно фото того места, где вы сейчас.';

  @override
  String get content_achievement_first_adventure_title => 'Первое приключение';

  @override
  String get content_achievement_first_adventure_description =>
      'Создайте первое событие.';

  @override
  String get content_achievement_globetrotter_title => 'Путешественник по миру';

  @override
  String get content_achievement_globetrotter_description =>
      'Побывайте в 10 странах.';

  @override
  String get content_achievement_century_title => '100 дней в пути';

  @override
  String get content_achievement_century_description =>
      'Запечатлейте 100 дней путешествий.';

  @override
  String get content_achievement_star_collector_title => 'Собиратель звёзд';

  @override
  String get content_achievement_star_collector_description =>
      'Заработайте 250 звёзд.';

  @override
  String get content_achievement_shutterbug_title => 'Скажите «сыр»';

  @override
  String get content_achievement_shutterbug_description =>
      'Добавьте 50 фото в события.';

  @override
  String get content_achievement_storyteller_title => 'Рассказчик';

  @override
  String get content_achievement_storyteller_description =>
      'Напишите 20 заметок в дневник.';

  @override
  String get content_achievement_jetsetter_title => 'Заядлый путешественник';

  @override
  String get content_achievement_jetsetter_description => 'Создайте 5 событий.';

  @override
  String get content_achievement_legend_title => 'Легенда';

  @override
  String get content_achievement_legend_description =>
      'Заработайте 1000 звёзд.';

  @override
  String get content_checklist_passport => 'Паспорт';

  @override
  String get content_checklist_visa_documents => 'Визовые документы';

  @override
  String get content_checklist_travel_insurance => 'Туристическая страховка';

  @override
  String get content_checklist_boarding_passes_tickets =>
      'Посадочные талоны / билеты';

  @override
  String get content_checklist_id_card => 'Удостоверение личности';

  @override
  String get content_checklist_local_currency_cash =>
      'Наличные в местной валюте';

  @override
  String get content_checklist_credit_debit_cards =>
      'Кредитные / дебетовые карты';

  @override
  String get content_checklist_phone_charger => 'Зарядка для телефона';

  @override
  String get content_checklist_underwear => 'Нижнее бельё';

  @override
  String get content_checklist_comfortable_walking_shoes =>
      'Удобная обувь для прогулок';

  @override
  String get content_checklist_t_shirts => 'Футболки';

  @override
  String get content_checklist_jacket => 'Куртка';

  @override
  String get content_checklist_swimsuit => 'Купальник / плавки';

  @override
  String get content_checklist_sleepwear => 'Одежда для сна';

  @override
  String get content_checklist_sunglasses => 'Солнцезащитные очки';

  @override
  String get content_checklist_toothbrush_toothpaste => 'Зубная щётка и паста';

  @override
  String get content_checklist_prescription_medications =>
      'Рецептурные лекарства';

  @override
  String get content_checklist_first_aid_kit => 'Аптечка';

  @override
  String get content_checklist_sunscreen => 'Солнцезащитный крем';

  @override
  String get content_checklist_deodorant => 'Дезодорант';

  @override
  String get content_checklist_hand_sanitizer => 'Антисептик для рук';

  @override
  String get content_checklist_shampoo_conditioner => 'Шампунь и кондиционер';

  @override
  String get content_checklist_contact_lenses_or_glasses =>
      'Контактные линзы или очки';

  @override
  String get content_checklist_phone => 'Телефон';

  @override
  String get content_checklist_charging_cables => 'Зарядные кабели';

  @override
  String get content_checklist_power_adapter => 'Переходник для розетки';

  @override
  String get content_checklist_portable_battery_pack => 'Пауэрбанк';

  @override
  String get content_checklist_headphones => 'Наушники';

  @override
  String get content_checklist_camera => 'Фотоаппарат';

  @override
  String get content_checklist_sim_card_or_esim => 'SIM-карта или eSIM';

  @override
  String get content_checklist_travel_pillow => 'Подушка для путешествий';

  @override
  String get content_checklist_reusable_water_bottle =>
      'Многоразовая бутылка для воды';

  @override
  String get content_checklist_snacks => 'Перекусы';

  @override
  String get content_checklist_packing_cubes => 'Органайзеры для вещей';

  @override
  String get content_checklist_earplugs_eye_mask => 'Беруши и маска для сна';

  @override
  String get content_checklist_travel_journal => 'Дневник путешествий';

  @override
  String get content_checklist_umbrella => 'Зонт';
}
