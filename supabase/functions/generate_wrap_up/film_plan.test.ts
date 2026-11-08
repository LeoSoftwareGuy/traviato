import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  bannedPhraseIn,
  describeFilmPlanProblems,
  MIN_TOTAL_SECONDS,
  repairFilmPlan,
} from "./film_plan.ts";
import {
  DIRECTOR_PHOTO_IDS,
  keepsakePlan,
  keepsakePlanWithFixableFaults,
  planContext,
  ravePlan,
} from "./director_fixtures.ts";

function problemsOf(plan: unknown, context = planContext()) {
  return describeFilmPlanProblems(plan, context);
}

function hasProblem(problems: string[], fragment: string) {
  assert(
    problems.some((p) => p.includes(fragment)),
    `expected a problem containing "${fragment}", got ${
      JSON.stringify(problems)
    }`,
  );
}

Deno.test("a valid keepsake plan has no problems", () => {
  assertEquals(problemsOf(keepsakePlan()), []);
});

Deno.test("a valid rave plan has no problems", () => {
  assertEquals(problemsOf(ravePlan()), []);
});

Deno.test("a scene type outside the recipe is rejected", () => {
  const plan = keepsakePlan();
  plan.chapters[0].scenes[1].type = "burst";
  hasProblem(problemsOf(plan), '"burst" is not a keepsake scene');
});

Deno.test("unknown, excluded and repeated photo ids are rejected", () => {
  const unknown = keepsakePlan();
  unknown.chapters[0].scenes[0].photo_ids = ["nope"];
  hasProblem(problemsOf(unknown), '"nope" is not a photo id');

  const excluded = problemsOf(
    keepsakePlan(),
    planContext({ excludedIds: new Set(["p04"]) }),
  );
  hasProblem(excluded, '"p04" was left out');

  const twice = keepsakePlan();
  twice.chapters[1].scenes[3].photo_ids = ["p10"];
  hasProblem(problemsOf(twice), '"p10" is used twice');
});

Deno.test("photos out of chronological order are rejected", () => {
  const plan = keepsakePlan();
  plan.chapters[0].scenes[0].photo_ids = ["p04"];
  plan.chapters[0].scenes[2].photo_ids = ["p00"];
  hasProblem(problemsOf(plan), "out of chronological order");
});

Deno.test("photo counts per scene type are enforced", () => {
  const collage = keepsakePlan();
  collage.chapters[0].scenes[1].photo_ids = ["p01", "p02"];
  hasProblem(problemsOf(collage), "a collage_3 takes 3");

  const burst = ravePlan();
  burst.chapters[0].scenes[0].photo_ids = ["p00", "p01"];
  hasProblem(problemsOf(burst), "a burst takes 3–6");

  const split = ravePlan();
  split.chapters[0].scenes[1].photo_ids = ["p03"];
  hasProblem(problemsOf(split), "a split takes 2–3");
});

Deno.test("scene durations follow the recipe and the total is 30–100s", () => {
  const slow = ravePlan();
  slow.chapters[0].scenes[0].duration_s = 5;
  hasProblem(problemsOf(slow), "rave scenes last 1.5–4s");

  const short = keepsakePlan();
  short.chapters[1].scenes.splice(1, 5);
  hasProblem(problemsOf(short), "scenes total 25s");
});

Deno.test("a rave needs at least two bursts", () => {
  const plan = ravePlan();
  plan.chapters[1].scenes[0] = {
    ...plan.chapters[1].scenes[0],
    type: "split",
    photo_ids: ["p05", "p06"],
  };
  plan.chapters[1].scenes[1].photo_ids = ["p07"];
  plan.chapters[1].scenes.splice(2, 1);
  hasProblem(problemsOf(plan), "1 bursts, a rave film needs at least 2");
});

Deno.test("line lengths, banned phrases and the language are checked", () => {
  const long = keepsakePlan();
  long.chapters[0].bridge_line = "x".repeat(71);
  hasProblem(problemsOf(long), "71 characters, at most 70");

  const closing = keepsakePlan();
  closing.closing_line = "y".repeat(91);
  hasProblem(problemsOf(closing), "closing_line: 91 characters");

  const banned = keepsakePlan();
  banned.footnote.line = "An Epic three days.";
  hasProblem(problemsOf(banned), 'banned phrase "epic"');

  hasProblem(
    problemsOf(keepsakePlan(), planContext({ language: "ru" })),
    'language: expected "ru"',
  );
});

Deno.test("2–3 chapters, each with a bridge line", () => {
  const plan = keepsakePlan();
  plan.chapters = [plan.chapters[0]];
  hasProblem(problemsOf(plan), "chapters: 1, expected 2–3");
});

Deno.test("every Always photo must be in the plan", () => {
  const plan = keepsakePlan();
  plan.chapters[1].scenes[3] = { ...plan.chapters[1].scenes[4] };
  const problems = problemsOf(
    plan,
    planContext({ mustIncludeIds: new Set(["p11"]) }),
  );
  hasProblem(problems, '"p11" is marked Always');
});

