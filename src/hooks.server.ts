import type { Handle } from '@sveltejs/kit';

export const handle: Handle = async ({ event, resolve }) => {
	// DEV ONLY: if you don't have auth yet, stub a user so pages don't explode.
	if (!event.locals.user) {
		event.locals.user = { id: 1, username: 'dev', role: 'admin' };
	}
	return resolve(event);
};
