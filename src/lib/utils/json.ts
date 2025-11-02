// Tiny JSON response helpers used by API routes.

type HeadersInit = Record<string, string>;

export function json(
  data: unknown,
  status = 200,
  extraHeaders: HeadersInit = {}
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      ...extraHeaders,
    },
  });
}

export function jsonError(
  status = 500,
  message = 'Internal Error',
  extraHeaders: HeadersInit = {}
): Response {
  return json({ message }, status, extraHeaders);
}

export function jsonCache(
  data: unknown,
  seconds = 300,
  status = 200
): Response {
  return json(data, status, {
    'cache-control': `public, max-age=${seconds}`,
  });
}
