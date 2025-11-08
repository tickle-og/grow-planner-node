// Minimal server-side error logger
export function logError(where: string, err: unknown, extra?: Record<string, unknown>) {
	const e = err as any;
	// Keep it simple and structured for tail -f
	console.error(`[${new Date().toISOString()}]`, where, {
		message: e?.message ?? String(err),
		stack: e?.stack,
		cause: e?.cause?.message ?? e?.cause,
		...extra
	});
}
