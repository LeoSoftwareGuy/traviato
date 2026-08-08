# Task Workflow
 
## Lifecycle of every task
 
1. **Issue.** Work starts from a GitHub Issue with: a clear title ("Implement authentication screens"), acceptance criteria, and a link to the relevant Figma frame(s) if UI is involved.
2. **Branch.** Create `feat/<issue-number>-<slug>` from the latest `main`.
3. **Plan.** For anything non-trivial, post the implementation plan as a comment on the issue *before* writing code: files to touch, migrations needed, open questions. Wait for a 👍 or answer if questions were raised.
4. **Implement.** Small commits, Conventional Commits format, referencing the issue (`feat(auth): add login form #12`).
5. **Verify.** `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` all pass. If a migration is included: `supabase db reset` succeeds locally.
6. **PR.** Open a PR to `main` using the template. Include `Closes #<issue>`. Summarize what changed, why, how to test manually, and any deviations from the Figma design or the plan.
7. **Stop.** Do not merge. Do not start dependent work on top of an unreviewed PR unless asked. The human reviews, requests changes or merges.
8. **Review feedback.** Address comments with new commits on the same branch; reply to each comment with what was done.
## Scope discipline
 
- One issue = one branch = one PR. No drive-by refactors; if you spot unrelated problems, open a new issue instead.
- If the task turns out bigger than expected, say so on the issue and propose splitting it.
## Branch protection (repo settings — set once by the human)
 
- `main`: require PR before merge, require 1 approval, require status checks (format/analyze/test) to pass, no force pushes.
## When blocked
 
If credentials are missing, the design is ambiguous, or two docs conflict: stop and ask on the issue. A wrong guess costs more than a question.