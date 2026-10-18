import '../../../../core/l10n/context_l10n.dart';
import '../controllers/journal_state.dart';

/// The explainer's `{ask}` line — "Add 2 more photos to unlock it." — in
/// the UI language, or `null` while the wrap-up isn't locked.
String? wrapUpAskLine(AppLocalizations l10n, JournalState state) {
  final missing = state.wrapUpMissing;
  if (missing == null) return null;
  if (missing.missingPhotos > 0 && missing.needsNote) {
    return l10n.journal_wrapUpAskPhotosAndNote(missing.missingPhotos);
  }
  if (missing.missingPhotos > 0) {
    return l10n.journal_wrapUpAskPhotos(missing.missingPhotos);
  }
  return l10n.journal_wrapUpAskNote;
}
