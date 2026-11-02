// Server-rendered HTML for storyni.app/m/:slug (#310): the web teaser (2b)
// or the unavailable page (2d), with Open Graph tags (2a) in the first
// response — link-preview crawlers don't run JavaScript.

import { dateRange, type Lang, strings } from "./i18n.ts";

export const SHARE_HOST = "storyni.app";
export const PLAY_PACKAGE = "com.leo.storyni";

/** get_shared_memory_preview's payload (#309). Image fields are paths. */
export interface SharedPreview {
  slug: string;
  title: string;
  destination: string | null;
  start_date: string;
  end_date: string;
  day_count: number;
  photo_count: number;
  has_film: boolean;
  cover_path: string | null;
  og_image_path: string | null;
  photos: string[];
  owner: {
    display_name: string | null;
    handle: string | null;
    avatar_url: string | null;
  };
  preview_ready: boolean;
}

export type Platform = "ios" | "android" | "desktop";

export const APP_SCHEME = "com.leo.storyni";

export interface PageConfig {
  /** Prefix for share-previews paths: `{SUPABASE_URL}/storage/v1/object/public/share-previews/`. */
  previewBaseUrl: string;
  appStoreId: string;
  lang: Lang;
  platform: Platform;
  /** `?open=1`: try the app's own scheme (in-app browsers skip universal links). */
  openInApp?: boolean;
}

export function detectPlatform(userAgent: string | null): Platform {
  const ua = userAgent ?? "";
  if (/iPhone|iPad|iPod/i.test(ua)) return "ios";
  if (/Android/i.test(ua)) return "android";
  return "desktop";
}

export function shareUrl(slug: string): string {
  return `https://${SHARE_HOST}/m/${slug}`;
}

