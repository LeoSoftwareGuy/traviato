import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// The app's UI strings for the current locale (#220).
///
/// Falls back to English when no [AppLocalizations] delegate is above
/// [this] — a bare `MaterialApp` in a widget test, or an overlay built
/// outside the app root — so a missing delegate never throws.
extension ContextL10n on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('en'));
}
