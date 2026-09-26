import 'package:fpdart/fpdart.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_cover_photo.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_dates.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_entity.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_film_cut.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_flurry_leftovers.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_footnote.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_invitation.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_keepsake.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_moment.dart';
import 'package:traviato/features/wrap_up/domain/entities/wrap_up_unlock.dart';
import 'package:traviato/features/wrap_up/domain/repositories/wrap_up_repository.dart';

class FakeWrapUpRepository implements WrapUpRepository {
  Either<Failure, WrapUpEntity>? getOrGenerateResult;
  Either<Failure, void>? publishResult;
  var getOrGenerateCallCount = 0;
  var publishCallCount = 0;

  /// Delays [getOrGenerate] so tests can observe the loading state.
  Duration delay = Duration.zero;

  @override
  Future<Either<Failure, WrapUpEntity>> getOrGenerate(String tripId) async {
    getOrGenerateCallCount++;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return getOrGenerateResult ?? Right(buildWrapUpEntity());
  }

  @override
  Future<Either<Failure, void>> publish(String tripId) async {
    publishCallCount++;
    return publishResult ?? const Right(null);
  }
}

WrapUpEntity buildWrapUpEntity({
  WrapUpFilmCut? cut,
  WrapUpDates? dates,
  WrapUpCoverPhoto? coverPhoto,
  WrapUpInvitation? invitation,
  List<String> bridges = const ['', '', ''],
  List<WrapUpMoment> moments = const [],
  WrapUpFlurryLeftovers flurryLeftovers = const WrapUpFlurryLeftovers(),
  WrapUpFootnote? footnote,
  WrapUpUnlock? unlock,
  WrapUpKeepsake? keepsake,
  DateTime? generatedAt,
  DateTime? publishedAt,
}) {
  return WrapUpEntity(
    cut: cut,
    dates: dates ?? const WrapUpDates(formatted: '1–5 June 2026'),
    coverPhoto: coverPhoto ?? const WrapUpCoverPhoto(imagePath: 'asset:hero'),
    invitation:
        invitation ??
        const WrapUpInvitation(line1: 'Five days.', line2: 'One long road.'),
    bridges: bridges,
    moments: moments,
    flurryLeftovers: flurryLeftovers,
    footnote:
        footnote ??
        const WrapUpFootnote(photoCount: 0, bonusCompletedCount: 0, stars: 0),
    unlock: unlock,
    keepsake:
        keepsake ??
        const WrapUpKeepsake(
          titleLine1: 'Dolomites,',
          titleLine2: 'slowly',
          closingQuote: "This one you'll keep.",
        ),
    generatedAt: generatedAt ?? DateTime(2026, 1, 1),
    publishedAt: publishedAt,
  );
}
