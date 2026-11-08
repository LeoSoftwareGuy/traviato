import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/presentation_failure_exception.dart';
import '../../../settings/presentation/controllers/app_language_controller.dart';
import '../controllers/wrap_up_controller.dart';
import '../providers/film_director_providers.dart';

final rerunDirectorMutation = Mutation<void>();

/// The Plan inspector's "Re-run director" (#328, debug builds only): runs
/// the director again, then reloads the inspector and the film (a draft's
/// content picks up the new plan; a kept film's content never changes).
Future<void> runRerunDirector({
  required WidgetRef ref,
  required String tripId,
}) {
  return rerunDirectorMutation.run(ref, (tsx) async {
    final result = await tsx
        .get(filmDirectorRepositoryProvider)
        .rerun(tripId, language: tsx.get(resolvedAppLanguageProvider).code!);
    result.fold((failure) => throw PresentationFailureException(failure), (_) {
      ref.invalidate(filmPlanInspectionProvider(tripId));
      ref.invalidate(wrapUpControllerProvider(tripId));
    });
  });
}
