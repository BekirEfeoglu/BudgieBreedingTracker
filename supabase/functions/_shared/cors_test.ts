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

Deno.test("getCorsHeaders includes baseline security headers", () => {
  Deno.env.set("ALLOWED_ORIGINS", "https://app.example.com");
  const req = new Request("https://edge.example.com", {
    headers: { Origin: "https://app.example.com" },
  });

  const headers = getCorsHeaders(req);

  // HSTS must enforce HTTPS for at least one year and cover subdomains.
  const hsts = headers["Strict-Transport-Security"] ?? "";
  assertEquals(hsts.includes("max-age="), true);
  assertEquals(hsts.includes("includeSubDomains"), true);
  assertEquals(headers["X-Content-Type-Options"], "nosniff");
  assertEquals(headers["X-Frame-Options"], "DENY");
  assertEquals(
    headers["Referrer-Policy"],
    "strict-origin-when-cross-origin",
  );
  // CSP for JSON endpoints must default-deny.
  const csp = headers["Content-Security-Policy"] ?? "";
  assertEquals(csp.includes("default-src 'none'"), true);
  assertEquals(csp.includes("frame-ancestors 'none'"), true);
});

Deno.test(
  "getCorsHeaders security headers are present even for unknown origins",
  () => {
    Deno.env.set("ALLOWED_ORIGINS", "https://app.example.com");
    const req = new Request("https://edge.example.com", {
      headers: { Origin: "https://evil.example.com" },
    });

    const headers = getCorsHeaders(req);

    // Origin not allowed, but baseline security headers must still apply.
    assertFalse("Access-Control-Allow-Origin" in headers);
    assertEquals(headers["X-Content-Type-Options"], "nosniff");
    assertEquals(headers["X-Frame-Options"], "DENY");
  },
);
