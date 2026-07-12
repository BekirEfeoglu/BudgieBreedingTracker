import { createValidateFreeTierLimitHandler } from "./handler.ts";

Deno.serve(createValidateFreeTierLimitHandler());
