import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_neon_night.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_from_wrap_up.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_scene_spec.dart';
import 'package:traviato/features/wrap_up/presentation/film/neon_night/neon_night_story.dart';

/// [id] taken at [hour]:[minute] on the phone's clock, 14 Nov 2026 (a
/// later hour past midnight rolls into the next day).
WrapUpNeonPhoto _p(String id, int hour, [int minute = 0]) =>
    WrapUpNeonPhoto(id: id, takenAt: DateTime(2026, 11, 14, hour, minute));

final _ch1 = [_p('a1', 22, 10), _p('a2', 22, 20), _p('a3', 22, 40)];
final _ch2 = [
  for (var i = 0; i < 12; i++) _p('b$i', 23, 40 + i),
];
final _ch3 = [_p('c1', 25, 10), _p('c2', 25, 30), _p('c3', 27, 10)];

WrapUpNeonNight _nn() => WrapUpNeonNight(
  title: 'Night out',
  startDate: DateTime(2026, 11, 14),
  plan: const [
    WrapUpNeonPlanRow(time: '22:00', title: 'Pre-drinks', done: true),
    WrapUpNeonPlanRow(time: '03:00', title: 'Afterparty'),
  ],
  chapters: [
    WrapUpNeonChapter(
      title: 'Doors open',
      photos: _ch1,
      note: 'Queue was worth it.',
      moments: const [
        WrapUpNeonMoment(
          type: 'split',
          photoIds: ['a1', 'a2'],
          place: 'Main stage',
        ),
        WrapUpNeonMoment(type: 'burst', photoIds: ['a2', 'a3']),
      ],
    ),
    WrapUpNeonChapter(
      title: 'After midnight',
      photos: _ch2,
      moments: const [
        WrapUpNeonMoment(type: 'timeline', photoIds: ['b0', 'b3', 'b6']),
      ],
    ),
    WrapUpNeonChapter(
      title: 'Peak time',
      photos: _ch3,
      moments: const [
        WrapUpNeonMoment(type: 'peak', photoIds: ['c1', 'c2', 'c3']),
      ],
    ),
  ],
  note: WrapUpNeonNote(
    text: 'Best night ever',
    number: 4,
    writtenAt: DateTime(2026, 11, 15, 0, 31),
    photoId: 'c2',
  ),
  headline: 'Best night ever',
  firstName: 'Leo',
  totals: const WrapUpNeonTotals(photos: 18, notes: 4, ticks: 1, moments: 18),
);

Set<String> _all() => {
  for (final chapter in _nn().chapters)
    for (final photo in chapter.photos) photo.id,
};

