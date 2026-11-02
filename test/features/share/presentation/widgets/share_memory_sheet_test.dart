import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/share/domain/entities/share_link.dart';
import 'package:traviato/features/share/presentation/providers/share_memory_provider.dart';
import 'package:traviato/features/share/presentation/providers/share_providers.dart';
import 'package:traviato/features/share/presentation/widgets/share_link_field.dart';
import 'package:traviato/features/share/presentation/widgets/share_memory_sheet.dart';

import '../../../../helpers/localized_app.dart';
import '../../../trip/fakes/fake_trip_repository.dart';
import '../../fakes/fake_share_repository.dart';

/// Holds `createLink` until [complete] — the sheet's loading state.
class _SlowShareRepository extends FakeShareRepository {
  final _pending = Completer<Either<Failure, ShareLink>>();

  void complete() => _pending.complete(createResult);

  @override
  Future<Either<Failure, ShareLink>> createLink(String tripId) async {
    calls.add('create $tripId');
    return _pending.future;
  }
}

final _builtAt = DateTime.utc(2026, 11, 2);

void main() {
  late FakeShareRepository repo;
  String? clipboard;

  setUp(() {
    repo = FakeShareRepository()
      ..createResult = Right(buildShareLink(previewBuiltAt: _builtAt));
    clipboard = null;
  });

  Future<void> pumpSheet(WidgetTester tester, {bool settle = true}) async {
    setScreenSize(tester, width: 360, height: 800);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          shareRepositoryProvider.overrideWithValue(repo),
          shareMemoryProvider('t1').overrideWith(
            (ref) async => ShareMemory(
              trip: buildTripCard(name: 'One long road'),
              teaserPhotos: const [],
            ),
          ),
        ],
        child: localizedApp(
          locale: const Locale('en'),
          home: const Scaffold(body: ShareMemorySheet(tripId: 't1')),
        ),
      ),
    );
    if (settle) await tester.pump();
    if (settle) await tester.pump();
  }

  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump();
  }

  testWidgets('loading: a shimmering link and disabled tiles (#311)', (
    tester,
  ) async {
    final slow = _SlowShareRepository()..createResult = repo.createResult;
    repo = slow;
    await pumpSheet(tester, settle: false);
    await tester.pump();

    expect(find.byKey(const ValueKey('share-link-shimmer')), findsOneWidget);
    final copy = tester.widget<TextButton>(
      find.byKey(const ValueKey('share-copy')),
    );
    expect(copy.onPressed, isNull);

    slow.complete();
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('share-link-shimmer')), findsNothing);
  });

  testWidgets('live: the link, the tiles and what people see', (
    tester,
  ) async {
    await pumpSheet(tester);

    expect(repo.calls, ['create t1']);
    expect(find.text('Share “One long road”'), findsOneWidget);
    expect(find.text('Anyone with the link can see a preview'), findsOneWidget);
    expect(
      find.text('storyni.app/m/k7Qm2xPa9c', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Share…'), findsOneWidget);
    expect(find.text('QR code'), findsOneWidget);
    expect(find.text('Story card'), findsOneWidget);
    expect(find.text('WHAT PEOPLE SEE'), findsOneWidget);
    expect(
      find.text('Never your notes, map spots, expenses or quests'),
      findsOneWidget,
    );
    expect(find.text('Turn off link'), findsOneWidget);
  });

  testWidgets('copy: the URL, "Copied ✓" for 1.6s, then Copy again', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tapAndWait(tester, find.byKey(const ValueKey('share-copy')));
    expect(clipboard, 'https://storyni.app/m/k7Qm2xPa9c');
    expect(find.text('Copied ✓'), findsOneWidget);
    expect(find.text('Link copied'), findsOneWidget);

    await tester.pump(ShareLinkField.copiedFor);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Copy'), findsOneWidget);
    expect(find.text('Link copied'), findsNothing);
  });

  testWidgets('turn off is two steps; Keep it backs out', (tester) async {
    await pumpSheet(tester);

    await tapAndWait(tester, find.text('Turn off link'));
    expect(find.text('Turn off this link?'), findsOneWidget);
    expect(repo.calls, isNot(contains('revoke k7Qm2xPa9c')));

    await tapAndWait(tester, find.text('Keep it'));
    expect(find.text('Turn off this link?'), findsNothing);
    expect(find.text('Turn off link'), findsOneWidget);
  });

  testWidgets('revoked: struck-through link, then "Make a new link"', (
    tester,
  ) async {
    await pumpSheet(tester);

    await tapAndWait(tester, find.text('Turn off link'));
    await tapAndWait(
      tester,
      find.byKey(const ValueKey('share-turn-off-confirm')),
    );
    expect(repo.calls, contains('revoke k7Qm2xPa9c'));
    expect(find.text('No link right now'), findsOneWidget);
    expect(find.text('storyni.app/m/k7Qm2xPa9c'), findsOneWidget);
    expect(
      find.text('People who open it now see “This link was turned off.”'),
      findsOneWidget,
    );
    expect(find.text('Turn off link'), findsNothing);
    expect(find.text('Link turned off'), findsOneWidget);

    repo.createResult = Right(
      buildShareLink(slug: 'Zz9Yy8Xx7W', previewBuiltAt: _builtAt),
    );
    await tester.pump(const Duration(seconds: 2));
    await tapAndWait(tester, find.byKey(const ValueKey('share-new-link')));
    expect(
      find.text('storyni.app/m/Zz9Yy8Xx7W', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('New link ready'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('error: an inline retry that makes the link', (tester) async {
    repo.createResult = const Left(NetworkFailure());
    await pumpSheet(tester);

    expect(find.text("Couldn't make a link. Try again"), findsOneWidget);
    expect(find.byKey(const ValueKey('share-copy')), findsNothing);

    repo.createResult = Right(buildShareLink(previewBuiltAt: _builtAt));
    await tapAndWait(tester, find.byKey(const ValueKey('share-retry')));
    await tester.pump();
    expect(
      find.text('storyni.app/m/k7Qm2xPa9c', findRichText: true),
      findsOneWidget,
    );
  });
}
