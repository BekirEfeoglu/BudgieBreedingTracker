import { createSystemHealthHandler } from "./handler.ts";

Deno.serve(createSystemHealthHandler());
