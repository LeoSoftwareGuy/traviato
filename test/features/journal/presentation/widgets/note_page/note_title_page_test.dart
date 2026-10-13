import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/hand_drawn_balloon.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/note_title_page.dart';

const _assets = [
  JournalDoodleAssets.balloonLarge,
  JournalDoodleAssets.balloonSmall,
  JournalDoodleAssets.balloonTiny,
  JournalDoodleAssets.cloud,
  JournalDoodleAssets.flightTrail,
];

void main() {
  test('every exported doodle SVG is bundled and parses', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final asset in _assets) {
      final svg = await rootBundle.loadString(asset);
      expect(svg, contains('<svg'), reason: asset);
      await vg.loadPicture(SvgStringLoader(svg), null);
    }
  });

  testWidgets('the title page draws three balloons, the trail and the cloud', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SizedBox(
          width: 390,
          height: 800,
          child: NoteTitlePage(
            stamp: 'Day 2 · 13 Aug',
            title: 'The lake before the buses',
            meta: '128 words · 5 photos',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HandDrawnBalloon), findsNWidgets(3));
    expect(find.byType(JournalDoodle), findsNWidgets(2));
    expect(find.byType(SvgPicture), findsNWidgets(5));
    expect(tester.takeException(), isNull);
  });
}
