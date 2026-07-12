import { createSyncPremiumStatusHandler } from "./handler.ts";

Deno.serve(createSyncPremiumStatusHandler());
