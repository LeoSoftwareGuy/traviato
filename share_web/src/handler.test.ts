import {
  assert,
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { type Env, handleSharePage } from "./handler.ts";
import { dateRange, pickLang } from "./i18n.ts";
import type { SharedPreview } from "./render.ts";

const env: Env = {
  SUPABASE_URL: "https://proj.supabase.co",
  SUPABASE_ANON_KEY: "anon-key",
  APP_STORE_ID: "123456789",
};

const preview: SharedPreview = {
  slug: "k7Qm2xPa9c",
  title: "One long road",
  destination: "Highlands",
  start_date: "2026-08-12",
  end_date: "2026-08-16",
  day_count: 5,
  photo_count: 84,
  has_film: true,
  cover_path: "k7Qm2xPa9c/0.jpg",
  og_image_path: "k7Qm2xPa9c/og.jpg",
  photos: [0, 1, 2, 3, 4, 5].map((n) => `k7Qm2xPa9c/${n}.jpg`),
  owner: { display_name: "Leo", handle: "leo", avatar_url: null },
  preview_ready: true,
};

const IPHONE = "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)";
const ANDROID = "Mozilla/5.0 (Linux; Android 15; Pixel 9)";
const FACEBOOK = "facebookexternalhit/1.1";

function fakeFetch(body: unknown, status = 200) {
  const calls: { url: string; init?: RequestInit }[] = [];
  const fn = (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), init });
    return Promise.resolve(
      new Response(JSON.stringify(body), {
        status,
        headers: { "content-type": "application/json" },
      }),
    );
  };
  return { fn: fn as typeof fetch, calls };
}

async function page(
  slug: string,
  body: unknown,
  headers: Record<string, string> = {},
  status = 200,
  query = "",
) {
  const { fn, calls } = fakeFetch(body, status);
  const response = await handleSharePage(
    new Request(`https://storyni.app/m/${slug}${query}`, { headers }),
    slug,
    env,
    fn,
  );
  return { response, html: await response.text(), calls };
}

Deno.test("active slug: 200 with OG tags in the HTML, no JS needed", async () => {
  const { response, html, calls } = await page("k7Qm2xPa9c", preview, {
    "User-Agent": FACEBOOK,
  });
  assertEquals(response.status, 200);
  assertEquals(
    response.headers.get("cache-control"),
    "public, max-age=60, s-maxage=300",
  );
  assertStringIncludes(
    html,
    '<meta property="og:title" content="One long road · Highlands">',
  );
  assertStringIncludes(
    html,
    '<meta property="og:description" content="Leo shared a memory on Storyni.">',
  );
  assertStringIncludes(
    html,
    '<meta property="og:image" content="https://proj.supabase.co/storage/v1/object/public/share-previews/k7Qm2xPa9c/og.jpg">',
  );
  assertStringIncludes(
    html,
    '<meta property="og:url" content="https://storyni.app/m/k7Qm2xPa9c">',
  );
  assertStringIncludes(
    html,
    '<meta name="twitter:card" content="summary_large_image">',
  );
  assertStringIncludes(
    html,
    '<meta name="apple-itunes-app" content="app-id=123456789, app-argument=https://storyni.app/m/k7Qm2xPa9c">',
  );

  assertEquals(calls.length, 1);
  assertEquals(
    calls[0].url,
    "https://proj.supabase.co/rest/v1/rpc/get_shared_memory_preview",
  );
  assertEquals(JSON.parse(String(calls[0].init?.body)), {
    p_slug: "k7Qm2xPa9c",
  });
});

Deno.test("teaser: 2 clear photos, 4 blurred, +N more and the film", async () => {
  const { html } = await page("k7Qm2xPa9c", preview);
  assertEquals(html.match(/class="tile"/g)?.length, 2);
  assertEquals(html.match(/class="tile blur"/g)?.length, 4);
  assertStringIncludes(html, "+82 more");
  assertStringIncludes(html, "Photos · notes · the film");
  assertStringIncludes(html, 'loading="lazy"');
  assertStringIncludes(html, "Highlands · 12–16 AUG 2026 · 5 days");
  assertStringIncludes(html, "Shared by <strong>Leo</strong> · @leo");
});

Deno.test("no film: the grid leaves it out", async () => {
  const { html } = await page("k7Qm2xPa9c", { ...preview, has_film: false });
  assertStringIncludes(html, "Photos · notes</span>");
});

Deno.test("preview not built yet: title, dates and CTA only", async () => {
  const { html } = await page("k7Qm2xPa9c", {
    ...preview,
    preview_ready: false,
    photos: [],
    cover_path: null,
    og_image_path: null,
  });
  assert(!html.includes('class="grid"'));
  assertStringIncludes(html, "One long road");
  assertStringIncludes(
    html,
    '<meta property="og:image" content="https://storyni.app/og-default.jpg">',
  );
});

