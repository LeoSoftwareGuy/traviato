import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/journal/domain/dictation/dictation_service.dart';
import 'package:traviato/features/journal/presentation/pages/note_page.dart';
import 'package:traviato/features/journal/presentation/providers/dictation_providers.dart';

import '../../fakes/fake_dictation_service.dart';

const _existing = 'Woke early. Walked the lake.';

class _Host extends StatefulWidget {
  const _Host({required this.existingText});

  final String existingText;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  var popped = false;
  String? result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () async {
            final draft = await Navigator.of(context).push(
              NotePageRoute(
                stamp: 'Day 2 · 13 Aug',
                title: 'The lake before the buses',
                existingText: widget.existingText,
                photoCount: 5,
              ),
            );
            setState(() {
              popped = true;
              result = draft;
            });
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _pumpHost(
  WidgetTester tester, {
  String existingText = _existing,
  bool reducedMotion = false,
  FakeDictationService? dictation,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dictationServiceProvider.overrideWithValue(
          dictation ?? FakeDictationService(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reducedMotion),
          child: child!,
        ),
        home: _Host(existingText: existingText),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pump(); // route pushed, closed title page painted
}

_HostState _host(WidgetTester tester) => tester.state(find.byType(_Host));

final _turning = find.byKey(const Key('note-page-turning'));
final _field = find.byKey(const Key('note-page-field'));

bool _writingPageIgnoresTaps(WidgetTester tester) => tester
    .widgetList<IgnorePointer>(
      find.ancestor(of: _field, matching: find.byType(IgnorePointer)),
    )
    .any((w) => w.ignoring);

void main() {
  testWidgets('opens with the title page over the writing page, which only '
      'becomes tappable once the turn completes (~1.23s)', (tester) async {
    await _pumpHost(tester);

    expect(find.byKey(const Key('note-title-page')), findsOneWidget);
    expect(_writingPageIgnoresTaps(tester), isTrue);

    await tester.pump(const Duration(milliseconds: 60)); // start delay
    await tester.pump(); // controller's first tick
    await tester.pump(const Duration(milliseconds: 1000));
    expect(_turning, findsOneWidget, reason: 'still turning at ~1.06s');
    expect(_writingPageIgnoresTaps(tester), isTrue);
    await tester.tap(
      find.byKey(const Key('note-page-done')),
      warnIfMissed: false,
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(_turning, findsNothing);
    expect(_writingPageIgnoresTaps(tester), isFalse);
    // The early Done tap was swallowed.
    expect(_host(tester).popped, isFalse);
    // No keyboard until the user asks for it.
    expect(tester.testTextInput.isVisible, isFalse);
  });

  testWidgets('shows the front face until 90°, then the back face', (
    tester,
  ) async {
    await _pumpHost(tester);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('note-title-page')), findsOneWidget);
    expect(find.byKey(const Key('note-page-back')), findsNothing);

    await tester.pump(const Duration(milliseconds: 750));
    expect(find.byKey(const Key('note-title-page')), findsNothing);
    expect(find.byKey(const Key('note-page-back')), findsOneWidget);
    // Pre-flipped so the back isn't mirrored once the page has turned.
    expect(
      find.ancestor(
        of: find.byKey(const Key('note-page-back')),
        matching: find.byType(Transform),
      ),
      findsAtLeastNWidgets(2),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('reduced motion crossfades instead of turning', (tester) async {
    await _pumpHost(tester, reducedMotion: true);
    expect(_turning, findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_turning, findsNothing);
    expect(
      tester.widget<Opacity>(find.byType(Opacity).first).opacity,
      closeTo(.5, .05),
    );

    await tester.pump(const Duration(milliseconds: 150));
    expect(_writingPageIgnoresTaps(tester), isFalse);

    await tester.tap(find.byKey(const Key('note-page-done')));
    await tester.pump();
    expect(_turning, findsNothing);
    await tester.pumpAndSettle();
    expect(_host(tester).popped, isTrue);
  });

  testWidgets('shows the existing entry read-only and counts only the draft', (
    tester,
  ) async {
    await _pumpHost(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('note-page-existing')), findsOneWidget);
    expect(find.byKey(const Key('note-page-word-counter')), findsNothing);

    await tester.enterText(_field, 'Then the buses came.');
    await tester.pump();
    expect(find.text('+4 words'), findsOneWidget);
  });

  testWidgets('Aa focuses the field with the caret at the end', (tester) async {
    await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.enterText(_field, 'Half a thought');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    await tester.tap(find.byKey(const Key('note-page-aa')));
    await tester.pump();

    final field = tester.widget<TextField>(_field);
    expect(field.focusNode!.hasFocus, isTrue);
    expect(field.controller!.selection.baseOffset, 'Half a thought'.length);
  });

  testWidgets('Done pops with the trimmed draft; Cancel pops with null', (
    tester,
  ) async {
    await _pumpHost(tester);
    await tester.pumpAndSettle();
    await tester.enterText(_field, '  The lake.  ');
    await tester.tap(find.byKey(const Key('note-page-done')));
    await tester.pumpAndSettle();
    expect(_host(tester).result, 'The lake.');

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('note-page-cancel')));
    await tester.pumpAndSettle();
    expect(_host(tester).popped, isTrue);
    expect(_host(tester).result, isNull);
  });

  testWidgets('the dock rides above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pumpHost(tester);
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 336);
    await tester.pump();

    final dock = tester.getRect(find.byKey(const Key('note-page-dock')));
    expect(dock.bottom, lessThanOrEqualTo(874 - 336));
    expect(dock.top, greaterThan(0));
  });

