<script lang="ts">
	export let data: any;
</script>

<div class="app-grid">
	<aside class="sidebar">
		<h1 class="brand">Grow Planner</h1>
		<nav class="menu">
			<a href="/" data-sveltekit-preload-data="hover">Today</a>
			<a href="/batches" data-sveltekit-preload-data="hover">Batches</a>
			<a href="/calendar" data-sveltekit-preload-data="hover">Calendar</a>
			<a href="/recipes" data-sveltekit-preload-data="hover">Recipes</a>
			<a href="/logs" data-sveltekit-preload-data="hover">Logs</a>
			<a href="/reports" data-sveltekit-preload-data="hover">Reports</a>
			<a href="/settings" data-sveltekit-preload-data="hover">Settings</a>
		</nav>
	</aside>

	<main class="content">
		<slot />
	</main>
</div>

<style>
	:global(html, body) {
		height: 100%;
		margin: 0;
		background: #0a0a0a;
	}

	.app-grid {
		min-height: 100vh;
		display: grid;
		grid-template-columns: 16rem 1fr; /* fixed sidebar, fluid content */
		background: #0a0a0a;
		color: #f5f5f5;
	}

	.sidebar {
		position: sticky; /* stays put while main scrolls */
		top: 0;
		height: 100vh;
		border-right: 1px solid #262626;
		padding: 1.25rem;
	}

	.brand {
		margin: 0 0 1rem 0;
		font-size: 1.25rem;
		font-weight: 700;
		letter-spacing: 0.2px;
	}

	.menu a {
		display: block;
		padding: 0.5rem 0.75rem;
		border-radius: 0.5rem;
		color: inherit;
		text-decoration: none;
		opacity: 0.9;
		transition:
			background 0.12s ease,
			opacity 0.12s ease;
	}
	.menu a:hover {
		background: #181818;
		opacity: 1;
	}

	.content {
		min-height: 100vh;
		overflow: auto;
		padding: 1.5rem;
	}
</style>
