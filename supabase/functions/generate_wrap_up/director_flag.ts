// Server-side switch for the director (#328): WRAP_UP_DIRECTOR_USER_IDS is a
// comma-separated list of user ids it runs for, `*` for everyone; unset or
// empty = off. Lets v2 planning run for Leo only first. Set it in
// supabase/functions/.env locally and as a function secret when deployed.

export const DIRECTOR_FLAG_ENV = "WRAP_UP_DIRECTOR_USER_IDS";

export function parseDirectorFlag(
  value: string | undefined | null,
): (userId: string) => boolean {
  const ids = new Set(
    (value ?? "").split(",").map((s) => s.trim()).filter(Boolean),
  );
  if (ids.has("*")) return () => true;
  return (userId) => ids.has(userId);
}
