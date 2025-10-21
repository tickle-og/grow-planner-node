
// this file is generated — do not edit it


declare module "svelte/elements" {
	export interface HTMLAttributes<T> {
		'data-sveltekit-keepfocus'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-noscroll'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-preload-code'?:
			| true
			| ''
			| 'eager'
			| 'viewport'
			| 'hover'
			| 'tap'
			| 'off'
			| undefined
			| null;
		'data-sveltekit-preload-data'?: true | '' | 'hover' | 'tap' | 'off' | undefined | null;
		'data-sveltekit-reload'?: true | '' | 'off' | undefined | null;
		'data-sveltekit-replacestate'?: true | '' | 'off' | undefined | null;
	}
}

export {};


declare module "$app/types" {
	export interface AppTypes {
		RouteId(): "/" | "/api" | "/api/dev" | "/api/dev/seed" | "/batches" | "/batches/new" | "/batches/[id]" | "/calendar" | "/recipes" | "/recipes/new" | "/recipes/[id]";
		RouteParams(): {
			"/batches/[id]": { id: string };
			"/recipes/[id]": { id: string }
		};
		LayoutParams(): {
			"/": { id?: string };
			"/api": Record<string, never>;
			"/api/dev": Record<string, never>;
			"/api/dev/seed": Record<string, never>;
			"/batches": { id?: string };
			"/batches/new": Record<string, never>;
			"/batches/[id]": { id: string };
			"/calendar": Record<string, never>;
			"/recipes": { id?: string };
			"/recipes/new": Record<string, never>;
			"/recipes/[id]": { id: string }
		};
		Pathname(): "/" | "/api" | "/api/" | "/api/dev" | "/api/dev/" | "/api/dev/seed" | "/api/dev/seed/" | "/batches" | "/batches/" | "/batches/new" | "/batches/new/" | `/batches/${string}` & {} | `/batches/${string}/` & {} | "/calendar" | "/calendar/" | "/recipes" | "/recipes/" | "/recipes/new" | "/recipes/new/" | `/recipes/${string}` & {} | `/recipes/${string}/` & {};
		ResolvedPathname(): `${"" | `/${string}`}${ReturnType<AppTypes['Pathname']>}`;
		Asset(): "/robots.txt" | string & {};
	}
}