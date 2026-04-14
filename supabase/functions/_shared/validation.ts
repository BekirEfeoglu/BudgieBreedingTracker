import { z } from "npm:zod@3.24.4";

export { z };

type ParseSuccess<T> = { success: true; data: T };
type ParseFailure = { success: false; response: Response };
type ParseResult<T> = ParseSuccess<T> | ParseFailure;

export async function parseRequestBody<T>(
  req: Request,
  schema: z.ZodSchema<T>,
  headers: HeadersInit,
): Promise<ParseResult<T>> {
  let raw: unknown;
  try {
    raw = await req.json();
  } catch {
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
