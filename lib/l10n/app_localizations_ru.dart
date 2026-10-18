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
      'В бесплатном тарифе можно создать до 3 воспоминаний. Перейдите на Pro, чтобы снять ограничение.';

  @override
  String get error_freeTierPhotos =>
      'В бесплатном тарифе — до 40 фото на одно воспоминание. Перейдите на Pro, чтобы снять ограничение.';

  @override
  String get error_questPlanningClosed =>
      'Это воспоминание добавлено после окончания поездки, поэтому планировать нечего.';

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
      'Ваши воспоминания принадлежат только вам — мы ничего не публикуем.';

  @override
  String auth_rewardTease(String stars) {
    return 'Первое воспоминание принесёт $stars, а до значка «Рассказчик» — всего три заметки.';
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
    return 'Мы отправили ссылку для подтверждения на $email. Откройте её на этом телефоне — и вы сразу войдёте, или подтвердите на другом устройстве и войдите здесь.';
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
  String get guest_headlineLead => 'Каждое воспоминание —';

  @override
  String get guest_headlineEmphasis => 'бережно сохранено.';

  @override
  String get guest_body =>
      'От больших праздников до спонтанных маленьких приключений — некоторые моменты слишком хороши, чтобы их забыть. Планируйте их, проживайте, а мы превратим лучшее в истории, к которым захочется возвращаться снова и снова.';

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
  String get guest_stepBeforeTitle => 'Планируйте веселье. Детали — на нас.';

  @override
  String get guest_stepBeforeBody =>
      'Большие выходные? Маленькое приключение? Или просто вторник, который хочется запомнить? Составляйте планы и списки — всё в одном уютном месте.';

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
  String get home_emptyTitle => 'Пока нет воспоминаний';

  @override
  String get home_emptyBody =>
      'Начните первое воспоминание — и оно превратится в дневник, который останется с вами навсегда.';

  @override
  String get home_emptyCta => 'Создать первое воспоминание';

  @override
  String get home_keptForeverEmpty =>
      'Пока ничего нет — воспоминания появятся здесь, когда поездка завершится.';

  @override
  String home_statMemories(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'воспоминания',
      many: 'воспоминаний',
      few: 'воспоминания',
      one: 'воспоминание',
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
  String get trip_newMemory => 'Новое воспоминание';

  @override
  String get trip_createTitleLead => 'Что достойно';

  @override
  String get trip_createTitleEmphasis => 'воспоминания?';

  @override
  String get trip_nameLabel => 'Название';

  @override
  String get trip_nameHint => 'например, Лето в Токио';

  @override
  String get trip_nameRequired => 'Дайте воспоминанию название.';

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
  String get trip_createCta => 'Создать воспоминание';

  @override
  String trip_rewardNudge(String stars) {
    return 'За создание — $stars. Пишите заметку каждый день, и откроется значок «Рассказчик».';
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
  String get trip_deleteTitle => 'Удалить воспоминание';

  @override
  String get trip_deleteConfirm => 'Да — удалить навсегда';

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
    return 'Будут удалены $photos и $notes. Заработанные звёзды останутся. Отменить это нельзя.';
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
  String get toast_packed => '✦ Собрано — отлично';

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
  String get manage_title => 'Изменить воспоминание';

  @override
  String get manage_nameLabel => 'Название';

  @override
  String get manage_rename => 'Переименовать';

  @override
  String get manage_shiftHint =>
      'Нажмите на дату, чтобы сдвинуть её на день вперёд, удерживайте — чтобы назад. Дела сдвинутся вместе с ней.';

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
  String get journal_quietOne => 'Тихий день';

  @override
  String journal_dayQuietOne(int day) {
    return 'День $day — тихий день';
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
  String get journal_wrapUpReqPhotos => 'Пять фото в этом воспоминании';

  @override
  String get journal_wrapUpReqNote => 'Хотя бы одна заметка';

  @override
  String get journal_wrapUpFree =>
      'Ничего покупать не нужно — на любом тарифе всё одинаково.';

  @override
  String get journal_nothingYet => 'Здесь пока пусто';

  @override
  String journal_nothingFromDay(int day) {
    return 'Из дня $day пока ничего';
  }

  @override
  String get journal_nudgeBody =>
      'Даже одно фото поможет итогам. Тихие дни тоже попадают в фильм — этот просто промелькнёт.';

  @override
  String get journal_addAPhoto => '＋ Добавить фото';

  @override
  String get journal_writeNote => 'Написать заметку';

  @override
  String get journal_addNotesToday => '✎ Добавить заметку о сегодня';

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
      'Продолжайте — печатайте или нажмите на микрофон и просто говорите.';

  @override
  String note_wordsAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count слова',
      many: '+$count слов',
      few: '+$count слова',
      one: '+$count слово',
    );
    return '$_temp0';
  }

  @override
  String get note_micOff =>
      'Микрофон выключен. Включите его в Настройках или просто печатайте.';

  @override
  String get note_voiceUnavailable =>
      'Голосовой ввод сейчас недоступен — можно печатать.';

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
  String note_listening(String time) {
    return 'Слушаю · $time';
  }

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
  String get expense_searchHint => 'Поиск воспоминаний';

  @override
  String get expense_sortLatest => 'Сначала новые';

  @override
  String get expense_sortBiggest => 'Самые затратные';

  @override
  String get expense_memoriesHeader => 'Воспоминания';

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
      'Сначала создайте воспоминание, а потом отмечайте, сколько тратите.';

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
  String get expense_pickMemoryTitle => 'Выберите воспоминание выше';

  @override
  String get expense_pickMemoryBody =>
      'Вы увидите итог, на что ушли деньги, и каждый расход так, как вы его записали.';

  @override
  String get expense_newExpense => 'Новый расход';

  @override
  String get expense_memoryLabel => 'Воспоминание';

  @override
  String get expense_memoryRequired =>
      'Выберите, к какому воспоминанию это относится.';

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
      'Выберите два воспоминания, чтобы сравнить расходы.';

  @override
  String get compare_hintPickSecond => 'Теперь выберите второе.';

  @override
  String compare_hintReady(String a, String b) {
    return '«$a» и «$b» — нажмите на любое, чтобы заменить.';
  }

  @override
  String get compare_needTwo =>
      'Создайте хотя бы два воспоминания, чтобы сравнить расходы.';

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
  String get bonus_emptyTitle => 'Пока нет текущего воспоминания';

  @override
  String get bonus_emptyBody =>
      'Бонусные задания появятся здесь, когда начнётся воспоминание.';

  @override
  String get bonus_backHome => 'На главную';

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
  String get bonus_newOnesTomorrow => 'Новые — завтра.';

  @override
  String get notif_promptTitle => 'Напоминать о ежедневных заданиях?';

  @override
  String notif_promptBody(String appName) {
    return '$appName может напомнить утром и вечером, если бонусное задание ещё не выполнено, — не чаще, и это легко отключить.';
  }

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
      other: 'воспоминания',
      many: 'воспоминаний',
      few: 'воспоминания',
      one: 'воспоминание',
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
    return 'Сохранено воспоминаний: $kept из $cap. Перейдите на Pro, чтобы сохранять больше.';
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
      '7 дней бесплатно, потом — по подписке. Отменить можно в любой момент.';

  @override
  String sub_trialTermsYearly(String price) {
    return '7 дней бесплатно, затем $price/год. Отменить можно в любой момент.';
  }

  @override
  String get sub_memoriesKept => 'Сохранено воспоминаний';

  @override
  String get sub_unlimited => 'Без ограничений';

  @override
  String sub_ofCap(int used, int cap) {
    return '$used из $cap';
  }

  @override
  String get sub_photosInMemory => 'Фото в этом воспоминании';

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
      'Три бесплатных воспоминания заняты. Перейдите на Pro, чтобы сохранять каждую поездку, а не только три.';

  @override
  String get paywall_subPhotoCap =>
      'В этом воспоминании уже 40 фото. Перейдите на Pro, чтобы добавлять фото без ограничений.';

  @override
  String get paywall_subProfile =>
      'Каждому воспоминанию нужно место. Перейдите на Pro в любой момент — и места хватит на всё.';

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
  String get paywall_perkMemories => 'Безлимит воспоминаний';

  @override
  String get paywall_perkMemoriesDetail =>
      'Сохраняйте каждую поездку, а не выбирайте три.';

  @override
  String get paywall_perkPhotos => 'Безлимит фото в воспоминании';

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
      'Три бесплатных воспоминания останутся с вами в любом случае — без Pro ничего не удалится и не заблокируется.';

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
}
