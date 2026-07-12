import { createRevokeOauthTokenHandler } from "./handler.ts";

Deno.serve(createRevokeOauthTokenHandler());
