// Minimal fakes standing in for supabase-js — just enough surface for
// handler.ts's getUser, `.upsert(...)` and `.select().eq().maybeSingle()`.
// The fake table is a Map keyed by user_id so a test can assert on both
// what was written and what the handler read back.

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

export function fakeServiceClient(
  options: {
    rows?: Row[];
    upsertError?: { message: string };
    readError?: { message: string };
  } = {},
) {
  const table = new Map<string, Row>(
    (options.rows ?? []).map((r) => [r.user_id, r]),
  );
  const upserts: { table: string; row: Row; onConflict?: string }[] = [];
  return {
    table,
    upserts,
    from(name: string) {
      return {
        upsert(row: Row, opts?: { onConflict?: string }) {
          upserts.push({ table: name, row, onConflict: opts?.onConflict });
          if (options.upsertError) {
            return Promise.resolve({ data: null, error: options.upsertError });
          }
          table.set(row.user_id, { ...table.get(row.user_id), ...row });
          return Promise.resolve({ data: row, error: null });
        },
        select(_columns: string) {
          return {
            eq(_column: string, value: string) {
              return {
                maybeSingle() {
                  if (options.readError) {
                    return Promise.resolve({
                      data: null,
                      error: options.readError,
                    });
                  }
                  const row = table.get(value);
                  if (!row) return Promise.resolve({ data: null, error: null });
                  const { tier, revenuecat_customer_id, expires_at } = row;
                  return Promise.resolve({
                    data: { tier, revenuecat_customer_id, expires_at },
                    error: null,
                  });
                },
              };
            },
          };
        },
      };
    },
  };
}

export function fakeAuthClient(userId: string | null) {
  return () => ({
    auth: {
      getUser: () =>
        Promise.resolve(
          userId
            ? { data: { user: { id: userId } }, error: null }
            : { data: { user: null }, error: { message: "invalid jwt" } },
        ),
    },
  });
}
