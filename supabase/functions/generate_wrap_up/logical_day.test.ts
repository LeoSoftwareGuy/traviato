import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { logicalDayOf, logicalDays } from "./logical_day.ts";

// The same cases as test/core/utils/logical_day_test.dart (#398 R1).

const THU = "2026-10-23";
const FRI = "2026-10-24";

// Local wall-clock times 'YYYY-MM-DDTHH:MM' → their logical days.
function days(times: string[]): string[] {
  const out: string[] = [];
  let previous: { localMs: number; day: string } | null = null;
  for (const t of times) {
    const localMs = Date.parse(`${t}:00Z`);
    const day = logicalDayOf(localMs, previous);
    out.push(day);
    previous = { localMs, day };
  }
  return out;
}

Deno.test("a club night stays on the evening it started", () => {
  assertEquals(
    days([
      "2026-10-23T22:46",
      "2026-10-24T01:04",
      "2026-10-24T04:34",
      "2026-10-24T06:30",
    ]),
    [THU, THU, THU, THU],
  );
});

Deno.test("03:00 after a 6 h gap starts a new day", () => {
  assertEquals(days(["2026-10-23T21:00", "2026-10-24T03:00"]), [THU, FRI]);
});

Deno.test("exactly 4 h is a gap", () => {
  assertEquals(days(["2026-10-23T23:00", "2026-10-24T03:00"]), [THU, FRI]);
  assertEquals(days(["2026-10-23T23:00", "2026-10-24T02:59"]), [THU, THU]);
});

Deno.test("from 08:00 an item always starts its own day", () => {
  assertEquals(days(["2026-10-24T06:30", "2026-10-24T08:00"]), [FRI, FRI]);
  assertEquals(
    days(["2026-10-23T22:00", "2026-10-24T07:59", "2026-10-24T08:01"]),
    [THU, FRI, FRI],
  );
});

Deno.test("an early item after a new day began stays on that new day", () => {
  assertEquals(
    days(["2026-10-23T18:00", "2026-10-24T01:00", "2026-10-24T03:00"]),
    [THU, FRI, FRI],
  );
});

Deno.test("the first item is on its calendar date", () => {
  assertEquals(logicalDayOf(Date.parse("2026-10-24T02:00:00Z")), FRI);
});

Deno.test("a previous item after this one is ignored", () => {
  assertEquals(
    logicalDayOf(Date.parse("2026-10-24T02:00:00Z"), {
      localMs: Date.parse("2026-10-24T03:00:00Z"),
      day: THU,
    }),
    FRI,
  );
});

Deno.test("a previous day that is not this night never applies", () => {
  assertEquals(
    logicalDayOf(Date.parse("2026-10-24T02:00:00Z"), {
      localMs: Date.parse("2026-10-24T01:00:00Z"),
      day: "2026-10-20",
    }),
    FRI,
  );
});

Deno.test("logicalDays: the phone's clock, mixed items, untimed fallbacks", () => {
  const result = logicalDays(
    [
      // 20:30 and 23:10 UTC = 22:30 and 01:10 in Tallinn (UTC+2).
      { id: "b", at: "2026-10-23T23:10:00Z", fallbackDay: FRI },
      { id: "a", at: "2026-10-23T20:30:00Z", fallbackDay: THU },
      { id: "legacy", at: null, fallbackDay: "2026-10-22" },
    ],
    120,
  );
  assertEquals(result.get("a"), THU);
  assertEquals(result.get("b"), THU);
  assertEquals(result.get("legacy"), "2026-10-22");
  // In UTC the same 23:10 is still Thursday's evening.
  assertEquals(
    logicalDays([{ id: "b", at: "2026-10-23T23:10:00Z", fallbackDay: null }])
      .get("b"),
    THU,
  );
});
