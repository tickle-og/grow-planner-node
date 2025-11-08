export function getLocationIdOrThrow(
	input: URL | string | Request | { url?: string; searchParams?: URLSearchParams }
): number {
	let sp: URLSearchParams | null = null;

	if (input instanceof URL) {
		sp = input.searchParams;
	} else if (typeof input === 'string') {
		sp = new URL(input, 'http://local').searchParams;
	} else if (typeof Request !== 'undefined' && input instanceof Request) {
		sp = new URL(input.url, 'http://local').searchParams;
	} else if (input && typeof (input as any).searchParams !== 'undefined') {
		sp = (input as any).searchParams as URLSearchParams;
	} else if (input && typeof (input as any).url === 'string') {
		sp = new URL((input as any).url, 'http://local').searchParams;
	}

	if (!sp) {
		throw new Error('Missing or invalid ?location_id');
	}

	const val = sp.get('location_id') ?? sp.get('locationId') ?? '1';
	const id = Number(val);
	if (!Number.isFinite(id) || id <= 0) {
		throw new Error('Missing or invalid ?location_id');
	}
	return id;
}
