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
}
