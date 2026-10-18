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
}
