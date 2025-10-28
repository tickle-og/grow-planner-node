// Lightweight JSON helpers for consistent responses
export function json(data: unknown, status = 200, cache = 'no-store') {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': cache
    }
  });
}

export function jsonError(status = 500, message = 'Internal Error') {
  return json({ message }, status);
}
