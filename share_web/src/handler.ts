// GET /m/:slug (#310). Looks the slug up with the anon key and renders the
// teaser (2b) or the unavailable page (2d). Always 200, so link-preview
// crawlers get the brand OG card even for a dead link.

import { pickLang } from "./i18n.ts";
import {
  detectPlatform,
  renderTeaser,
  renderUnavailable,
  type SharedPreview,
} from "./render.ts";

export interface Env {
  SUPABASE_URL: string;
  /** The anon / publishable key: it can only call the preview RPC. */
  SUPABASE_ANON_KEY: string;
  APP_STORE_ID: string;
}

const SLUG = /^[A-Za-z0-9]{10}$/;

/** A revoked link falls back to 2d within this long (spec: 5 minutes). */
const CACHE_OK = "public, max-age=60, s-maxage=300";
/** A lookup failure isn't cached for long, so it heals quickly. */
const CACHE_ERROR = "public, max-age=0, s-maxage=30";

export async function fetchPreview(
  slug: string,
  env: Env,
  fetchFn: typeof fetch = fetch,
): Promise<SharedPreview | null> {
  const response = await fetchFn(
    `${env.SUPABASE_URL}/rest/v1/rpc/get_shared_memory_preview`,
    {
      method: "POST",
      headers: {
        apikey: env.SUPABASE_ANON_KEY,
        Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ p_slug: slug }),
    },
  );
  if (!response.ok) {
    throw new Error(`preview lookup failed: ${response.status}`);
  }
  return (await response.json()) as SharedPreview | null;
}

export async function handleSharePage(
  request: Request,
  slug: string,
  env: Env,
  fetchFn: typeof fetch = fetch,
): Promise<Response> {
  const url = new URL(request.url);
  const config = {
    previewBaseUrl:
      `${env.SUPABASE_URL}/storage/v1/object/public/share-previews/`,
    appStoreId: env.APP_STORE_ID,
    lang: pickLang(request.headers.get("Accept-Language")),
    platform: detectPlatform(request.headers.get("User-Agent")),
    openInApp: url.searchParams.get("open") === "1",
  };

  let preview: SharedPreview | null = null;
  let cache = CACHE_OK;
  if (SLUG.test(slug)) {
    try {
      preview = await fetchPreview(slug, env, fetchFn);
    } catch (e) {
      console.error(`[share_web] ${e}`);
      cache = CACHE_ERROR;
    }
  }

  const html = preview === null
    ? renderUnavailable(config)
    : renderTeaser(preview, config);
  return new Response(html, {
    status: 200,
    headers: {
      "Content-Type": "text/html; charset=utf-8",
      "Cache-Control": cache,
      "Vary": "Accept-Language, User-Agent",
      "Referrer-Policy": "no-referrer",
      "X-Content-Type-Options": "nosniff",
    },
  });
}
