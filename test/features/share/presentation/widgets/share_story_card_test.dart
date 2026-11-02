import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:traviato/features/share/presentation/widgets/share_qr_code.dart';
import 'package:traviato/features/share/presentation/widgets/share_story_card.dart';

import '../../../../helpers/localized_app.dart';

/// Goldens are made on one OS and checked on another (CI is Linux), so a
/// sliver of anti-aliasing drift is allowed.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const _tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    if (result.passed || result.diffPercent <= _tolerance) return true;
    throw FlutterError(await generateFailureOutput(result, golden, basedir));
  }
}

const _url = 'https://storyni.app/m/k7Qm2xPa9c';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    final base = (goldenFileComparator as LocalFileComparator).basedir;
    goldenFileComparator = _TolerantComparator(
      base.resolve('share_story_card_test.dart'),
    );
  });

  Widget card({
    String title = 'One long road',
    String eyebrow = 'Highlands · 5 days',
    String? dates = '12–16 AUG 2026',
  }) => ShareStoryCard(
    title: title,
    eyebrow: eyebrow,
    dates: dates,
    coverPath: null,
    url: _url,
  );

  Future<void> pumpPreview(
    WidgetTester tester,
    Widget child, {
    Locale locale = const Locale('en'),
    GlobalKey? boundaryKey,
  }) async {
    setScreenSize(tester, width: 390, height: 844);
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(
          locale: locale,
          home: Center(
            child: SizedBox(
              width: 300,
              height: 533,
              child: FittedBox(
                child: RepaintBoundary(key: boundaryKey, child: child),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('exports at 1080×1920 however small it is shown (#311)', (
    tester,
  ) async {
    final key = GlobalKey();
    await pumpPreview(tester, card(), boundaryKey: key);

    // captureBoundaryPng renders the boundary at its own logical size
    // (pixelRatio 1), so this is the PNG's size: the FittedBox scales the
    // preview, never the export.
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    expect(boundary.size, const Size(1080, 1920));
    expect(tester.getSize(find.byType(FittedBox)), const Size(300, 533));
  });

  testWidgets('the QR is at least 200px in the export', (tester) async {
    await pumpPreview(tester, card());

    final qr = tester.widget<ShareQrCode>(find.byType(ShareQrCode));
    expect(qr.url, _url);
    expect(qr.size, greaterThanOrEqualTo(200));
  });

  Future<void> golden(
    WidgetTester tester,
    Widget child,
    Locale locale,
    String name,
  ) async {
    setScreenSize(tester, width: 1080, height: 1920);
    await tester.pumpWidget(
      ProviderScope(
        child: localizedApp(locale: locale, home: child),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(ShareStoryCard),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('golden: English', (tester) async {
    await golden(tester, card(), const Locale('en'), 'share_story_card_en');
  });

  testWidgets('golden: Russian, long title', (tester) async {
    await golden(
      tester,
      card(
        title: 'Длинная дорога через всё нагорье и обратно к морю',
        eyebrow: 'Хайленд · 5 дней',
        dates: '12–16 АВГ. 2026',
      ),
      const Locale('ru'),
      'share_story_card_ru',
    );
  });
}