export function escapeHtml(value: string): string {
  return value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function appStoreUrl(config: PageConfig): string {
  return `https://apps.apple.com/app/id${config.appStoreId}`;
}

/** Play passes `referrer` to the app on first launch (Install Referrer API). */
function playUrl(slug: string | null): string {
  const base = `https://play.google.com/store/apps/details?id=${PLAY_PACKAGE}`;
  return slug === null
    ? base
    : `${base}&referrer=${encodeURIComponent(`storyni_slug=${slug}`)}`;
}

/**
 * The store buttons: the device's store first and filled; desktop shows
 * both, App Store first. The App Store button carries the link to copy
 * (iOS deferred deep link: the app offers to paste it after install).
 */
function storeButtons(config: PageConfig, slug: string | null): string {
  const t = strings[config.lang];
  const copy = slug === null
    ? ""
    : ` data-copy="${escapeHtml(shareUrl(slug))}"`;
  const apple = (primary: boolean) =>
    `<a class="store${primary ? " primary" : ""}" href="${
      escapeHtml(appStoreUrl(config))
    }"${copy}>${t.appStore}</a>`;
  const google = (primary: boolean) =>
    `<a class="store${primary ? " primary" : ""}" href="${
      escapeHtml(playUrl(slug))
    }">${t.googlePlay}</a>`;
  if (config.platform === "android") return google(true) + apple(false);
  return apple(true) + google(false);
}

function head(opts: {
  lang: Lang;
  title: string;
  description: string;
  image: string;
  url: string | null;
  appArgument: string | null;
  appStoreId: string;
}): string {
  const e = escapeHtml;
  const appArg = opts.appArgument === null
    ? ""
    : `, app-argument=${opts.appArgument}`;
  return `<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
<title>${e(opts.title)}</title>
<meta name="description" content="${e(opts.description)}">
<meta property="og:site_name" content="Storyni">
<meta property="og:type" content="website">
<meta property="og:title" content="${e(opts.title)}">
<meta property="og:description" content="${e(opts.description)}">
<meta property="og:image" content="${e(opts.image)}">
<meta property="og:image:width" content="1200">
<meta property="og:image:height" content="630">
${
    opts.url === null
      ? ""
      : `<meta property="og:url" content="${e(opts.url)}">\n`
  }<meta name="twitter:card" content="summary_large_image">
<meta name="apple-itunes-app" content="app-id=${e(opts.appStoreId)}${
    e(appArg)
  }">
<meta name="robots" content="noindex">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Fraunces:ital,wght@0,400;1,400&family=JetBrains+Mono:wght@500&family=Literata:ital,wght@0,400;1,400&family=Roboto:wght@400;500;600&display=swap">
<style>${css(opts.lang)}</style>
</head>`;
}

function css(lang: Lang): string {
  const serif = lang === "ru"
    ? "Literata, Georgia, serif"
    : "Fraunces, Literata, Georgia, serif";
  const track = lang === "ru" ? ".08em" : ".14em";
  return `
*{box-sizing:border-box;margin:0}
html{background:#07091A}
body{max-width:480px;min-height:100vh;margin:0 auto;background:#0C0F27;color:#FBFAF6;font:400 14px/1.5 Roboto,system-ui,sans-serif;-webkit-font-smoothing:antialiased}
a{color:inherit;text-decoration:none}
em{font-style:italic;color:#F2A65A}
.serif{font-family:${serif};font-weight:400}
.mono{font:500 9.5px 'JetBrains Mono',ui-monospace,monospace;letter-spacing:${track};text-transform:uppercase}
.hero{position:relative;height:300px;overflow:hidden;background:#131736}
.hero img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}
.hero .scrim{position:absolute;inset:0;background:linear-gradient(to top,#0C0F27 3%,rgba(12,15,39,.4) 50%,rgba(12,15,39,.2))}
.wordmark{position:absolute;top:16px;left:20px;font-style:italic;font-size:18px}
.wordmark b,.star{color:#F29520;font-weight:400}
.hero .caption{position:absolute;left:22px;right:22px;bottom:12px;display:flex;flex-direction:column;gap:6px}
.hero .caption .mono{color:#F2A65A}
.hero h1{font-size:36px;line-height:1.04}
.by{padding:6px 22px 0;display:flex;align-items:center;gap:10px;font-size:13px;color:#AEACB7}
.by strong{color:#FBFAF6;font-weight:500}
.avatar{flex:none;width:30px;height:30px;border-radius:50%;background:#8962C5;color:#FBFAF6;display:flex;align-items:center;justify-content:center;font-weight:600;font-size:12px;overflow:hidden}
.avatar img{width:100%;height:100%;object-fit:cover}
.grid{position:relative;padding:20px 22px 0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:4px}
.tile{aspect-ratio:1;border-radius:10px;overflow:hidden;background:#131736}
.tile img{width:100%;height:100%;object-fit:cover;display:block}
.tile.blur img{filter:blur(10px) brightness(.55);transform:scale(1.15)}
.more{position:absolute;left:22px;right:22px;bottom:0;height:calc(50% - 2px);display:flex;flex-direction:column;align-items:center;justify-content:center;gap:4px;text-align:center;pointer-events:none}
.more .serif{font-size:22px}
.more .mono{letter-spacing:.1em;color:#E8E5DD}
.actions{padding:24px 22px 0;display:flex;flex-direction:column;gap:10px}
.actions .cta{font-size:20px;line-height:1.3;text-align:center;text-wrap:balance}
.store{display:block;text-align:center;padding:13px;border-radius:14px;border:1px solid rgba(174,172,183,.3);font-weight:600;font-size:13px}
.store.primary{padding:14px;background:#FBFAF6;border-color:#FBFAF6;color:#0C0F27;font-size:14px}
.open{padding:16px 0 30px;text-align:center;font-size:12px;color:#6D6D7A}
.open span{color:#F29520}
.gone{min-height:100vh;display:flex;flex-direction:column;background:radial-gradient(110% 50% at 50% 0%,#241C4E 0%,#0F1230 50%,#0C0F27 100%)}
.gone .body{flex:1;display:flex;flex-direction:column;justify-content:center;gap:14px;padding:60px 34px}
.gone .tile-dashed{width:96px;height:120px;border-radius:16px;border:1.5px dashed rgba(174,172,183,.3);display:flex;align-items:center;justify-content:center;font-size:28px;color:#6D6D7A}
.gone .mono{color:#6D6D7A}
.gone h1{font-size:30px;line-height:1.12}
.gone p{font-size:13px;line-height:1.6;color:#92909E}
.gone .actions{padding:0 22px 38px}
`;
}

/** 2d's buttons: "Start your own memory" to the device's store. */
function startOwnButtons(config: PageConfig): string {
  const t = strings[config.lang];
  const primaryHref = config.platform === "android"
    ? playUrl(null)
    : appStoreUrl(config);
  const secondary = config.platform === "desktop"
    ? `<a class="store" href="${escapeHtml(playUrl(null))}">${t.googlePlay}</a>`
    : "";
  return `<a class="store primary" href="${
    escapeHtml(primaryHref)
  }">${t.startOwn}</a>${secondary}`;
}

function openInAppScript(slug: string): string {
  return `<script>location.href = ${
    JSON.stringify(`${APP_SCHEME}://m/${slug}`)
  };</script>`;
}

/** Copies the share link before leaving for the App Store (iOS deferred link). */
const script = `<script>
document.querySelectorAll('a[data-copy]').forEach(function (a) {
  a.addEventListener('click', function (e) {
    if (!navigator.clipboard) return;
    e.preventDefault();
    navigator.clipboard.writeText(a.dataset.copy).catch(function () {}).finally(function () {
      location.href = a.href;
    });
  });
});
</script>`;

function initial(name: string | null): string {
  const first = (name ?? "").trim().charAt(0);
  return first === "" ? "✦" : first.toUpperCase();
}

/** 2b — the teaser. */
export function renderTeaser(p: SharedPreview, config: PageConfig): string {
  const t = strings[config.lang];
  const e = escapeHtml;
  const img = (path: string) => config.previewBaseUrl + path;
  const name = p.owner.display_name?.trim() || null;
  const dates = dateRange(p.start_date, p.end_date, config.lang);
  const place = p.destination?.trim() || null;
  const ogTitle = place === null ? p.title : `${p.title} · ${place}`;
  const eyebrow = [place, dates, t.days(p.day_count)]
    .filter((s): s is string => s !== null)
    .join(" · ");
  const ready = p.preview_ready && p.photos.length > 0;
  const fallbackImage = `https://${SHARE_HOST}/og-default.jpg`;

  const avatar = p.owner.avatar_url
    ? `<span class="avatar"><img src="${
      e(p.owner.avatar_url)
    }" alt="" width="30" height="30"></span>`
    : `<span class="avatar">${e(initial(name))}</span>`;
  const by = name === null
    ? ""
    : `<div class="by">${avatar}<span>${t.sharedBy(e(name))}${
      p.owner.handle ? ` · @${e(p.owner.handle)}` : ""
    }</span></div>`;

  const tiles = p.photos.slice(0, 6).map((path, i) =>
    `<div class="tile${i >= 2 ? " blur" : ""}"><img src="${
      e(img(path))
    }" alt="" width="140" height="140" loading="lazy"></div>`
  ).join("");
  const hidden = Math.max(p.photo_count - 2, 0);
  const more = p.photos.length > 2 && hidden > 0
    ? `<div class="more"><span class="serif">${
      e(t.more(hidden))
    }</span><span class="mono">${
      p.has_film ? t.moreSub : t.moreSubNoFilm
    }</span></div>`
    : "";
  const grid = ready ? `<div class="grid">${tiles}${more}</div>` : "";

  const cover = ready && p.cover_path
    ? `<img src="${e(img(p.cover_path))}" alt="" width="480" height="300">`
    : "";

  return `<!doctype html>
<html lang="${config.lang}">
${
    head({
      lang: config.lang,
      title: ogTitle,
      description: name === null ? t.ogDescriptionAnon : t.ogDescription(name),
      image: p.og_image_path ? img(p.og_image_path) : fallbackImage,
      url: shareUrl(p.slug),
      appArgument: shareUrl(p.slug),
      appStoreId: config.appStoreId,
    })
  }
<body>
<header class="hero">${cover}<div class="scrim"></div>
<span class="wordmark serif">Storyni<b> ✦</b></span>
<div class="caption"><span class="mono">${e(eyebrow)}</span><h1 class="serif">${
    e(p.title)
  }</h1></div>
</header>
${by}
${grid}
<div class="actions">
<p class="cta serif">${t.cta}</p>
${storeButtons(config, p.slug)}
<a class="open" href="${e(shareUrl(p.slug))}?open=1">${t.openInApp}</a>
</div>
${script}
${config.openInApp ? openInAppScript(p.slug) : ""}
</body>
</html>`;
}

/** 2d — an unknown, revoked or deleted link. Same page for all three. */
export function renderUnavailable(config: PageConfig): string {
  const t = strings[config.lang];
  return `<!doctype html>
<html lang="${config.lang}">
${
    head({
      lang: config.lang,
      title: t.ogUnavailableTitle,
      description: t.ogDescriptionAnon,
      image: `https://${SHARE_HOST}/og-default.jpg`,
      url: null,
      appArgument: null,
      appStoreId: config.appStoreId,
    })
  }
<body>
<main class="gone">
<div class="body">
<div class="tile-dashed serif">✦</div>
<span class="mono">${t.unavailableEyebrow}</span>
<h1 class="serif">${t.unavailableTitle}</h1>
<p>${t.unavailableBody}</p>
</div>
<div class="actions">${startOwnButtons(config)}</div>
</main>
${script}
</body>
</html>`;
}
