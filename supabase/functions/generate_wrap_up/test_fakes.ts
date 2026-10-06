// Minimal fakes standing in for supabase-js's chainable query builder and
// auth client, just enough surface for gather.ts/handler.ts's exact call
// shapes. Not a real query engine — filters (.eq/.gte/.order/.limit) are
// accepted but not applied; each table's fixture rows are returned as-is.
// Writes (insert/update/upsert) are recorded on the returned `writes` array,
// along with the .eq/.is filters applied to them, so tests can assert what
// was saved and under which guard.

// deno-lint-ignore no-explicit-any
type Row = Record<string, any>;

export interface RecordedWrite {
  table: string;
  op: "insert" | "update" | "upsert";
  values: Row;
  filters: [string, string, unknown][];
}

export function fakeSupabaseClient(
  tables: Record<string, Row[]>,
  errors: Record<string, { message: string }> = {},
) {
  const writes: RecordedWrite[] = [];
  return {
    writes,
    from(table: string) {
      const rows = tables[table] ?? [];
      const error = errors[table] ?? null;
      let write: RecordedWrite | null = null;
      // deno-lint-ignore no-explicit-any
      const builder: any = {
        select() {
          return builder;
        },
        eq(column: string, value: unknown) {
          write?.filters.push(["eq", column, value]);
          return builder;
        },
        is(column: string, value: unknown) {
          write?.filters.push(["is", column, value]);
          return builder;
        },
        insert(values: Row) {
          write = { table, op: "insert", values, filters: [] };
          writes.push(write);
          return builder;
        },
        update(values: Row) {
          write = { table, op: "update", values, filters: [] };
          writes.push(write);
          return builder;
        },
        gte() {
          return builder;
        },
        not() {
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
        upsert(values: Row) {
          writes.push({ table, op: "upsert", values, filters: [] });
          return Promise.resolve({ data: null, error: error ?? null });
        },
        then(resolve: (v: { data: Row[] | null; error: unknown }) => void) {
          if (error) return resolve({ data: null, error });
          resolve({ data: write ? null : rows, error: null });
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
