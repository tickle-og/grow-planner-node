export function json(a: number | unknown, b?: unknown) {
  let status: number;
  let data: unknown;

  if (typeof a === 'number') {
    // Called as json(200, data)
    status = a;
    data = b ?? {};
  } else {
    // Called as json(data, 200) or json(data, { status })
    data = a;
    if (typeof b === 'number') {
      status = b;
    } else if (b && typeof (b as any).status === 'number') {
      status = (b as any).status;
    } else {
      status = 200;
    }
  }

  return new Response(JSON.stringify(data), {
    status,
    headers: { 'content-type': 'application/json' }
  });
}

export function jsonError(status = 500, message = 'Internal Error') {
  return json({ message }, { status });
}
