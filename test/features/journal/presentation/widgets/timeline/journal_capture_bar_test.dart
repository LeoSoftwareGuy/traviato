import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/widgets/app_bottom_nav_bar.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/journal_capture_bar.dart';

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
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: JournalCaptureBar(
              onPhotoTap: onPhotoTap ?? () {},
              onNoteTap: onNoteTap ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('shows the Photo and Note labels with no star count', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Photo'), findsOneWidget);
    expect(find.text('Note'), findsOneWidget);
    expect(find.textContaining('✦'), findsNothing);
  });

  testWidgets('wears the Home nav surface and tabs, no balloon (#424)', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.byType(AppBottomBarSurface), findsOneWidget);
    expect(find.byType(AppBottomBarTab), findsNWidgets(2));
    expect(find.byKey(const Key('journal-balloon-fill-left')), findsNothing);
    for (final icon in [Icons.photo_camera_outlined, Icons.edit_note_rounded]) {
      expect(tester.widget<Icon>(find.byIcon(icon)).size, 28);
    }
  });

  testWidgets('the two halves are equal and at least 48 tall', (tester) async {
    await _pump(tester);

    final photo = tester.getSize(find.byKey(const Key('capture-photo')));
    final note = tester.getSize(find.byKey(const Key('capture-note')));
    expect(photo.width, closeTo(note.width, .5));
    expect(photo.height, greaterThanOrEqualTo(48));
    expect(
      tester.getSize(find.byType(JournalCaptureBar)).height,
      closeTo(JournalCaptureBar.height, 4),
    );
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

  testWidgets('reads in Russian', (tester) async {
    await _pump(tester, locale: const Locale('ru'));

    expect(find.text('Фото'), findsOneWidget);
    expect(find.text('Заметка'), findsOneWidget);
  });
}
