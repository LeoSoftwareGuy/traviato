import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/events/global_event.dart';
import '../../../../core/events/global_event_bus.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../bonus/presentation/providers/bonus_task_providers.dart';
import '../../../photo/presentation/providers/photo_providers.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../../../trip/presentation/providers/trip_providers.dart';
import '../../domain/entities/og_card_content.dart';
import '../../domain/entities/share_link.dart';
import '../../domain/share_teaser_photos.dart';
import '../providers/share_providers.dart';

part 'share_preview_builder.g.dart';

/// At most one rebuild per memory per this long after picks change (#309).
const sharePreviewRebuildDelay = Duration(minutes: 1);

/// Builds share links' public preview images in the background (#309) —
/// nothing waits on it; the web page shows a title-only teaser until it's
/// done. Runs when the share sheet opens on a link that isn't built, and a
/// minute after the memory's photos, film picks, name or cover change while
/// it has an active link. `keepAlive` and instantiated from `main.dart`, so
/// a build outlives the sheet that started it.
@Riverpod(keepAlive: true)
class SharePreviewBuilder extends _$SharePreviewBuilder {
  final _rebuildTimers = <String, Timer>{};
  final _building = <String>{};

  @override
  void build() {
    final sub = ref.watch(globalEventBusProvider).stream.listen(_onEvent);
    ref.onDispose(() {
      unawaited(sub.cancel());
      for (final timer in _rebuildTimers.values) {
        timer.cancel();
      }
    });
  }

  void _onEvent(GlobalEvent event) {
    final tripId = switch (event) {
      FilmPhotosChangedDispatched(:final tripId) => tripId,
      TripUpdatedDispatched(:final trip) => trip.id,
      _ => null,
    };
    if (tripId == null) return;
    _rebuildTimers[tripId]?.cancel();
    _rebuildTimers[tripId] = Timer(sharePreviewRebuildDelay, () {
      _rebuildTimers.remove(tripId);
      unawaited(_rebuildIfShared(tripId));
    });
  }

  Future<void> _rebuildIfShared(String tripId) async {
    final link = await ref.read(shareRepositoryProvider).getActiveLink(tripId);
    final active = link.getOrElse((_) => null);
    if (active != null) await buildFor(active);
  }

  /// Builds [link]'s preview from the memory's current photos and picks.
  /// Never throws: failures are logged, and the next trigger retries.
  Future<void> buildFor(ShareLink link) async {
    if (!_building.add(link.tripId)) return;
    try {
      final tripId = link.tripId;
      final trip = (await ref.read(tripRepositoryProvider).getTripCard(tripId))
          .getOrElse((f) => throw StateError('trip: ${f.message}'));
      final photos =
          (await ref.read(photoRepositoryProvider).getPhotosForTrip(tripId))
              .getOrElse((f) => throw StateError('photos: ${f.message}'));
      final assignments =
          (await ref
                  .read(bonusTaskRepositoryProvider)
                  .getAssignmentsForTrip(tripId))
              .getOrElse((_) => const []);
      final completed =
          assignments
              .where((a) => a.completedAt != null && a.photoId != null)
              .toList()
            ..sort((a, b) => a.completedAt!.compareTo(b.completedAt!));

      final locale = ref.read(appLocaleProvider).languageCode;
      final start = trip.startDate;
      final end = trip.endDate;
      final eyebrow = [
        if (trip.destination?.trim().isNotEmpty ?? false) trip.destination!,
        if (start != null && end != null)
          L10nDates.dateRange(start, end, locale),
      ].join(' · ').toUpperCase();

      final result = await ref
          .read(shareRepositoryProvider)
          .buildPreview(
            link: link,
            photos: shareTeaserPhotos(
              photos: photos,
              bonusPhotoIds: [for (final a in completed) a.photoId!],
              coverImagePath: trip.coverImagePath,
            ),
            og: OgCardContent(title: trip.name, eyebrow: eyebrow),
          );
      result.fold(
        (f) => debugPrint('Share preview build failed for $tripId: $f'),
        (_) {},
      );
    } catch (e) {
      debugPrint('Share preview build threw for ${link.tripId}: $e');
    } finally {
      _building.remove(link.tripId);
    }
  }
}
