// Cloudflare Pages Function for storyni.app/m/:slug (#310). Thin: all the
// logic is in src/, which is unit-tested with Deno.

import { type Env, handleSharePage } from "../../src/handler.ts";

export const onRequestGet = (
  context: { request: Request; params: { slug: string }; env: Env },
): Promise<Response> =>
  handleSharePage(context.request, String(context.params.slug), context.env);
