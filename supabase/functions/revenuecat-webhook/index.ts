import { createRevenueCatWebhookHandler } from "./handler.ts";

Deno.serve(createRevenueCatWebhookHandler());
