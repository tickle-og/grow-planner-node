import { json } from '$lib/server/http';
export const POST = async ({ params }) => {
	const id = Number(params.id);
	// TODO: wire to DB (set status='completed', completed_at=now())
	// Swallow errors for now so UI stays snappy.
	try {
		/* no-op */
	} catch {}
	return json({ ok: true, id });
};
