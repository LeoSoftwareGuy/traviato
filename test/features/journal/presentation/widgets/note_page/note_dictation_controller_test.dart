import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/journal/domain/dictation/dictation_service.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/note_dictation_controller.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/note_draft_controller.dart';

import '../../../fakes/fake_dictation_service.dart';

void main() {
  late FakeDictationService service;
  late NoteDraftController draft;
  late NoteDictationController dictation;

  setUp(() {
    service = FakeDictationService();
    draft = NoteDraftController();
    dictation = NoteDictationController(service: service, draft: draft);
  });

  tearDown(() {
    dictation.dispose();
    draft.dispose();
  });

  test('listens with the 8s silence and 90s caps', () async {
    await dictation.start();
    expect(dictation.isListening, isTrue);
    expect(service.lastPauseFor, const Duration(seconds: 8));
    expect(service.lastListenFor, const Duration(seconds: 90));
  });

  test('partials stream in as pending; final settles them', () async {
    draft.value = const TextEditingValue(
      text: 'Woke early.',
      selection: TextSelection.collapsed(offset: 11),
    );
    await dictation.start();

    service.partial('then the');
    await Future<void>.delayed(Duration.zero);
    expect(draft.text, 'Woke early. then the');
    expect(draft.pending, const TextRange(start: 12, end: 20));

    service.finalWords('then the lake');
    await Future<void>.delayed(Duration.zero);
    expect(draft.text, 'Woke early. then the lake');
    expect(draft.pending.isValid, isFalse);
  });

  test('stop keeps the words heard so far and goes idle', () async {
    await dictation.start();
    service.partial('the lake');
    await Future<void>.delayed(Duration.zero);

    await dictation.stop();
    expect(dictation.isListening, isFalse);
    expect(service.stopCallCount, 1);
    expect(draft.text, 'the lake');
    expect(draft.pending.isValid, isFalse);
  });

  test(
    'a late final after stop still lands, a late partial does not',
    () async {
      await dictation.start();
      service.partial('the lake');
      await Future<void>.delayed(Duration.zero);
      await dictation.stop();

      service.partial('the lake was cold and');
      await Future<void>.delayed(Duration.zero);
      expect(draft.text, 'the lake');

      service.finalWords('the lake was cold');
      await Future<void>.delayed(Duration.zero);
      expect(draft.text, 'the lake was cold');
    },
  );

  test('never overwrites what the user typed meanwhile', () async {
    await dictation.start();
    service.partial('the lake');
    await Future<void>.delayed(Duration.zero);
    await dictation.stop();
    draft.text = 'the lake, typed';

    service.finalWords('the lake was');
    await Future<void>.delayed(Duration.zero);
    expect(draft.text, 'the lake, typed');
  });

  test('the platform ending the session (silence) returns to idle', () async {
    await dictation.start();
    await service.end();
    await Future<void>.delayed(Duration.zero);
    expect(dictation.isListening, isFalse);
    expect(dictation.notice, DictationNotice.none);
  });

  test(
    'permission denied shows the mic-off notice and never listens',
    () async {
      service.readiness = DictationReadiness.permissionDenied;
      await dictation.start();
      expect(dictation.isListening, isFalse);
      expect(dictation.notice, DictationNotice.micOff);
      expect(service.listenCallCount, 0);

      // Tapping again re-asks.
      service.readiness = DictationReadiness.ready;
      await dictation.start();
      expect(service.prepareCallCount, 2);
      expect(dictation.isListening, isTrue);
      expect(dictation.notice, DictationNotice.none);
    },
  );

  test('an unavailable recogniser shows the typing-works notice', () async {
    service.readiness = DictationReadiness.unavailable;
    await dictation.start();
    expect(dictation.notice, DictationNotice.unavailable);
  });

  test('a mid-session failure stops listening with a notice', () async {
    await dictation.start();
    await service.end(
      const DictationFailed(DictationReadiness.unavailable),
    );
    await Future<void>.delayed(Duration.zero);
    expect(dictation.isListening, isFalse);
    expect(dictation.notice, DictationNotice.unavailable);
  });

  test('the timer ticks each second and stops itself at 90s', () {
    fakeAsync((async) {
      dictation.start();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 7));
      expect(dictation.elapsed, const Duration(seconds: 7));

      async.elapse(const Duration(seconds: 83));
      expect(dictation.isListening, isFalse);
      expect(service.stopCallCount, 1);
    });
  });

  test('levels are normalised per session into .3…1', () async {
    await dictation.start();
    expect(dictation.hasLiveLevels, isFalse);
    for (final level in [-2.0, 10.0, 4.0]) {
      service.emit(DictationLevel(level));
    }
    await Future<void>.delayed(Duration.zero);

    expect(dictation.hasLiveLevels, isTrue);
    final levels = dictation.levels;
    expect(levels, hasLength(NoteDictationController.barCount));
    expect(levels.last, closeTo(.3 + .7 * .5, 1e-9));
    expect(levels[levels.length - 2], closeTo(1, 1e-9));
    expect(levels.every((l) => l >= .3 && l <= 1), isTrue);
  });

  test('a flat mic level keeps the fallback waveform', () async {
    await dictation.start();
    for (var i = 0; i < 5; i++) {
      service.emit(const DictationLevel(0));
    }
    await Future<void>.delayed(Duration.zero);
    expect(dictation.hasLiveLevels, isFalse);
  });

  test('cancel drops the session', () async {
    await dictation.start();
    await dictation.cancel();
    expect(dictation.isListening, isFalse);
    expect(service.cancelCallCount, 1);
  });
}
