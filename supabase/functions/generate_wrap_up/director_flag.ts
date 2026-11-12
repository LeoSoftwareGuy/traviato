// Off switch for the director (#328, #345): WRAP_UP_DIRECTOR_USER_IDS.
// - unset, empty or `*`: on for everyone (the default — Sky Story is planned
//   by the director);
// - `off`: off for everyone, e.g. if Anthropic costs spike. Films then use
//   the code-built Sky Story pages;
// - a comma-separated list of user ids: on only for those accounts
//   (debugging).
// Set it in supabase/functions/.env locally and as a function secret when
// deployed.

export const DIRECTOR_FLAG_ENV = "WRAP_UP_DIRECTOR_USER_IDS";

export function parseDirectorFlag(
  value: string | undefined | null,
): (userId: string) => boolean {
  const ids = new Set(
    (value ?? "").split(",").map((s) => s.trim()).filter(Boolean),
  );
  if (ids.size === 0 || ids.has("*")) return () => true;
  if (ids.has("off")) return () => false;
  return (userId) => ids.has(userId);
}
