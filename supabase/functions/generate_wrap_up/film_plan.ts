// The director's film plan (#328, docs/design/wrap-up-film-v2-design.md):
// its shape (plan_version 2), the tool schema the model fills, the recipes,
// and the validation every plan passes before it is stored.
//
// The plan describes only the middle of the film. The bookends — opening
// (dust/invitation), stats footnote numbers, badge unlock and keepsake card
// — stay fixed and are filled by code (assemble.ts).
//
// Renderer-agnostic on purpose: the Flutter player reads it in a follow-up
// issue, and a server renderer could read the same plan later.

import type { WrapUpLanguage } from "./language.ts";

export const PLAN_VERSION = 2;

export const RECIPES = ["rave", "keepsake"] as const;
export type Recipe = typeof RECIPES[number];

export const OCCASIONS = [
  "wedding",
  "party",
  "camping",
  "city",
  "family",
  "birthday",
  "other",
] as const;
export type Occasion = typeof OCCASIONS[number];

export const SCENE_TYPES = [
  "card_flip",
  "collage_3",
  "collage_4",
  "collage_6",
  "flurry",
  "burst",
  "split",
  "text_card",
] as const;
export type SceneType = typeof SCENE_TYPES[number];

export type Energy = "calm" | "medium" | "high";

export interface PlanScene {
  type: SceneType;
  photo_ids: string[];
  caption_note_id: string | null;
  // The line a text_card shows; null for every other scene type.
  text: string | null;
  duration_s: number;
  emphasis: "normal" | "hero";
}

export interface PlanChapter {
  bridge_line: string;
  scenes: PlanScene[];
}

export interface FilmPlan {
  plan_version: 2;
  occasion: Occasion;
  recipe: Recipe;
  music: { energy: Energy };
  language: WrapUpLanguage;
  chapters: PlanChapter[];
  footnote: { line: string };
  closing_line: string;
  // 2–3 sentences on why this recipe and shape — the Plan inspector only.
  reasoning: string;
}

export interface RecipeRules {
  scenes: readonly SceneType[];
  minDuration: number;
  maxDuration: number;
  minBursts: number;
  fits: string;
  tone: string;
}

export const RECIPE_RULES: Record<Recipe, RecipeRules> = {
  rave: {
    scenes: ["burst", "split", "collage_6", "card_flip", "text_card"],
    minDuration: 1.5,
    maxDuration: 4,
    minBursts: 2,
    fits:
      "nights out, parties, festivals, concerts, club/venue photos, high energy, crowds",
    tone: "playful, a bit cheeky",
  },
  keepsake: {
    scenes: [
      "card_flip",
      "collage_3",
      "collage_4",
      "collage_6",
      "flurry",
      "text_card",
    ],
    minDuration: 4,
    maxDuration: 6,
    minBursts: 0,
    fits: "everything else — and the fallback when unsure",
    tone: "quiet, wry",
  },
};

// Exact photo count per scene type, as [min, max].
export const SCENE_PHOTO_COUNT: Record<SceneType, [number, number]> = {
  card_flip: [1, 1],
  collage_3: [3, 3],
  collage_4: [4, 4],
  collage_6: [6, 6],
  flurry: [6, 15],
  burst: [3, 6],
  split: [2, 3],
  text_card: [0, 0],
};

// Lowered from 45s (#334): a shorter plan that fits the memory beats the
// template fallback. To be tuned per photo count after real films.
export const MIN_TOTAL_SECONDS = 30;
export const MAX_TOTAL_SECONDS = 100;
export const MIN_CHAPTERS = 2;
export const MAX_CHAPTERS = 3;
export const MAX_BRIDGE_CHARS = 70;
export const MAX_CLOSING_CHARS = 90;
export const MAX_FOOTNOTE_CHARS = 90;
export const MAX_TEXT_CARD_CHARS = 90;

export const BANNED_PHRASES = [
  "unforgettable",
  "adventure awaits",
  "wanderlust",
  "memories to last a lifetime",
  "epic",
];