Deno.test("caption notes must be real and only text cards carry text", () => {
  const note = keepsakePlan();
  note.chapters[0].scenes[0].caption_note_id = "ghost";
  hasProblem(problemsOf(note), "not a note id");

  const text = keepsakePlan();
  text.chapters[0].scenes[0].text = "Hello";
  hasProblem(problemsOf(text), "only a text_card has text");
});

Deno.test("bannedPhraseIn matches whole words only", () => {
  assertEquals(bannedPhraseIn("An EPIC night"), "epic");
  assertEquals(bannedPhraseIn("Right at the epicentre"), null);
  assertEquals(bannedPhraseIn("Pure wanderlust."), "wanderlust");
});

Deno.test("anything that isn't a plan object is rejected", () => {
  assertEquals(problemsOf(null), ["plan: expected an object"]);
  assert(problemsOf({}).length > 0);
  assertEquals(DIRECTOR_PHOTO_IDS.length, 12);
});

Deno.test("repairFilmPlan fixes plan_version and splits a 2-photo collage into card_flips", () => {
  const broken = keepsakePlanWithFixableFaults();
  assertEquals(describeFilmPlanProblems(broken, planContext()), [
    "plan_version: expected 2",
    "chapters[0].scenes[1].photo_ids: 2 photos, a collage_3 takes 3",
  ]);

  const repaired = repairFilmPlan(broken) as ReturnType<typeof keepsakePlan>;

  assertEquals(describeFilmPlanProblems(repaired, planContext()), []);
  assertEquals(repaired.plan_version, 2);
  const ids = DIRECTOR_PHOTO_IDS;
  assertEquals(
    repaired.chapters[0].scenes.slice(1, 3).map((s) => ({
      type: s.type,
      photo_ids: s.photo_ids,
      caption_note_id: s.caption_note_id,
      duration_s: s.duration_s,
    })),
    [
      {
        type: "card_flip",
        photo_ids: [ids[1]],
        caption_note_id: "n2",
        duration_s: 5,
      },
      {
        type: "card_flip",
        photo_ids: [ids[2]],
        caption_note_id: null,
        duration_s: 5,
      },
    ],
  );
  // The input is left as it was.
  assertEquals("plan_version" in broken, false);
});

Deno.test("repairFilmPlan leaves full collages and non-plans alone", () => {
  const plan = keepsakePlan();
  assertEquals(repairFilmPlan(plan), plan);
  assertEquals(repairFilmPlan(null), null);
  assertEquals(repairFilmPlan("plan"), "plan");
  const noChapters = repairFilmPlan({ recipe: "keepsake" });
  assertEquals(noChapters, { recipe: "keepsake", plan_version: 2 });
});

Deno.test("repairFilmPlan turns a 2-photo burst into a split", () => {
  const plan = ravePlan();
  const burst = plan.chapters.flatMap((c) => c.scenes).find((s) =>
    s.type === "burst"
  )!;
  burst.photo_ids = burst.photo_ids.slice(0, 2);
  assert(
    describeFilmPlanProblems(plan, planContext()).some((p) =>
      p.includes("a burst takes 3–6")
    ),
  );

  const repaired = repairFilmPlan(plan) as ReturnType<typeof ravePlan>;

  const split = repaired.chapters.flatMap((c) => c.scenes).find((s) =>
    s.photo_ids.join() === burst.photo_ids.join()
  )!;
  assertEquals(split.type, "split");
  assert(
    !describeFilmPlanProblems(repaired, planContext()).some((p) =>
      p.includes("photo_ids:")
    ),
  );
});

Deno.test("repairFilmPlan stretches a short film to the minimum, within the recipe max", () => {
  const plan = ravePlan();
  const scenes = plan.chapters.flatMap((c) => c.scenes);
  scenes.forEach((s, i) => (s.duration_s = i === 0 ? 4 : 1.6));
  const before = scenes.reduce((sum, s) => sum + s.duration_s, 0);
  assert(before < MIN_TOTAL_SECONDS);

  const repaired = repairFilmPlan(plan) as ReturnType<typeof ravePlan>;

  const after = repaired.chapters.flatMap((c) => c.scenes);
  const total = after.reduce((sum, s) => sum + s.duration_s, 0);
  assert(total >= MIN_TOTAL_SECONDS, `total ${total}s`);
  assert(after.every((s) => s.duration_s <= 4), "a scene went past 4s");
  assertEquals(after[0].duration_s, 4);
  assertEquals(
    describeFilmPlanProblems(repaired, planContext()).filter((p) =>
      p.startsWith("duration")
    ),
    [],
  );
});

Deno.test("repairFilmPlan leaves a film the caps can't save to validation", () => {
  const plan = ravePlan();
  plan.chapters[0].scenes.splice(1);
  plan.chapters[1].scenes.splice(1);
  if (plan.chapters[2]) plan.chapters[2].scenes.splice(1);
  const repaired = repairFilmPlan(plan) as ReturnType<typeof ravePlan>;
  assert(
    repaired.chapters.flatMap((c) => c.scenes).every((s) => s.duration_s <= 4),
  );
  assert(
    describeFilmPlanProblems(repaired, planContext()).some((p) =>
      p.startsWith("duration")
    ),
  );
});