Deno.test("null preview: 200 with the unavailable page and brand OG", async () => {
  const { response, html } = await page("k7Qm2xPa9c", null);
  assertEquals(response.status, 200);
  assertStringIncludes(html, "Link unavailable");
  assertStringIncludes(html, "isn't shared anymore");
  assertStringIncludes(
    html,
    '<meta property="og:title" content="A memory on Storyni">',
  );
  assertStringIncludes(
    html,
    '<meta property="og:image" content="https://storyni.app/og-default.jpg">',
  );
  assert(!html.includes("og:url"));
});

Deno.test("a malformed slug never reaches Supabase", async () => {
  const { html, calls } = await page("nope", preview);
  assertEquals(calls.length, 0);
  assertStringIncludes(html, "Link unavailable");
});

Deno.test("lookup failure: unavailable page, cached briefly", async () => {
  const { response, html } = await page(
    "k7Qm2xPa9c",
    { message: "x" },
    {},
    500,
  );
  assertEquals(response.status, 200);
  assertStringIncludes(html, "Link unavailable");
  assertEquals(
    response.headers.get("cache-control"),
    "public, max-age=0, s-maxage=30",
  );
});

Deno.test("store buttons follow the device; App Store copies the link", async () => {
  const ios =
    (await page("k7Qm2xPa9c", preview, { "User-Agent": IPHONE })).html;
  assert(ios.indexOf("apps.apple.com") < ios.indexOf("play.google.com"));
  assertStringIncludes(
    ios,
    'class="store primary" href="https://apps.apple.com/app/id123456789" data-copy="https://storyni.app/m/k7Qm2xPa9c"',
  );

  const android =
    (await page("k7Qm2xPa9c", preview, { "User-Agent": ANDROID })).html;
  assert(
    android.indexOf("play.google.com") < android.indexOf("apps.apple.com"),
  );
  assertStringIncludes(
    android,
    'class="store primary" href="https://play.google.com/store/apps/details?id=com.leo.storyni&amp;referrer=storyni_slug%3Dk7Qm2xPa9c"',
  );
});

Deno.test("?open=1 tries the app's own scheme", async () => {
  const { html } = await page("k7Qm2xPa9c", preview, {}, 200, "?open=1");
  assertStringIncludes(
    html,
    'location.href = "com.leo.storyni://m/k7Qm2xPa9c"',
  );
  const plain = (await page("k7Qm2xPa9c", preview)).html;
  assert(!plain.includes("com.leo.storyni://"));
});

Deno.test("user content is escaped", async () => {
  const { html } = await page("k7Qm2xPa9c", {
    ...preview,
    title: '<script>alert("x")</script>',
    owner: { display_name: "<b>Leo</b>", handle: "leo", avatar_url: null },
  });
  assert(!html.includes("<script>alert"));
  assertStringIncludes(
    html,
    "&lt;script&gt;alert(&quot;x&quot;)&lt;/script&gt;",
  );
  assertStringIncludes(html, "&lt;b&gt;Leo&lt;/b&gt;");
});

Deno.test("Russian from Accept-Language", async () => {
  const { html } = await page("k7Qm2xPa9c", preview, {
    "Accept-Language": "ru-RU,ru;q=0.9,en;q=0.8",
  });
  assertStringIncludes(html, '<html lang="ru">');
  assertStringIncludes(html, "Leo поделился(-ась) воспоминанием в Storyni.");
  assertStringIncludes(html, "Ещё 82");
});

Deno.test("pickLang: first of en/ru by quality, English otherwise", () => {
  assertEquals(pickLang(null), "en");
  assertEquals(pickLang("de-DE,de;q=0.9"), "en");
  assertEquals(pickLang("de-DE,ru;q=0.7,en;q=0.5"), "ru");
  assertEquals(pickLang("en;q=0.4,ru;q=0.8"), "ru");
});

Deno.test("dateRange matches the app's format", () => {
  assertEquals(dateRange("2026-08-12", "2026-08-16", "en"), "12–16 AUG 2026");
  assertEquals(
    dateRange("2026-07-30", "2026-08-02", "en"),
    "30 JUL – 2 AUG 2026",
  );
  assertEquals(
    dateRange("2026-12-30", "2027-01-02", "en"),
    "30 DEC 2026 – 2 JAN 2027",
  );
  assertEquals(dateRange("2026-08-12", "2026-08-12", "en"), "12 AUG 2026");
});