export const filmPlanToolSchema = {
  name: "emit_film_plan",
  description:
    "Emit the plan for this memory's wrap-up film as structured JSON (plan_version 2).",
  input_schema: {
    type: "object",
    properties: {
      plan_version: { type: "integer", enum: [PLAN_VERSION] },
      occasion: { type: "string", enum: [...OCCASIONS] },
      recipe: { type: "string", enum: [...RECIPES] },
      music: {
        type: "object",
        properties: {
          energy: { type: "string", enum: ["calm", "medium", "high"] },
        },
        required: ["energy"],
      },
      language: { type: "string", enum: ["en", "ru"] },
      chapters: {
        type: "array",
        minItems: MIN_CHAPTERS,
        maxItems: MAX_CHAPTERS,
        items: {
          type: "object",
          properties: {
            bridge_line: {
              type: "string",
              description:
                `Opens the chapter. At most ${MAX_BRIDGE_CHARS} characters.`,
            },
            scenes: {
              type: "array",
              minItems: 1,
              items: {
                type: "object",
                properties: {
                  type: { type: "string", enum: [...SCENE_TYPES] },
                  photo_ids: { type: "array", items: { type: "string" } },
                  caption_note_id: {
                    type: ["string", "null"],
                    description: "A note id from the input, or null.",
                  },
                  text: {
                    type: ["string", "null"],
                    description:
                      `text_card only: the line it shows (at most ${MAX_TEXT_CARD_CHARS} characters). Null for every other type.`,
                  },
                  duration_s: { type: "number" },
                  emphasis: { type: "string", enum: ["normal", "hero"] },
                },
                required: [
                  "type",
                  "photo_ids",
                  "caption_note_id",
                  "text",
                  "duration_s",
                  "emphasis",
                ],
              },
            },
          },
          required: ["bridge_line", "scenes"],
        },
      },
      footnote: {
        type: "object",
        properties: {
          line: {
            type: "string",
            description:
              `One line over the stats card. At most ${MAX_FOOTNOTE_CHARS} characters.`,
          },
        },
        required: ["line"],
      },
      closing_line: {
        type: "string",
        description: `At most ${MAX_CLOSING_CHARS} characters.`,
      },
      reasoning: {
        type: "string",
        description:
          "2–3 sentences: why this occasion, recipe and shape. Debug only, never shown to the user.",
      },
    },
    required: [
      "plan_version",
      "occasion",
      "recipe",
      "music",
      "language",
      "chapters",
      "footnote",
      "closing_line",
      "reasoning",
    ],
  },
} as const;

// What a plan is checked against: the memory as it is now.
export interface PlanContext {
  language: WrapUpLanguage;
  // Every photo the plan may use, in chronological order (day, then time).
  photoOrder: string[];
  // "Leave out" picks (#294) — never in the film.
  excludedIds: ReadonlySet<string>;
  // "Always" picks (#294) the plan could use — each must appear.
  mustIncludeIds: ReadonlySet<string>;
  noteIds: ReadonlySet<string>;
}

function isString(v: unknown): v is string {
  return typeof v === "string";
}

function isOneOf<T extends string>(
  list: readonly T[],
  v: unknown,
): v is T {
  return isString(v) && (list as readonly string[]).includes(v);
}

// The banned phrase found in [line], or null.
export function bannedPhraseIn(line: string): string | null {
  const lower = line.toLowerCase();
  for (const phrase of BANNED_PHRASES) {
    // Whole words only, so "epicentre" isn't "epic".
    const pattern = new RegExp(`(^|[^\\p{L}])${phrase}($|[^\\p{L}])`, "u");
    if (pattern.test(lower)) return phrase;
  }
  return null;
}

function checkLine(
  problems: string[],
  where: string,
  line: unknown,
  maxChars: number,
): void {
  if (!isString(line) || line.trim().length === 0) {
    problems.push(`${where}: expected a non-empty string`);
    return;
  }
  if ([...line].length > maxChars) {
    problems.push(
      `${where}: ${[...line].length} characters, at most ${maxChars}`,
    );
  }
  const banned = bannedPhraseIn(line);
  if (banned) problems.push(`${where}: banned phrase "${banned}"`);
}

