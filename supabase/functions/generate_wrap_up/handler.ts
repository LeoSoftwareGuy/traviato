// Request handling for generate_wrap_up (#93), separated from index.ts's
// Deno.serve bootstrap so it can be exercised in tests without starting a
// server. Auth guard + ownership check per docs/supabase.md; idempotent per
// the issue's acceptance criteria (existing content short-circuits before
// any Anthropic call).

import { gatherTripData, type TripData } from "./gather.ts";
import type { Screenplay } from "./screenplay.ts";

// deno-lint-ignore no-explicit-any
type SupabaseClient = any;

export interface Deps {
  serviceClient: SupabaseClient;
  authClient: (authHeader: string) => SupabaseClient;
  generateScreenplay: (tripData: TripData) => Promise<Screenplay>;
}

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json" },
  });
}

export async function handleRequest(req: Request, deps: Deps): Promise<Response> {
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

  const { data: userData, error: userError } = await deps.authClient(authHeader).auth.getUser();
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
    .select("content, generated_at")
    .eq("trip_id", tripId)
    .maybeSingle();
  if (existingError) {
    return json({ error: `wrap-up lookup failed: ${existingError.message}` }, 500);
  }
  if (existing?.content) {
    return json({ content: existing.content, generated_at: existing.generated_at }, 200);
  }

  let tripData: TripData;
  try {
    tripData = await gatherTripData(deps.serviceClient, tripId);
  } catch (err) {
    return json({ error: `failed to gather trip data: ${(err as Error).message}` }, 500);
  }

  let screenplay: Screenplay;
  try {
    screenplay = await deps.generateScreenplay(tripData);
  } catch (err) {
    return json({ error: `wrap-up generation failed: ${(err as Error).message}` }, 502);
  }

  const generatedAt = new Date().toISOString();
  const { error: upsertError } = await deps.serviceClient
    .from("wrap_ups")
    .upsert({ trip_id: tripId, content: screenplay, generated_at: generatedAt });
  if (upsertError) {
    return json({ error: `failed to save wrap-up: ${upsertError.message}` }, 500);
  }

  return json({ content: screenplay, generated_at: generatedAt }, 200);
}
