# Coding Standards
 
## Linting and formatting
 
- Lints: `flutter_lints` (or `very_good_analysis` for stricter defaults) — configured in `analysis_options.yaml`. Zero analyzer warnings in PRs.
- Formatting: `dart format` with default settings. Run before every commit.
## Naming
 
- Files: `snake_case.dart`. One public class per file, file named after it (`login_screen.dart` → `LoginScreen`).
- Classes/enums/typedefs: `UpperCamelCase`. Members/variables: `lowerCamelCase`. Constants: `lowerCamelCase` (not SCREAMING_CAPS).
- Widgets end in what they are: `LoginScreen`, `AvatarTile`, `PrimaryButton`.
- Booleans read as predicates: `isLoading`, `hasError`, `canSubmit`.
## Widgets and UI
 
- Prefer small, composable widgets over deep build methods. If a `build` method exceeds ~60 lines, extract widgets (real classes, not helper methods returning widgets).
- Use `const` constructors wherever possible.
- All user-facing strings go through the localization file, even if the app ships in one language at first.
- Colors, text styles, spacing come from `core/theme/` — never inline `Color(0xFF...)` or `TextStyle(...)` in feature code.
- Every screen handles three states explicitly: loading, error, data.
## Error handling
 
- Repositories catch Supabase/network exceptions and return typed `Failure`s (sealed classes) — no raw exceptions crossing into domain/presentation.
- Never swallow errors silently. Log unexpected ones; show a user-friendly message for expected ones.
- No `print()` — use the project logger.
## Async
 
- No unawaited futures without `unawaited(...)` and a comment.
- Check `mounted` / use safe patterns before using `BuildContext` after `await`.
## Tests (required for every PR)
 
- Unit tests for use cases and mappers.
- Widget tests for new screens: renders loading/error/data states correctly.
- Repository tests against fakes; no live Supabase calls in tests.
- Test file mirrors source path: `lib/features/auth/domain/login_use_case.dart` → `test/features/auth/domain/login_use_case_test.dart`.
- A PR without tests for new logic is incomplete.
## Dependencies
 
- Adding a new package requires a one-line justification in the PR description.
- Prefer well-maintained, popular packages; avoid abandoned ones.