// Every way [data] breaks the plan rules, one readable line each — empty
// when it's valid. These lines are fed back to the model on the retry and
// shown in the Plan inspector on a fallback.
export function describeFilmPlanProblems(
  data: unknown,
  context: PlanContext,
): string[] {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return ["plan: expected an object"];
  }
  const d = data as Record<string, unknown>;
  const problems: string[] = [];

  if (d.plan_version !== PLAN_VERSION) {
    problems.push(`plan_version: expected ${PLAN_VERSION}`);
  }
  if (!isOneOf(OCCASIONS, d.occasion)) {
    problems.push(`occasion: expected one of ${OCCASIONS.join(", ")}`);
  }
  const recipe = isOneOf(RECIPES, d.recipe) ? d.recipe : null;
  if (!recipe) problems.push(`recipe: expected one of ${RECIPES.join(", ")}`);
  const music = d.music as Record<string, unknown> | undefined;
  if (
    typeof music !== "object" || music === null ||
    !isOneOf(["calm", "medium", "high"], music.energy)
  ) {
    problems.push("music.energy: expected calm, medium or high");
  }
  if (d.language !== context.language) {
    problems.push(`language: expected "${context.language}"`);
  }
  if (!isString(d.reasoning)) {
    problems.push("reasoning: expected a string");
  }

  const footnote = d.footnote as Record<string, unknown> | undefined;
  checkLine(
    problems,
    "footnote.line",
    typeof footnote === "object" && footnote !== null
      ? footnote.line
      : undefined,
    MAX_FOOTNOTE_CHARS,
  );
  checkLine(problems, "closing_line", d.closing_line, MAX_CLOSING_CHARS);

  if (!Array.isArray(d.chapters)) {
    problems.push("chapters: expected an array");
    return problems;
  }
  if (
    d.chapters.length < MIN_CHAPTERS || d.chapters.length > MAX_CHAPTERS
  ) {
    problems.push(
      `chapters: ${d.chapters.length}, expected ${MIN_CHAPTERS}–${MAX_CHAPTERS}`,
    );
  }

  const rules = recipe ? RECIPE_RULES[recipe] : null;
  const order = new Map(context.photoOrder.map((id, i) => [id, i]));
  const used = new Set<string>();
  let lastIndex = -1;
  let chronologyBroken = false;
  let totalSeconds = 0;
  let bursts = 0;

  d.chapters.forEach((rawChapter, c) => {
    const chapterWhere = `chapters[${c}]`;
    if (typeof rawChapter !== "object" || rawChapter === null) {
      problems.push(`${chapterWhere}: expected an object`);
      return;
    }
    const chapter = rawChapter as Record<string, unknown>;
    checkLine(
      problems,
      `${chapterWhere}.bridge_line`,
      chapter.bridge_line,
      MAX_BRIDGE_CHARS,
    );
    if (!Array.isArray(chapter.scenes) || chapter.scenes.length === 0) {
      problems.push(`${chapterWhere}.scenes: expected at least one scene`);
      return;
    }

    chapter.scenes.forEach((rawScene, s) => {
      const where = `${chapterWhere}.scenes[${s}]`;
      if (typeof rawScene !== "object" || rawScene === null) {
        problems.push(`${where}: expected an object`);
        return;
      }
      const scene = rawScene as Record<string, unknown>;

      const type = isOneOf(SCENE_TYPES, scene.type) ? scene.type : null;
      if (!type) {
        problems.push(`${where}.type: unknown scene type`);
      } else if (rules && !rules.scenes.includes(type)) {
        problems.push(
          `${where}.type: "${type}" is not a ${recipe} scene (${
            rules.scenes.join(", ")
          })`,
        );
      }
      if (type === "burst") bursts++;

      if (typeof scene.duration_s !== "number" || !isFinite(scene.duration_s)) {
        problems.push(`${where}.duration_s: expected a number`);
      } else {
        totalSeconds += scene.duration_s;
        if (
          rules &&
          (scene.duration_s < rules.minDuration ||
            scene.duration_s > rules.maxDuration)
        ) {
          problems.push(
            `${where}.duration_s: ${scene.duration_s}s, ${recipe} scenes last ${rules.minDuration}–${rules.maxDuration}s`,
          );
        }
      }

      if (!isOneOf(["normal", "hero"], scene.emphasis)) {
        problems.push(`${where}.emphasis: expected normal or hero`);
      }

      if (
        scene.caption_note_id !== null && scene.caption_note_id !== undefined &&
        !(isString(scene.caption_note_id) &&
          context.noteIds.has(scene.caption_note_id))
      ) {
        problems.push(`${where}.caption_note_id: not a note id from the input`);
      }

      if (type === "text_card") {
        checkLine(problems, `${where}.text`, scene.text, MAX_TEXT_CARD_CHARS);
      } else if (scene.text !== null && scene.text !== undefined) {
        problems.push(`${where}.text: only a text_card has text`);
      }

      if (!Array.isArray(scene.photo_ids) || !scene.photo_ids.every(isString)) {
        problems.push(`${where}.photo_ids: expected an array of ids`);
        return;
      }
      const ids = scene.photo_ids as string[];
      if (type) {
        const [min, max] = SCENE_PHOTO_COUNT[type];
        if (ids.length < min || ids.length > max) {
          problems.push(
            `${where}.photo_ids: ${ids.length} photos, a ${type} takes ${
              min === max ? min : `${min}–${max}`
            }`,
          );
        }
      }
      for (const id of ids) {
        if (context.excludedIds.has(id)) {
          problems.push(`${where}.photo_ids: "${id}" was left out by the user`);
          continue;
        }
        const index = order.get(id);
        if (index === undefined) {
          problems.push(
            `${where}.photo_ids: "${id}" is not a photo id from the input`,
          );
          continue;
        }
        if (used.has(id)) {
          problems.push(`${where}.photo_ids: "${id}" is used twice`);
          continue;
        }
        used.add(id);
        if (index < lastIndex && !chronologyBroken) {
          chronologyBroken = true;
          problems.push(
            `${where}.photo_ids: "${id}" is out of chronological order`,
          );
        }
        lastIndex = Math.max(lastIndex, index);
      }
    });
  });

  if (rules && bursts < rules.minBursts) {
    problems.push(
      `scenes: ${bursts} bursts, a ${recipe} film needs at least ${rules.minBursts}`,
    );
  }
  // Rounded so 44.999999 from float sums doesn't fail.
  const total = Math.round(totalSeconds * 10) / 10;
  if (total < MIN_TOTAL_SECONDS || total > MAX_TOTAL_SECONDS) {
    problems.push(
      `duration: scenes total ${total}s, expected ${MIN_TOTAL_SECONDS}–${MAX_TOTAL_SECONDS}s`,
    );
  }
  for (const id of context.mustIncludeIds) {
    if (!used.has(id)) {
      problems.push(`photo "${id}" is marked Always but is not in the plan`);
    }
  }
  return problems;
}

