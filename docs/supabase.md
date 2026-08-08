# Supabase Rules
 
## Golden rule
 
The database schema lives in `supabase/migrations/` as SQL files. That folder is the source of truth. **Never** create or alter tables directly on the remote database (via MCP, dashboard SQL, or otherwise). Schema changes go through a migration file in a PR, reviewed like any other code.
 
## What the Supabase MCP is for
 
Allowed:
- Inspecting current schema, listing tables, reading logs
- Running read-only queries against the **dev branch / local instance** to debug
- Generating TypeScript/Dart types from the schema
- Searching Supabase docs
Not allowed:
- Any write or DDL against production
- Creating/pausing/deleting projects
- Deploying edge functions directly (deploys go through CI after PR merge)
## Migrations
 
- Create with the Supabase CLI: `supabase migration new <description>`.
- One migration per logical change; include the corresponding `down`/revert notes in a comment when practical.
- Test locally with `supabase db reset` before opening the PR.
- Migration files are immutable once merged — fix mistakes with a new migration.
## Row Level Security (RLS)
 
- **RLS is enabled on every table. No exceptions.** A migration creating a table must enable RLS and define policies in the same file.
- Default posture: deny. Add explicit policies per operation (select/insert/update/delete).
- Policies are tested: for each table, note in the PR description who can read/write what, and why.
- The `anon` key is treated as public. Anything it can reach, an attacker can reach.
## Auth
 
- Use Supabase Auth (email/password + providers as designed in Figma). No custom auth.
- Client stores no tokens manually — `supabase_flutter` handles session persistence.
- User profile data lives in a `profiles` table keyed by `auth.users.id`, created via trigger migration.
## Edge functions
 
- Live in `supabase/functions/<name>/`, TypeScript.
- Used for logic that must not run on the client (secrets, third-party API calls, privileged writes).
- Each function validates its input and checks the caller's JWT.
## Secrets
 
- Never in code, never in migrations, never in PR descriptions or issue comments.
- Local: `.env` (gitignored). CI/production: platform secret stores.
 