  testWidgets('body text sits on the 30px rule grid', (tester) async {
    await _pumpHost(
      tester,
      existingText:
          'A long first entry that will wrap onto more than one '
          'line of the notebook page, because it keeps going and going.',
    );
    await tester.pumpAndSettle();

    final rules = find.ancestor(
      of: _field,
      matching: find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter != null,
      ),
    );
    final top = tester.getTopLeft(rules.first).dy;
    final existing = tester.getRect(
      find.byKey(const Key('note-page-existing')),
    );
    final field = tester.getTopLeft(_field).dy;

    expect((existing.top - top) % 30, closeTo(0, .01));
    expect(existing.height % 30, closeTo(0, .01));
    expect(existing.height, greaterThanOrEqualTo(60));
    expect((field - top) % 30, closeTo(0, .01));
  });

  group('voice dictation (#206)', () {
    final mic = find.byKey(const Key('note-page-mic'));

    TextField field(WidgetTester tester) => tester.widget<TextField>(_field);

    Future<FakeDictationService> openListening(WidgetTester tester) async {
      final service = FakeDictationService();
      await _pumpHost(tester, dictation: service);
      await tester.pumpAndSettle();
      await tester.tap(mic);
      await tester.pump();
      return service;
    }

    testWidgets('idle: "Tap to talk", no waveform', (tester) async {
      await _pumpHost(tester);
      await tester.pumpAndSettle();

      expect(find.text('Tap to talk'), findsOneWidget);
      expect(find.byKey(const Key('note-page-waveform')), findsNothing);
    });

    testWidgets('mic → waveform + timer; words appear live; tap again → '
        'stops and the text stays', (tester) async {
      final service = await openListening(tester);

      expect(find.byKey(const Key('note-page-waveform')), findsOneWidget);
      expect(find.byKey(const Key('note-page-mic-stop')), findsOneWidget);
      expect(find.text('Tap to stop'), findsOneWidget);
      expect(find.text('LISTENING · 0:00'), findsOneWidget);

      await tester.pump(const Duration(seconds: 7));
      expect(find.text('LISTENING · 0:07'), findsOneWidget);

      service.partial('the water was');
      await tester.pump();
      expect(field(tester).controller!.text, 'the water was');
      service.partial('the water was so still');
      await tester.pump();
      expect(field(tester).controller!.text, 'the water was so still');
      expect(find.text('+5 words'), findsOneWidget);

      await tester.tap(mic);
      await tester.pump();
      expect(service.stopCallCount, 1);
      expect(find.byKey(const Key('note-page-waveform')), findsNothing);
      expect(find.text('Tap to talk'), findsOneWidget);
      expect(field(tester).controller!.text, 'the water was so still');
      await tester.pumpAndSettle();
    });

    testWidgets('Aa while listening stops, focuses the field, caret at end', (
      tester,
    ) async {
      final service = await openListening(tester);
      service.partial('the lake');
      await tester.pump();

      await tester.tap(find.byKey(const Key('note-page-aa')));
      await tester.pump();

      expect(service.stopCallCount, 1);
      expect(find.text('Tap to talk'), findsOneWidget);
      expect(field(tester).focusNode!.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(field(tester).controller!.selection.baseOffset, 'the lake'.length);
    });

    testWidgets('mic while typing dismisses the keyboard, then listens', (
      tester,
    ) async {
      final service = FakeDictationService();
      await _pumpHost(tester, dictation: service);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-page-aa')));
      await tester.pump();
      expect(field(tester).focusNode!.hasFocus, isTrue);

      await tester.tap(mic);
      await tester.pump();

      expect(field(tester).focusNode!.hasFocus, isFalse);
      expect(service.listenCallCount, 1);
      expect(find.text('Tap to stop'), findsOneWidget);
      await tester.tap(mic); // stop, so the ticker is gone
      await tester.pump();
    });

    testWidgets('permission denied: inline message, typing still works', (
      tester,
    ) async {
      final service = FakeDictationService()
        ..readiness = DictationReadiness.permissionDenied;
      await _pumpHost(tester, dictation: service);
      await tester.pumpAndSettle();

      await tester.tap(mic);
      await tester.pump();

      expect(
        find.text('Microphone is off. Turn it on in Settings, or just type.'),
        findsOneWidget,
      );
      expect(find.text('Tap to talk'), findsOneWidget);
      await tester.enterText(_field, 'Typed instead.');
      await tester.pump();
      expect(find.text('+2 words'), findsOneWidget);

      // The mic stays tappable and asks again.
      await tester.tap(mic);
      await tester.pump();
      expect(service.prepareCallCount, 2);
    });

    testWidgets('an unavailable recogniser says typing works', (tester) async {
      final service = FakeDictationService()
        ..readiness = DictationReadiness.unavailable;
      await _pumpHost(tester, dictation: service);
      await tester.pumpAndSettle();
      await tester.tap(mic);
      await tester.pump();

      expect(
        find.text("Voice isn't available right now — typing works."),
        findsOneWidget,
      );
    });

    testWidgets('Done while listening stops first and saves what was heard', (
      tester,
    ) async {
      final service = await openListening(tester);
      service.partial('the lake at dawn');
      await tester.pump();

      await tester.tap(find.byKey(const Key('note-page-done')));
      await tester.pumpAndSettle();

      expect(service.stopCallCount, 1);
      expect(_host(tester).result, 'the lake at dawn');
    });

    testWidgets('Discard while listening cancels the session', (tester) async {
      final service = await openListening(tester);
      service.partial('never mind');
      await tester.pump();

      await tester.tap(find.byKey(const Key('note-page-cancel')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('note-page-discard')));
      await tester.pumpAndSettle();

      expect(_host(tester).popped, isTrue);
      expect(_host(tester).result, isNull);
      expect(service.cancelCallCount, 1);
    });
  });
}