const COLLAGES: readonly string[] = ["collage_3", "collage_4", "collage_6"];

// Fixes, before validation, what the model gets wrong but code can put
// right without guessing (#332):
// - plan_version is always PLAN_VERSION;
// - a collage with only 1–2 photos becomes that many card_flip scenes (the
//   keepsake recipe has no 2-photo scene, so a leftover pair otherwise ends
//   up in a collage_3). Each keeps the collage's duration, emphasis and
//   order; the caption stays on the first;
// - a burst with only 2 photos becomes a split (#334);
// - a film shorter than MIN_TOTAL_SECONDS has every scene stretched by the
//   same factor, each capped at its recipe's maximum (#334). If the caps
//   stop it short, validation still reports the total.
// With [context] (#336):
// - a caption_note_id that isn't one of the memory's notes becomes null;
// - the plan's photos are put back in chronological order across the same
//   slots: scene types, photo counts and durations stay, a photo may move
//   to a neighbouring scene. Unknown or left-out ids keep their slot.
// Never throws; input that isn't plan-shaped is returned as is for
// describeFilmPlanProblems to report.
export function repairFilmPlan(
  data: unknown,
  context?: PlanContext,
): unknown {
  if (typeof data !== "object" || data === null || Array.isArray(data)) {
    return data;
  }
  const plan = structuredClone(data) as Record<string, unknown>;
  plan.plan_version = PLAN_VERSION;
  if (!Array.isArray(plan.chapters)) return plan;
  for (const chapter of plan.chapters) {
    if (typeof chapter !== "object" || chapter === null) continue;
    const c = chapter as Record<string, unknown>;
    if (!Array.isArray(c.scenes)) continue;
    c.scenes = c.scenes.flatMap((scene) => {
      if (typeof scene !== "object" || scene === null) return [scene];
      const sc = scene as Record<string, unknown>;
      const ids = sc.photo_ids;
      if (sc.type === "burst" && Array.isArray(ids) && ids.length === 2) {
        return [{ ...sc, type: "split" }];
      }
      if (
        !COLLAGES.includes(sc.type as string) || !Array.isArray(ids) ||
        ids.length === 0 || ids.length > 2
      ) {
        return [scene];
      }
      return ids.map((id, i) => ({
        ...sc,
        type: "card_flip",
        photo_ids: [id],
        caption_note_id: i === 0 ? sc.caption_note_id ?? null : null,
      }));
    });
  }
  if (context) {
    dropUnknownCaptions(plan, context);
    restoreChronology(plan, context);
  }
  stretchToMinimum(plan);
  return plan;
}

