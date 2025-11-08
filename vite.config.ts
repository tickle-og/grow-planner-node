import { sveltekit } from '@sveltejs/kit/vite';
import { SvelteKitPWA } from '@vite-pwa/sveltekit';
import { defineConfig } from 'vite';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
	plugins: [
		tailwindcss(),
		sveltekit(),
		SvelteKitPWA({
			registerType: 'autoUpdate',
			manifest: {
				name: 'Grow Planner',
				short_name: 'GrowPlanner',
				start_url: '/',
				display: 'standalone',
				background_color: '#0b0b0b',
				theme_color: '#0b0b0b',
				icons: []
			}
		})
	]
});
