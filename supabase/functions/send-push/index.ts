import { createSendPushHandler } from "./handler.ts";

Deno.serve(createSendPushHandler());
