# CLAUDE.md
 
## Project
 
Trevy — a mobile app built with Flutter (Dart) and Supabase.
One-line description: the place where your travel life lives — plan your trip, log it as you go, and it becomes a beautiful journal you keep forever.
 
## Golden rules (non-negotiable)
 
1. **Never commit or push to `main`.** All work happens on feature branches.
2. **Every task starts from a GitHub Issue.** Branch name: `feat/<issue-number>-<short-slug>` (e.g. `feat/12-authentication`). Fixes: `fix/<issue-number>-<slug>`.
3. **Every change ends in a Pull Request** targeting `main`, linked to its issue (`Closes #12` in the description). Fill in the PR template completely. Do not merge PRs — the human reviews and merges.
4. **Commits are small and descriptive.** Conventional Commits format: `feat(auth): add login screen`, `fix(profile): handle null avatar`.
5. **Database changes only via migration files** in `supabase/migrations/`. Never mutate the remote database schema directly through the Supabase MCP. MCP is for inspecting schema, reading logs, and querying the dev branch only.
6. **Ask before destructive actions** (deleting files, dropping tables, force-pushing, changing CI config).
7. **If a Figma frame and this doc conflict, ask** rather than guessing.
## Before opening a PR, run and pass:
 
```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```
 
## Detailed guides (read the relevant one before starting a task)
- Backlog with milestones and issues: @docs/issue-backlog.md
- Overall planed scope of app functionalities: @docs/functionality.md
- Backend architecture design: @docs/data-model.md
- Architecture and folder structure: @docs/guidelines.md,00-tech-stack-and-philosophy.md, 01-architecture-and-folder-structure.md,
02-riverpod-conventions.md,
03-error-handling.md,
04-data-layer-supabase.md,
05-domain-layer.md,
06-presentation-controllers-and-mutations.md,
07-routing-gorouter.md,
08-cross-feature-communication.md,
09-naming-and-style-cheatsheet.md,
10-anti-patterns-and-evolution.md
- Dart/Flutter coding standards: @docs/coding-standards.md
- Supabase rules (migrations, RLS, edge functions): @docs/supabase.md
- Task workflow, branches and PRs: @docs/workflow.md
## Figma
 
Designs live in: https://www.figma.com/design/5Z1A1H6eNNsaJN3sbEsNIh/Leo-s-team-library?node-id=449-2&t=QPDHq0Yeo6yxU08J-0
open journey page for the design.

When implementing UI, pull the exact values (spacing, colors, typography) from the Figma MCP for the specific frame named in the issue. Map design tokens to the theme in `lib/core/theme/` — never hardcode colors or text styles in widgets.