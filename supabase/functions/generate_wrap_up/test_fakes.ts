// Minimal fakes standing in for supabase-js's chainable query builder and
// auth client, just enough surface for gather.ts/handler.ts's exact call
// shapes. Not a real query engine — filters (.eq/.gte/.order/.limit) are
// accepted but not applied; each table's fixture rows are returned as-is.

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

export function fakeSupabaseClient(
  tables: Record<string, Row[]>,
  errors: Record<string, { message: string }> = {},
) {
  return {
    from(table: string) {
      const rows = tables[table] ?? [];
      const error = errors[table] ?? null;
      // deno-lint-ignore no-explicit-any
      const builder: any = {
        select() {
          return builder;
        },
        eq() {
          return builder;
        },
        gte() {
          return builder;
        },
        order() {
          return builder;
        },
        limit() {
          return builder;
        },
        single() {
          if (error) return Promise.resolve({ data: null, error });
          const row = rows[0];
          return Promise.resolve({
            data: row ?? null,
            error: row ? null : { message: `${table}: not found` },
          });
        },
        maybeSingle() {
          if (error) return Promise.resolve({ data: null, error });
          return Promise.resolve({ data: rows[0] ?? null, error: null });
        },
        upsert(_values: unknown) {
          return Promise.resolve({ data: null, error: error ?? null });
        },
        then(resolve: (v: { data: Row[] | null; error: unknown }) => void) {
          if (error) return resolve({ data: null, error });
          resolve({ data: rows, error: null });
        },
      };
      return builder;
    },
  };
}

export function fakeAuthClient(user: { id: string } | null) {
  return () => ({
    auth: {
      getUser: () =>
        Promise.resolve(
          user
            ? { data: { user }, error: null }
            : { data: { user: null }, error: { message: "invalid session" } },
        ),
    },
  });
}
