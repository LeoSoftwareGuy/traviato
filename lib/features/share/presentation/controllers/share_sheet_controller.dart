import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../domain/entities/share_link.dart';
import '../providers/share_providers.dart';
import 'share_preview_builder.dart';

part 'share_sheet_controller.g.dart';

/// The share sheet's link (#311, design 1a): live, being turned off
/// (step 2 of the two-step revoke), or turned off with "Make a new link".
class ShareSheetState extends Equatable {
  const ShareSheetState({
    this.link,
    this.revokedLink,
    this.isConfirmingRevoke = false,
    this.isBusy = false,
  });

  /// The active link; null once turned off.
  final ShareLink? link;

  /// The link just turned off — shown struck through.
  final ShareLink? revokedLink;
  final bool isConfirmingRevoke;

  /// A revoke or new-link call is in flight.
  final bool isBusy;

  bool get isLive => link != null;

  ShareSheetState copyWith({bool? isConfirmingRevoke, bool? isBusy}) =>
      ShareSheetState(
        link: link,
        revokedLink: revokedLink,
        isConfirmingRevoke: isConfirmingRevoke ?? this.isConfirmingRevoke,
        isBusy: isBusy ?? this.isBusy,
      );

  @override
  List<Object?> get props => [link, revokedLink, isConfirmingRevoke, isBusy];
}

/// Opening the sheet makes (or reuses) the memory's link. A link whose
/// public preview isn't built yet starts the background build (#309) —
/// nothing waits on it.
@riverpod
class ShareSheetController extends _$ShareSheetController {
  @override
  Future<ShareSheetState> build(String tripId) async {
    final link = await _create();
    return ShareSheetState(link: link);
  }

  Future<ShareLink> _create() async {
    final link =
        (await ref
                .read(shareRepositoryProvider)
                .createLink(
                  tripId,
                ))
            .getOrElse((f) => throw PresentationFailureException(f));
    if (!link.isPreviewBuilt) {
      unawaited(ref.read(sharePreviewBuilderProvider.notifier).buildFor(link));
    }
    return link;
  }

  void askRevoke() => _update((s) => s.copyWith(isConfirmingRevoke: true));

  void cancelRevoke() => _update((s) => s.copyWith(isConfirmingRevoke: false));

  /// Step 2 confirmed. Returns whether the link is off; on failure the
  /// sheet stays as it was and the caller shows the error.
  Future<bool> revoke() async {
    final current = state.value;
    final link = current?.link;
    if (current == null || link == null || current.isBusy) return false;
    state = AsyncData(current.copyWith(isBusy: true));
    final result = await ref.read(shareRepositoryProvider).revokeLink(link);
    return result.fold(
      (failure) {
        state = AsyncData(current.copyWith(isBusy: false));
        throw PresentationFailureException(failure);
      },
      (_) {
        state = AsyncData(ShareSheetState(revokedLink: link));
        return true;
      },
    );
  }

  /// "Make a new link" after turning one off.
  Future<void> makeNewLink() async {
    final current = state.value;
    if (current == null || current.isBusy) return;
    state = AsyncData(current.copyWith(isBusy: true));
    try {
      final link = await _create();
      state = AsyncData(ShareSheetState(link: link));
    } catch (_) {
      state = AsyncData(current.copyWith(isBusy: false));
      rethrow;
    }
  }

  void _update(ShareSheetState Function(ShareSheetState) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
