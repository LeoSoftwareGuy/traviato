import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/controllers/auth_state.dart';
import '../../domain/entities/shared_memory_preview.dart';
import 'share_providers.dart';

part 'shared_memory_view_provider.g.dart';

/// What `/m/{slug}` shows (#310).
sealed class SharedMemoryView extends Equatable {
  const SharedMemoryView();

  @override
  List<Object?> get props => [];
}

/// Unknown, revoked or deleted — one screen for all three (2d), so it
/// never hints that a slug once existed.
final class SharedMemoryUnavailable extends SharedMemoryView {
  const SharedMemoryUnavailable();
}

/// The signed-in owner's own link: they go to their Kept Memory page.
final class SharedMemoryOwn extends SharedMemoryView {
  const SharedMemoryOwn({required this.tripId});

  final String tripId;

  @override
  List<Object?> get props => [tripId];
}

/// The teaser (2c), for anyone else.
final class SharedMemoryTeaser extends SharedMemoryView {
  const SharedMemoryTeaser({required this.preview, required this.signedIn});

  final SharedMemoryPreview preview;
  final bool signedIn;

  @override
  List<Object?> get props => [preview, signedIn];
}

@riverpod
Future<SharedMemoryView> sharedMemoryView(Ref ref, String slug) async {
  final repo = ref.watch(shareRepositoryProvider);
  final signedIn =
      ref.watch(authControllerProvider).status == AuthStatus.authenticated;
  if (signedIn) {
    final own = (await repo.findOwnTripIdForSlug(slug)).getOrElse((f) => null);
    if (own != null) return SharedMemoryOwn(tripId: own);
  }
  final preview = (await repo.getSharedPreview(
    slug,
  )).getOrElse((f) => throw PresentationFailureException(f));
  return preview == null
      ? const SharedMemoryUnavailable()
      : SharedMemoryTeaser(preview: preview, signedIn: signedIn);
}
