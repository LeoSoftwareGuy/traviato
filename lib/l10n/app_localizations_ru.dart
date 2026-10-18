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
}
