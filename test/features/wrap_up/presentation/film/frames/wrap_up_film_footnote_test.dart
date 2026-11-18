import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_footnote.dart';
import 'package:traviato/features/wrap_up/presentation/film/frames/wrap_up_film_footnote.dart';
import 'package:traviato/features/wrap_up/presentation/film/timeline/classic_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/timeline/film_timeline.dart';

import '../../../../../helpers/localized_app.dart';

void main() {
  Future<void> pump(WidgetTester tester, WrapUpFootnote footnote) async {
    setScreenSize(tester, width: 1080, height: 1920);
    final scene = TimedScene(
      start: 0,
      duration: 5,
      spec: FootnoteSceneSpec(footnote: footnote),
    );
    await tester.pumpWidget(
      localizedApp(
        locale: const Locale('en'),
        home: Stack(
          children: [
            WrapUpFilmFootnote(t: 2.5, scene: scene, footnote: footnote),
          ],
        ),
      ),
    );
  }

  testWidgets('zero counts are left out (#399 T4)', (tester) async {
    await pump(
      tester,
      const WrapUpFootnote(photoCount: 28, bonusCompletedCount: 0, stars: 0),
    );
    expect(find.text('28'), findsOneWidget);
    expect(find.text('0'), findsNothing);
    expect(find.text('✦0'), findsNothing);
  });

  testWidgets('every count above zero shows', (tester) async {
    await pump(
      tester,
      const WrapUpFootnote(photoCount: 28, bonusCompletedCount: 3, stars: 41),
    );
    expect(find.text('28'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('✦41'), findsOneWidget);
  });
}
