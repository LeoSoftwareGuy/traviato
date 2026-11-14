import 'package:flutter/services.dart';

/// The film's bundled fonts; widget tests otherwise render text in Ahem.
Future<void> loadNeonNightFonts() async {
  final display = FontLoader('BigShouldersDisplay')
    ..addFont(rootBundle.load('assets/fonts/BigShouldersDisplay[wght].ttf'));
  final fallback = FontLoader('FiraSansExtraCondensed');
  for (final weight in const ['SemiBold', 'ExtraBold', 'Black']) {
    fallback.addFont(
      rootBundle.load('assets/fonts/FiraSansExtraCondensed-$weight.ttf'),
    );
  }
  final mono = FontLoader('JetBrainsMono')
    ..addFont(rootBundle.load('assets/fonts/JetBrainsMono[wght].ttf'));
  await Future.wait([display.load(), fallback.load(), mono.load()]);
}