function planScenes(plan: Record<string, unknown>): Record<string, unknown>[] {
  if (!Array.isArray(plan.chapters)) return [];
  return plan.chapters.flatMap((c) =>
    typeof c === "object" && c !== null &&
      Array.isArray((c as Record<string, unknown>).scenes)
      ? (c as { scenes: unknown[] }).scenes
      : []
  ).filter((sc): sc is Record<string, unknown> =>
    typeof sc === "object" && sc !== null
  );
}

function dropUnknownCaptions(
  plan: Record<string, unknown>,
  context: PlanContext,
): void {
  for (const scene of planScenes(plan)) {
    const id = scene.caption_note_id;
    if (id !== null && id !== undefined && !context.noteIds.has(id as string)) {
      scene.caption_note_id = null;
    }
  }
}

function restoreChronology(
  plan: Record<string, unknown>,
  context: PlanContext,
): void {
  const order = new Map(context.photoOrder.map((id, i) => [id, i]));
  const isPlannable = (id: unknown): id is string =>
    typeof id === "string" && order.has(id) && !context.excludedIds.has(id);
  // Every slot holding a plannable photo, in plan order.
  const slots: { ids: unknown[]; index: number }[] = [];
  for (const scene of planScenes(plan)) {
    if (!Array.isArray(scene.photo_ids)) continue;
    scene.photo_ids.forEach((id, index) => {
      if (isPlannable(id)) {
        slots.push({ ids: scene.photo_ids as unknown[], index });
      }
    });
  }
  const sorted = slots
    .map((slot) => slot.ids[slot.index] as string)
    .sort((a, b) => order.get(a)! - order.get(b)!);
  slots.forEach((slot, i) => (slot.ids[slot.index] = sorted[i]));
}

function stretchToMinimum(plan: Record<string, unknown>): void {
  if (!isOneOf(RECIPES, plan.recipe)) return;
  const { maxDuration } = RECIPE_RULES[plan.recipe];
  const scenes = planScenes(plan);
  if (
    !scenes.every((sc) =>
      typeof sc.duration_s === "number" && isFinite(sc.duration_s) &&
      sc.duration_s > 0
    )
  ) {
    return;
  }
  const total = scenes.reduce((sum, sc) => sum + (sc.duration_s as number), 0);
  if (total === 0 || total >= MIN_TOTAL_SECONDS) return;
  const factor = MIN_TOTAL_SECONDS / total;
  for (const sc of scenes) {
    const d = sc.duration_s as number;
    // Rounded up to 0.1s so the stretched total doesn't land just short.
    sc.duration_s = Math.min(
      Math.max(d, maxDuration),
      Math.ceil(d * factor * 10) / 10,
    );
  }
}

export function totalSceneSeconds(plan: FilmPlan): number {
  return plan.chapters.reduce(
    (sum, chapter) =>
      sum + chapter.scenes.reduce((s, scene) => s + scene.duration_s, 0),
    0,
  );
}
