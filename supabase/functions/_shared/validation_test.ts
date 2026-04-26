import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { parseRequestBody, z } from "./validation.ts";

const headers = { "Content-Type": "application/json" };
const schema = z.object({ name: z.string() });

Deno.test("parseRequestBody parses valid JSON", async () => {
  const req = new Request("https://example.com", {
    method: "POST",
    body: JSON.stringify({ name: "Rio" }),
  });

  const result = await parseRequestBody(req, schema, headers);

  assertEquals(result.success, true);
  if (result.success) {
    assertEquals(result.data.name, "Rio");
  }
});

Deno.test("parseRequestBody rejects invalid JSON", async () => {
  const req = new Request("https://example.com", {
    method: "POST",
    body: "{not-json",
  });

  const result = await parseRequestBody(req, schema, headers);

  assertEquals(result.success, false);
  if (!result.success) {
    assertEquals(result.response.status, 400);
  }
});

Deno.test("parseRequestBody rejects Content-Length above limit", async () => {
  const req = new Request("https://example.com", {
    method: "POST",
    headers: { "Content-Length": "32" },
    body: JSON.stringify({ name: "Rio" }),
  });

  const result = await parseRequestBody(req, schema, headers, 8);

  assertEquals(result.success, false);
  if (!result.success) {
    assertEquals(result.response.status, 413);
  }
});

Deno.test("parseRequestBody rejects streamed body above limit", async () => {
  const body = new ReadableStream<Uint8Array>({
    start(controller) {
      controller.enqueue(new TextEncoder().encode('{"name":"'));
      controller.enqueue(new TextEncoder().encode("0123456789"));
      controller.enqueue(new TextEncoder().encode('"}'));
      controller.close();
    },
  });
  const req = new Request("https://example.com", {
    method: "POST",
    body,
  });

  const result = await parseRequestBody(req, schema, headers, 12);

  assertEquals(result.success, false);
  if (!result.success) {
    assertEquals(result.response.status, 413);
  }
});

Deno.test("parseRequestBody returns validation errors", async () => {
  const req = new Request("https://example.com", {
    method: "POST",
    body: JSON.stringify({ name: 42 }),
  });

  const result = await parseRequestBody(req, schema, headers);

  assertEquals(result.success, false);
  if (!result.success) {
    assertEquals(result.response.status, 400);
    const body = await result.response.json();
    assertEquals(body.error, "Validation failed");
  }
});
