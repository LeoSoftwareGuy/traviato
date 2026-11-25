import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_theme.dart';
import 'package:traviato/features/journal/domain/entities/journal_note_entity.dart';
import 'package:traviato/features/journal/presentation/widgets/timeline/note_sheets.dart';
import 'package:traviato/l10n/app_localizations.dart';

import '../../../fakes/fake_journal_note_repository.dart';

Future<NoteAction?> _open(
  WidgetTester tester,
  JournalNoteEntity note, {
  String? tap,
}) async {
  NoteAction? result;
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.dark,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async => result = await NoteActionsSheet.show(
              context,
              note: note,
              use24h: true,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  if (tap != null) {
    await tester.tap(find.byKey(Key(tap)));
    await tester.pumpAndSettle();
  }
  return result;
}

void main() {
  // Written in November about an April day (#468).
  final backfilled = JournalNoteEntity(
    id: 'n1',
    tripId: 't1',
    dayDate: DateTime(2026, 4, 13),
    takenAt: DateTime.utc(2026, 11, 24, 18),
    editedAt: DateTime.utc(2026, 11, 24, 18),
    content: 'The Grand Mosque',
    utcOffsetMinutes: 120,
  );

  testWidgets('a backfilled note says "added later" and offers Edit time', (
    tester,
  ) async {
    await _open(tester, backfilled);
    expect(find.text('added later'), findsOneWidget);
    expect(find.text('Edit time'), findsOneWidget);
  });

  testWidgets('Edit time returns editTime', (tester) async {
    expect(
      await _open(tester, backfilled, tap: 'note-sheet-edit-time'),
      NoteAction.editTime,
    );
  });

  testWidgets('a legacy note has no Edit time', (tester) async {
    await _open(
      tester,
      buildJournalNoteEntity(
        id: 'l',
        dayDate: DateTime(2026, 4, 13),
        createdAt: DateTime(2026, 4, 13, 20),
        legacy: true,
      ),
    );
    expect(find.byKey(const Key('note-sheet-edit-time')), findsNothing);
  });
}