void main() {
  test('maps every piece, on the phone clock (#363)', () {
    final story = neonNightFromWrapUp(_nn(), photoIds: _all())!;

    expect(story.title, 'Night out');
    expect(story.date, DateTime(2026, 11, 14));
    expect(story.plan, const [
      NnPlanRow(time: '22:00', item: 'Pre-drinks', done: true),
      NnPlanRow(time: '03:00', item: 'Afterparty'),
    ]);
    expect(story.chapters.map((c) => (c.title, c.from, c.to)), [
      ('Doors open', '22:10', '23:40'),
      ('After midnight', '23:40', '01:10'),
      ('Peak time', '01:10', '03:10'),
    ]);
    final first = story.chapters.first;
    expect(first.note, 'Queue was worth it.');
    expect(first.moments.map((m) => m.type), [
      NnMomentType.split,
      NnMomentType.burst,
    ]);
    expect((first.moments.first as NnSplit).place, 'Main stage');
    expect(
      first.moments.first.photos.first,
      const NnPhoto(
        id: 'a1',
        takenAt: '22:10',
      ),
    );
    expect(
      story.note,
      const NnNoteMoment(
        text: 'Best night ever',
        number: 4,
        time: '00:31',
        photo: NnPhoto(id: 'c2', takenAt: '01:30'),
      ),
    );
    expect(story.firstName, 'Leo');
    expect(story.headline, 'Best night ever');
    expect(story.endTotals.photos, 18);
  });

  test('photos that are gone: moments that no longer fit are dropped', () {
    final story = neonNightFromWrapUp(
      _nn(),
      photoIds: _all().difference({'a1', 'c3', 'b3'}),
    )!;

    // The split fell under 2; the burst stays.
    expect(story.chapters[0].moments.map((m) => m.type), [
      NnMomentType.burst,
    ]);
    expect(story.chapters[1].moments.single.photos.map((p) => p.id), [
      'b0',
      'b6',
    ]);
    // The peak fell under 3: a timeline of what's left instead.
    final last = story.chapters[2];
    expect(last.moments.single, isA<NnTimeline>());
    expect(last.moments.single.photos.map((p) => p.id), ['c1', 'c2']);
    expect(last.to, '01:30');
  });

  test('a chapter under 2 photos is skipped; none left means no film', () {
    final story = neonNightFromWrapUp(
      _nn(),
      photoIds: _all().difference({'c1', 'c2'}),
    )!;
    expect(story.chapters.map((c) => c.title), [
      'Doors open',
      'After midnight',
    ]);
    // The last chapter now ends at its own last photo.
    expect(story.chapters.last.to, '23:51');
    // The note's photo is gone: the haze shows through.
    expect(story.note!.photo, isNull);

    expect(neonNightFromWrapUp(_nn(), photoIds: {'a1', 'b0', 'c1'}), isNull);
  });

  test('the live start date wins; without any, the first photo day', () {
    final edited = neonNightFromWrapUp(
      _nn(),
      photoIds: _all(),
      startDate: DateTime(2026, 11, 13),
    )!;
    expect(edited.date, DateTime(2026, 11, 13));

    final nn = _nn();
    final undated = WrapUpNeonNight(title: nn.title, chapters: nn.chapters);
    expect(
      neonNightFromWrapUp(undated, photoIds: _all())!.date,
      DateTime(2026, 11, 14),
    );
  });

  test('a moment over its count plays its first photos', () {
    final nn = _nn();
    final busy = WrapUpNeonNight(
      title: nn.title,
      chapters: [
        WrapUpNeonChapter(
          title: 'After midnight',
          photos: _ch2,
          moments: [
            WrapUpNeonMoment(
              type: 'timeline',
              photoIds: [for (final p in _ch2) p.id],
            ),
          ],
        ),
      ],
    );
    final story = neonNightFromWrapUp(busy, photoIds: _all())!;
    expect(story.chapters.single.moments.single.photos, hasLength(8));
  });

  test('the heart: its own photos when sent, else every photo (#378)', () {
    final legacy = neonNightFromWrapUp(_nn(), photoIds: _all())!;
    expect(legacy.heartIds, [for (final p in legacy.allPhotos) p.id]);

    final nn = _nn();
    final withHeart = WrapUpNeonNight(
      title: nn.title,
      startDate: nn.startDate,
      chapters: nn.chapters,
      heartPhotoIds: const ['a3', 'b1', 'gone', 'c3'],
    );
    final all = _all()..remove('c3');
    final story = neonNightFromWrapUp(withHeart, photoIds: all)!;
    // Photos the memory no longer has drop out of the heart.
    expect(story.heartIds, ['a3', 'b1']);
    expect(story.allPhotos.length, greaterThan(story.heartIds.length));
  });

  test('the card shows its own photos; without them, all (#390)', () {
    final legacy = neonNightFromWrapUp(_nn(), photoIds: _all())!;
    expect(legacy.chapters[1].cardPhotos, legacy.chapters[1].photos);

    final nn = _nn();
    final withCard = WrapUpNeonNight(
      title: nn.title,
      startDate: nn.startDate,
      chapters: [
        for (final (i, c) in nn.chapters.indexed)
          WrapUpNeonChapter(
            title: c.title,
            photos: c.photos,
            note: c.note,
            moments: c.moments,
            cardPhotoIds: i == 1 ? const ['b9', 'b10', 'gone'] : const [],
          ),
      ],
    );
    final story = neonNightFromWrapUp(withCard, photoIds: _all())!;
    expect(story.chapters[1].cardPhotos.map((p) => p.id), ['b9', 'b10']);
    // The chapter's range is unchanged.
    expect(story.chapters[1].photos, hasLength(12));
  });

  test('the Plan scene needs 3 rows (#390)', () {
    final story = neonNightFromWrapUp(_nn(), photoIds: _all())!;
    expect(story.plan, hasLength(2));
    expect(story.hasPlan, isFalse);

    final nn = _nn();
    final three = WrapUpNeonNight(
      title: nn.title,
      startDate: nn.startDate,
      chapters: nn.chapters,
      plan: [
        ...nn.plan,
        const WrapUpNeonPlanRow(time: '05:00', title: 'Breakfast'),
      ],
    );
    expect(neonNightFromWrapUp(three, photoIds: _all())!.hasPlan, isTrue);
  });
}
