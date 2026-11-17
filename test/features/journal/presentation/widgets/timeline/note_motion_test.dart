import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/fold_away.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/fresh_glow.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/fresh_note_in.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/swipe_to_delete.dart';

import '../../../../../helpers/localized_app.dart';

Widget _host(Widget child, {bool reducedMotion = false}) => localizedApp(
  locale: const Locale('en'),
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reducedMotion),
      child: Scaffold(body: Center(child: child)),
    ),
  ),
);

const _card = SizedBox(key: Key('card'), width: 200, height: 80);

double _slotFactor(WidgetTester tester) => tester
    .widget<Align>(find.byKey(const Key('fresh-note-slot')))
    .heightFactor!;

void main() {
  group('FreshNoteIn (#407)', () {
    testWidgets('the slot opens at +420ms and the card lands by ~1.24s', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const FreshNoteIn(isFresh: true, child: _card)),
      );

      await tester.pump(const Duration(milliseconds: 300));
      expect(_slotFactor(tester), 0);
      await tester.pump(const Duration(milliseconds: 300)); // 600ms
      expect(_slotFactor(tester), allOf(greaterThan(0), lessThan(1)));
      await tester.pump(const Duration(milliseconds: 700)); // 1.3s
      expect(find.byKey(const Key('fresh-note-slot')), findsNothing);
      expect(tester.getSize(find.byKey(const Key('card'))).height, 80);
    });

    testWidgets('reduced motion: a 200ms crossfade, no slot or drop', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FreshNoteIn(isFresh: true, child: _card),
          reducedMotion: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const Key('fresh-note-slot')), findsNothing);
      expect(find.byType(FadeTransition), findsWidgets);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byKey(const Key('card')), findsOneWidget);
    });

    testWidgets('a note that is not fresh is shown as is', (tester) async {
      await tester.pumpWidget(
        _host(const FreshNoteIn(isFresh: false, child: _card)),
      );

      expect(find.byKey(const Key('fresh-note-slot')), findsNothing);
    });
  });

  group('FreshGlow (#407)', () {
    Widget glow({bool reducedMotion = false}) => _host(
      FreshGlow(
        isFresh: true,
        borderRadius: BorderRadius.circular(16),
        child: _card,
      ),
      reducedMotion: reducedMotion,
    );

    testWidgets('one ring from +800ms for 1.4s', (tester) async {
      await tester.pumpWidget(glow());

      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('fresh-note-glow')), findsNothing);
      await tester.pump(const Duration(milliseconds: 700)); // 1.2s
      expect(find.byKey(const Key('fresh-note-glow')), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1100)); // 2.3s
      expect(find.byKey(const Key('fresh-note-glow')), findsNothing);
    });

    testWidgets('no ring under reduced motion', (tester) async {
      await tester.pumpWidget(glow(reducedMotion: true));
      await tester.pump(const Duration(milliseconds: 1200));

      expect(find.byKey(const Key('fresh-note-glow')), findsNothing);
    });
  });

  group('FoldAway (#407)', () {
    testWidgets('fades and folds to 0 height over 340ms', (tester) async {
      await tester.pumpWidget(
        _host(const FoldAway(isLeaving: false, child: _card)),
      );
      await tester.pumpWidget(
        _host(const FoldAway(isLeaving: true, child: _card)),
      );

      await tester.pump(const Duration(milliseconds: 170));
      final mid = tester.getSize(find.byType(FoldAway)).height;
      expect(mid, allOf(greaterThan(0), lessThan(80)));
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.getSize(find.byType(FoldAway)).height, 0);
    });

    testWidgets('reduced motion fades without folding', (tester) async {
      await tester.pumpWidget(
        _host(
          const FoldAway(isLeaving: true, child: _card),
          reducedMotion: true,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.getSize(find.byType(FoldAway)).height, 80);
      final opacity = tester.widget<Opacity>(
        find.byKey(const Key('fold-away')),
      );
      expect(opacity.opacity, allOf(greaterThan(0), lessThan(1)));
    });
  });

  group('SwipeToDelete (#407)', () {
    Future<void> pumpAndSwipe(
      WidgetTester tester,
      VoidCallback onDelete,
    ) async {
      await tester.pumpWidget(
        _host(
          SwipeToDelete(
            onDelete: onDelete,
            borderRadius: BorderRadius.circular(16),
            child: const ColoredBox(color: Colors.black, child: _card),
          ),
        ),
      );
      await tester.drag(find.byKey(const Key('card')), const Offset(-120, 0));
      await tester.pumpAndSettle();
    }

    testWidgets('on iOS a left swipe reveals Delete, which calls onDelete', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      var deletes = 0;
      await pumpAndSwipe(tester, () => deletes++);

      expect(find.byKey(const Key('note-swipe-delete')), findsOneWidget);
      await tester.tap(find.byKey(const Key('note-swipe-delete')));
      await tester.pumpAndSettle();
      expect(deletes, 1);
      expect(find.byKey(const Key('note-swipe-delete')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('a short swipe snaps back closed', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await tester.pumpWidget(
        _host(
          SwipeToDelete(
            onDelete: () {},
            borderRadius: BorderRadius.circular(16),
            child: const ColoredBox(color: Colors.black, child: _card),
          ),
        ),
      );
      await tester.timedDrag(
        find.byKey(const Key('card')),
        const Offset(-20, 0),
        const Duration(milliseconds: 400),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('note-swipe-delete')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('elsewhere the swipe does nothing', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pumpAndSwipe(tester, () {});

      expect(find.byKey(const Key('note-swipe-delete')), findsNothing);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
