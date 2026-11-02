# storyni.app — shared-memory pages (#310)

A tiny Cloudflare Pages project. It serves:

- `/m/:slug` — `functions/m/[slug].ts`, server-rendered so link-preview
  crawlers (WhatsApp, iMessage, Instagram DMs) get the Open Graph tags
  without running JS. It calls `get_shared_memory_preview` (#309) with
  the anon key and renders the teaser (design 2b) or the unavailable page
  (2d). Always HTTP 200; cached `s-maxage=300`, so a turned-off link
  shows 2d within 5 minutes.
- `/.well-known/apple-app-site-association` and `/.well-known/assetlinks.json`
  — iOS Universal Links / Android App Links for `/m/*`.
- `/og-default.jpg` — the brand link-preview image for dead links.

No framework, no bundle: `src/` is plain TypeScript, tested with Deno:

```sh
cd share_web
deno test src/
```

## Environment variables (Pages → Settings → Variables)

| Name | Value |
|---|---|
| `SUPABASE_URL` | the hosted project URL, e.g. `https://xxxx.supabase.co` |
| `SUPABASE_ANON_KEY` | the project's anon / publishable key (public by design — it can only call the preview RPC) |
| `APP_STORE_ID` | the numeric App Store id, once the app is listed |

## One-time setup checklist

1. **Domain:** register `storyni.app` (any registrar; `.app` requires
   HTTPS, which Pages provides).
2. **Cloudflare Pages:** create a project from this repo with root
   directory `share_web`, build command empty, output directory `public`.
   Or deploy by hand: `npx wrangler pages deploy public` from `share_web/`.
3. **Custom domain:** Pages → Custom domains → add `storyni.app`
   (Cloudflare creates the DNS record when the zone is on Cloudflare;
   otherwise add the CNAME it shows).
4. Set the three environment variables above (Production), redeploy.
5. **iOS:** replace `TEAMID` in `public/.well-known/apple-app-site-association`
   with the Apple Developer Team ID. In the Apple Developer portal, enable
   **Associated Domains** for `com.leo.storyni` (the app already has the
   `applinks:storyni.app` entitlement). Check with
   `curl -sI https://storyni.app/.well-known/apple-app-site-association`
   → `200`, `content-type: application/json`, no redirect.
6. **Android:** in `public/.well-known/assetlinks.json`, replace
   `UPLOAD_KEY_SHA256` with the release/upload key's SHA-256
   (`keytool -list -v -keystore <upload.jks>`) and
   `PLAY_APP_SIGNING_SHA256` with Play Console → Setup → App signing →
   *App signing key certificate* SHA-256. Validate with Google's
   [Statement List tester](https://developers.google.com/digital-asset-links/tools/generator).
7. **Smoke test:** `curl -A facebookexternalhit https://storyni.app/m/<slug>`
   shows the `og:` tags; open the link on a phone with and without the
   app installed.
