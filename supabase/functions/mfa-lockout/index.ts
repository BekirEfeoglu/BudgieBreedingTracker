import { createMfaLockoutHandler } from "./handler.ts";

Deno.serve(createMfaLockoutHandler());
