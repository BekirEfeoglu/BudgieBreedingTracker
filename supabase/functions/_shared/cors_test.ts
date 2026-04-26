import {
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { corsPreflightResponse, getCorsHeaders } from "./cors.ts";

Deno.test("getCorsHeaders reflects only allowed origins", () => {
  Deno.env.set(
    "ALLOWED_ORIGINS",
    "https://app.example.com,https://admin.example.com",
  );
  const req = new Request("https://edge.example.com", {
    headers: { Origin: "https://app.example.com" },
  });

  const headers = getCorsHeaders(req);

  assertEquals(
    headers["Access-Control-Allow-Origin"],
    "https://app.example.com",
  );
  assertEquals(headers["Vary"], "Origin");
});

Deno.test("getCorsHeaders omits allow-origin for unknown origins", () => {
  Deno.env.set("ALLOWED_ORIGINS", "https://app.example.com");
  const req = new Request("https://edge.example.com", {
    headers: { Origin: "https://evil.example.com" },
  });

  const headers = getCorsHeaders(req);

  assertFalse("Access-Control-Allow-Origin" in headers);
  assertEquals(headers["Vary"], "Origin");
});

Deno.test("corsPreflightResponse uses CORS headers", () => {
  Deno.env.set("ALLOWED_ORIGINS", "https://app.example.com");
  const req = new Request("https://edge.example.com", {
    method: "OPTIONS",
    headers: { Origin: "https://app.example.com" },
  });

  const response = corsPreflightResponse(req);

  assertEquals(
    response.headers.get("Access-Control-Allow-Origin"),
    "https://app.example.com",
  );
  assertEquals(response.headers.get("Vary"), "Origin");
});
