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
}
