import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/core/theme/app_typography.dart';
import 'package:traviato/core/widgets/adaptive_button_pair.dart';
import 'package:traviato/core/widgets/shrink_to_floor_text.dart';
import 'package:traviato/core/widgets/trailing_fade.dart';

const _label = TextStyle(fontSize: 12, letterSpacing: 1);

Widget _sized(double width, Widget child) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ShrinkToFloorText.fittedStyle', () {
    test('leaves a label that fits alone', () {
      final r = ShrinkToFloorText.fittedStyle(
        text: 'Plan',
        style: _label,
        maxWidth: 200,
        minFontSize: 9,
      );
      expect(r.fitsOnOneLine, isTrue);
      expect(r.style.fontSize, 12);
    });

    test('tightens tracking before shrinking the size', () {
      // "ВОСПОМИНАНИЯ" at 12px + 1 tracking in the 1em test font is
      // 12×12 + 12 = 156; at 0 tracking it's 144.
      final r = ShrinkToFloorText.fittedStyle(
        text: 'ВОСПОМИНАНИЯ',
        style: _label,
        maxWidth: 150,
        minFontSize: 7.5,
        minLetterSpacing: 0,
      );
      expect(r.fitsOnOneLine, isTrue);
      expect(r.style.letterSpacing, 0);
      expect(r.style.fontSize, 12);
    });

    test('then steps the size down to the floor, never below', () {
      final shrunk = ShrinkToFloorText.fittedStyle(
        text: 'Pakkimisnimekiri',
        style: _label.copyWith(letterSpacing: 0),
        maxWidth: 16 * 10.5,
        minFontSize: 9,
      );
      expect(shrunk.fitsOnOneLine, isTrue);
      expect(shrunk.style.fontSize, 10.5);

      final floor = ShrinkToFloorText.fittedStyle(
        text: 'Pakkimisnimekiri',
        style: _label.copyWith(letterSpacing: 0),
        maxWidth: 60,
        minFontSize: 9,
      );
      expect(floor.fitsOnOneLine, isFalse);
      expect(floor.style.fontSize, 9);
    });
  });

  testWidgets('ShrinkToFloorText wraps at the floor instead of an ellipsis', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sized(
        60,
        const ShrinkToFloorText(
          'Pakkimisnimekiri',
          style: _label,
          minFontSize: 9,
          maxLines: 2,
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('Pakkimisnimekiri'));
    expect(text.maxLines, 2);
    expect(text.overflow, isNot(TextOverflow.ellipsis));
    expect(tester.takeException(), isNull);
  });

  group('AdaptiveButtonPair (frame 4b)', () {
    Widget pair(String primary, String secondary) => AdaptiveButtonPair(
      primaryLabel: primary,
      secondaryLabel: secondary,
      labelStyle: const TextStyle(fontSize: 15),
      primary: ElevatedButton(onPressed: () {}, child: Text(primary)),
      secondary: OutlinedButton(onPressed: () {}, child: Text(secondary)),
    );

    testWidgets('sits side by side when both labels fit at half width', (
      tester,
    ) async {
      await tester.pumpWidget(_sized(328, pair('Done', 'Cancel')));
      expect(
        find.byKey(const Key('adaptive-button-pair-row')),
        findsOneWidget,
      );
      // Primary on the right by default.
      expect(
        tester.getCenter(find.text('Done')).dx,
        greaterThan(tester.getCenter(find.text('Cancel')).dx),
      );
    });

    testWidgets('stacks, primary on top, when a label overflows half width', (
      tester,
    ) async {
      await tester.pumpWidget(
        _sized(328, pair('Kinnita fotod kaardile', 'Mitte praegu')),
      );
      expect(
        find.byKey(const Key('adaptive-button-pair-stacked')),
        findsOneWidget,
      );
      expect(
        tester.getCenter(find.text('Kinnita fotod kaardile')).dy,
        lessThan(tester.getCenter(find.text('Mitte praegu')).dy),
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('TrailingFade masks the row without changing its layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      _sized(
        200,
        const TrailingFade(child: SizedBox(height: 30, width: 200)),
      ),
    );
    expect(find.byType(ShaderMask), findsOneWidget);
    expect(tester.getSize(find.byType(TrailingFade)), const Size(200, 30));
  });

  test('eyebrow tracking drops to .08em in Russian and Estonian', () {
    AppTypography.useLocale(const Locale('en'));
    expect(AppTypography.eyebrowTracking(9.5), closeTo(1.3, 1e-9));
    for (final code in ['ru', 'et']) {
      AppTypography.useLocale(Locale(code));
      expect(AppTypography.eyebrowTracking(10), closeTo(.8, 1e-9));
    }
    AppTypography.useLocale(const Locale('en'));
  });
}
