repo: LeoSoftwareGuy/traviato
branch: main
path: lib/core/theme, assets/images

## Last sync
date: 2026-08-24T11:22:34Z

### Updated in this project
- Pulled color, radius, spacing and typography tokens from `lib/core/theme` into the design.
- Built a 13-screen iOS redesign proposal on those tokens (Fraunces / Roboto, #0C0F27 ground, #F29520 primary).
- Imported `assets/images/` (guest, journal, trip) and used the real art for the landing hero and all memory covers.
- Added the three undesigned screens: wrap-up playback, expenses Compare, photo detail with tagging.

## Screen map
| Project screen | Repo source |
| --- | --- |
| All screens (tokens) | lib/core/theme/app_colors.dart, app_radius.dart, app_spacing.dart, app_typography.dart, app_theme.dart |
| Guest landing | lib/features/auth/, assets/images/guest/hero.png + guest cards |
| Memory covers, journal photos | assets/images/journal/, assets/images/guest/ |
| New memory banner | assets/images/trip/new_memory.png |
| Register / Log in | lib/features/auth/ |
| Home | lib/features/home/, lib/features/trip/ |
| New memory | lib/features/trip/ |
| Plan · quests | lib/features/quest/ |
| Checklist | lib/features/checklist/ |
| Journal | lib/features/journal/ |
| Expenses, Compare | lib/features/expense/ |
| Bonus tasks, You | supabase/migrations/*bonus_tasks*, *achievements*, *points_ledger* |
| Photo detail | lib/features/photo/ |
| Wrap-up playback | (new — no repo source yet) |
