// Canonical JSON helpers for SvelteKit endpoints.
export type JSONValue = unknown;

function toInit(init?: number | ResponseInit): ResponseInit {
	if (typeof init === 'number') return { status: init };
	return init ?? {};
}

export function json(data: JSONValue, init?: number | ResponseInit): Response {
	const base = toInit(init);
	const headers = new Headers(base.headers || {});
	if (!headers.has('content-type')) headers.set('content-type', 'application/json; charset=utf-8');
	if (!headers.has('cache-control')) headers.set('cache-control', 'no-store');
	return new Response(JSON.stringify(data), { ...base, headers });
}

export function jsonError(status = 500, body: JSONValue = { message: 'Internal Error' }): Response {
	const init = toInit(status);
	const headers = new Headers(init.headers || {});
	if (!headers.has('content-type')) headers.set('content-type', 'application/json; charset=utf-8');
	if (!headers.has('cache-control')) headers.set('cache-control', 'no-store');
	return new Response(
		JSON.stringify({
			ok: false,
			...(body && typeof body === 'object' ? body : { error: String(body) })
		}),
		{ ...init, status: typeof init.status === 'number' ? init.status : status, headers }
	);
}
