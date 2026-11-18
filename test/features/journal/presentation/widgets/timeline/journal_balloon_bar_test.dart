import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/journal_balloon_bar.dart';

import '../../../../../helpers/localized_app.dart';

Future<void> _pump(
  WidgetTester tester, {
  VoidCallback? onPhotoTap,
  VoidCallback? onNoteTap,
  Locale locale = const Locale('en'),
}) {
  return tester.pumpWidget(
    localizedApp(
      locale: locale,
      home: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
            child: JournalBalloonBar(
              onPhotoTap: onPhotoTap ?? () {},
              onNoteTap: onNoteTap ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

double _fillOpacity(WidgetTester tester, String half) => tester
    .widget<AnimatedOpacity>(find.byKey(Key('journal-balloon-fill-$half')))
    .opacity;

void main() {
  testWidgets('shows the Photo and Note labels with no star count', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.textContaining('✦'), findsNothing);
  });

  testWidgets('is 60 tall', (tester) async {
    await _pump(tester);

    expect(tester.getSize(find.byType(JournalBalloonBar)).height, 60);
  });

  testWidgets('each half calls its own action', (tester) async {
    var photoTaps = 0;
    var noteTaps = 0;
    await _pump(
      tester,
      onPhotoTap: () => photoTaps++,
      onNoteTap: () => noteTaps++,
    );

    await tester.tap(find.byKey(const Key('capture-photo')));
    await tester.tap(find.byKey(const Key('capture-note')));

    expect(photoTaps, 1);
    expect(noteTaps, 1);
  });

  testWidgets('the buttons carry their screen-reader labels', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('Add a photo'), findsOneWidget);
    expect(find.bySemanticsLabel('Add a note'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('pressing a half fills that half of the balloon, then clears', (
    tester,
  ) async {
    await _pump(tester);
    expect(_fillOpacity(tester, 'left'), 0);
    expect(_fillOpacity(tester, 'right'), 0);

    final photo = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('capture-photo'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_fillOpacity(tester, 'left'), 1);
    expect(_fillOpacity(tester, 'right'), 0);

    await photo.up();
    await tester.pumpAndSettle();
    expect(_fillOpacity(tester, 'left'), 0);

    final note = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('capture-note'))),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(_fillOpacity(tester, 'left'), 0);
    expect(_fillOpacity(tester, 'right'), 1);
    await note.up();
    await tester.pumpAndSettle();
  });

  testWidgets('hovering a half fills it and leaving clears it', (
    tester,
  ) async {
    await _pump(tester);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);

    await mouse.moveTo(
      tester.getCenter(find.byKey(const Key('capture-note'))),
    );
    await tester.pumpAndSettle();
    expect(_fillOpacity(tester, 'right'), 1);

    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(_fillOpacity(tester, 'right'), 0);
  });

  testWidgets('reads in Russian', (tester) async {
    await _pump(tester, locale: const Locale('ru'));

    expect(find.text('Фото'), findsOneWidget);
    expect(find.text('Заметка'), findsOneWidget);
  });
}
