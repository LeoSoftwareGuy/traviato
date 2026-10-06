// Request handling for generate_wrap_up (#93), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server. Auth guard + ownership check per docs/supabase.md.
//
// Draft vs frozen (#187): a published wrap-up is returned untouched. A draft
// is rebuilt from current data on every call, and Anthropic is only called
// when the AI's inputs (ai_input_hash.ts) changed — at most
// MAX_AI_GENERATIONS times per memory, after which the last AI text is
// reused.

import { gatherTripData, type TripData } from "./gather.ts";
import { assembleWrapUpContent } from "./assemble.ts";
import {
  type AiGeneratedFields,
  validateAiGeneratedFields,
} from "./ai_fields.ts";
import { computeAiInputHash } from "./ai_input_hash.ts";
import { logEvent, type LogLike, WrapUpGenerationError } from "./anthropic.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

// 1 initial generation + 3 regenerations, same for free and Pro (#187).
export const MAX_AI_GENERATIONS = 4;

export interface Deps {
  serviceClient: SupabaseClient;
  authClient: (authHeader: string) => SupabaseClient;
  generateAiFields: (tripData: TripData) => Promise<AiGeneratedFields>;
  // Defaults to `console.error` — see anthropic.ts's `[generate_wrap_up]`
  // log lines (#166).
  log?: LogLike;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function handleRequest(
  req: Request,
  deps: Deps,
): Promise<Response> {
  if (req.method !== "POST") {
    return json({ error: "method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "missing authorization" }, 401);
  }

  const body = await req.json().catch(() => ({}));
  const tripId = (body as Record<string, unknown>).trip_id;
  if (typeof tripId !== "string" || tripId.length === 0) {
    return json({ error: "trip_id is required" }, 400);
  }

  const { data: userData, error: userError } = await deps.authClient(authHeader)
    .auth.getUser();
  if (userError || !userData?.user) {
    return json({ error: "invalid session" }, 401);
  }

  const { data: trip, error: tripError } = await deps.serviceClient
    .from("trips")
    .select("id, user_id")
    .eq("id", tripId)
    .maybeSingle();
  if (tripError) {
    return json({ error: `trip lookup failed: ${tripError.message}` }, 500);
  }
  if (!trip) {
    return json({ error: "trip not found" }, 404);
  }
  if (trip.user_id !== userData.user.id) {
    return json({ error: "forbidden" }, 403);
  }

  const { data: existing, error: existingError } = await deps.serviceClient
    .from("wrap_ups")
    .select(
      "content, generated_at, published_at, ai_fields, ai_input_hash, ai_generation_count",
    )
    .eq("trip_id", tripId)
    .maybeSingle();
  if (existingError) {
    return json(
      { error: `wrap-up lookup failed: ${existingError.message}` },
      500,
    );
  }
  // Kept forever → frozen: never rebuilt, never regenerated (#187).
  if (existing?.published_at && existing.content) {
    return json({
      content: existing.content,
      generated_at: existing.generated_at,
    }, 200);
  }

  // Everything below is a draft (or a first generation): the film is always
  // rebuilt from current data, so photo edits never leave it stale.
  let tripData: TripData;
  try {
    tripData = await gatherTripData(deps.serviceClient, tripId);
  } catch (err) {
    return json({
      error: `failed to gather trip data: ${(err as Error).message}`,
    }, 500);
  }

  const inputHash = await computeAiInputHash(tripData);
  const storedFields = validateAiGeneratedFields(existing?.ai_fields)
    ? existing!.ai_fields as AiGeneratedFields
    : null;
  const generationCount: number = existing?.ai_generation_count ?? 0;
  const storedHash: string | null = existing?.ai_input_hash ?? null;

  let aiFields: AiGeneratedFields;
  let newCount = generationCount;
  // Whether [aiFields] were written from the current inputs — decides which
  // hash is saved. A failed regeneration (or the cap) keeps the old hash so
  // the row never claims text is fresher than it is.
  let fieldsMatchInputs = true;
  if (
    storedFields &&
    (storedHash === null || storedHash === inputHash ||
      generationCount >= MAX_AI_GENERATIONS)
  ) {
    // Unchanged inputs, a backfilled row adopting its hash, or the cap
    // reached — reuse the last AI-written text, no Anthropic call.
    aiFields = storedFields;
    fieldsMatchInputs = storedHash === null || storedHash === inputHash;
  } else if (storedFields) {
    // A regeneration. Counted whether or not it succeeds — every call costs
    // — and a failure falls back to the last text rather than breaking.
    newCount = generationCount + 1;
    try {
      aiFields = await deps.generateAiFields(tripData);
    } catch (err) {
      logGenerationFailure(deps, tripId, err, "regeneration_failed");
      aiFields = storedFields;
      fieldsMatchInputs = false;
    }
  } else {
    // First generation: only counted on success, so a failed first attempt
    // can't burn the cap before the user ever has a wrap-up.
    try {
      aiFields = await deps.generateAiFields(tripData);
    } catch (err) {
      // `error` keeps its old shape (the Dart client reads it as the
      // message); `code` + `detail` say which of the three upstream
      // failures this was (#166) — all 502, distinct from 401/403/404/500.
      const { code, detail } = logGenerationFailure(
        deps,
        tripId,
        err,
        "generation_failed",
      );
      return json({
        error: `wrap-up generation failed: ${detail}`,
        code,
        detail,
      }, 502);
    }
    newCount = generationCount + 1;
  }

  const content = assembleWrapUpContent(tripData, aiFields);
  const generatedAt = new Date().toISOString();
  const row = {
    content,
    generated_at: generatedAt,
    ai_fields: aiFields,
    // After a failed regeneration the old hash stays, so the next open
    // retries — counted again, so still bounded by the cap.
    ai_input_hash: fieldsMatchInputs ? inputHash : storedHash,
    ai_generation_count: newCount,
  };

  // Never delete-and-recreate (that would reset the counter), and never
  // write over a wrap-up that was kept forever while this request ran.
  const { error: saveError } = existing
    ? await deps.serviceClient
      .from("wrap_ups")
      .update(row)
      .eq("trip_id", tripId)
      .is("published_at", null)
    : await deps.serviceClient
      .from("wrap_ups")
      .insert({ trip_id: tripId, ...row });
  if (saveError) {
    return json(
      { error: `failed to save wrap-up: ${saveError.message}` },
      500,
    );
  }

  return json({ content, generated_at: generatedAt }, 200);
}

function logGenerationFailure(
  deps: Deps,
  tripId: string,
  err: unknown,
  event: string,
): { code: string; detail: string } {
  const code = err instanceof WrapUpGenerationError
    ? err.code
    : "ai_output_invalid";
  const detail = (err as Error).message;
  logEvent(deps.log ?? console.error, event, {
    trip_id: tripId,
    code,
    detail,
  });
  return { code, detail };
}
