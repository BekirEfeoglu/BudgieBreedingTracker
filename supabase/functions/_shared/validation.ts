import { z } from "npm:zod@3.24.4";

export { z };

type ParseSuccess<T> = { success: true; data: T };
type ParseFailure = { success: false; response: Response };
type ParseResult<T> = ParseSuccess<T> | ParseFailure;

const DEFAULT_MAX_BODY_BYTES = 256 * 1024;

async function readLimitedJsonBody(
  req: Request,
  maxBodyBytes: number,
): Promise<unknown> {
  const contentLength = Number(req.headers.get("content-length") ?? "0");
  if (Number.isFinite(contentLength) && contentLength > maxBodyBytes) {
    throw new RangeError("Request body too large");
  }

  if (!req.body) {
    throw new SyntaxError("Missing request body");
  }

  const reader = req.body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    if (!value) continue;

    total += value.byteLength;
    if (total > maxBodyBytes) {
      await reader.cancel();
      throw new RangeError("Request body too large");
    }
    chunks.push(value);
  }

  const body = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }

  return JSON.parse(new TextDecoder().decode(body));
}

export async function parseRequestBody<T>(
  req: Request,
  schema: z.ZodSchema<T>,
  headers: HeadersInit,
  maxBodyBytes = DEFAULT_MAX_BODY_BYTES,
): Promise<ParseResult<T>> {
  let raw: unknown;
  try {
    raw = await readLimitedJsonBody(req, maxBodyBytes);
  } catch (error) {
    if (error instanceof RangeError) {
      return {
        success: false,
        response: new Response(
          JSON.stringify({ error: "Request body too large" }),
          { status: 413, headers },
        ),
      };
    }
    return {
      success: false,
      response: new Response(
        JSON.stringify({ error: "Invalid JSON body" }),
        { status: 400, headers },
      ),
    };
  }

  const result = schema.safeParse(raw);
  if (!result.success) {
    const fieldErrors = result.error.issues.map((issue) => ({
      path: issue.path.join("."),
      message: issue.message,
    }));
    return {
      success: false,
      response: new Response(
        JSON.stringify({ error: "Validation failed", details: fieldErrors }),
        { status: 400, headers },
      ),
    };
  }

  return { success: true, data: result.data };
}
