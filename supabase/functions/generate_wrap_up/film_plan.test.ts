import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { bannedPhraseIn, describeFilmPlanProblems } from "./film_plan.ts";
import {
  DIRECTOR_PHOTO_IDS,
  keepsakePlan,
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

Deno.test("scene durations follow the recipe and the total is 45–100s", () => {
  const slow = ravePlan();
  slow.chapters[0].scenes[0].duration_s = 5;
  hasProblem(problemsOf(slow), "rave scenes last 1.5–4s");

  const short = keepsakePlan();
  short.chapters[1].scenes.splice(3, 3);
  hasProblem(problemsOf(short), "scenes total 35s");
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
