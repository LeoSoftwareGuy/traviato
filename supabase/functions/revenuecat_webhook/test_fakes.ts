// Minimal fake standing in for supabase-js's chainable query builder — just
// enough surface for handler.ts's single `.from(...).upsert(...)` call.
// Records every upsert so tests can assert on what was written.

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

export function fakeSupabaseClient(
  options: { upsertError?: { message: string } } = {},
) {
  const upserts: { table: string; row: Row; onConflict?: string }[] = [];
  return {
    upserts,
    from(table: string) {
      return {
        upsert(row: Row, opts?: { onConflict?: string }) {
          upserts.push({ table, row, onConflict: opts?.onConflict });
          if (options.upsertError) {
            return Promise.resolve({ data: null, error: options.upsertError });
          }
          return Promise.resolve({ data: row, error: null });
        },
      };
    },
  };
}
