<!-- src/routes/calendar/+page.svelte -->
<script lang="ts">
	export let data: { locationId: number; tasks: any[] };

	function safeDate(v: any): Date | null {
		if (!v && v !== 0) return null;
		const d = new Date(v);
		return isNaN(d.getTime()) ? null : d;
	}
	function taskDueAt(t: any): Date | null {
		for (const k of [
			'dueAt',
			'due_at',
			'due',
			'dueDate',
			'due_date',
			'scheduledAt',
			'scheduled_at'
		]) {
			const d = safeDate(t[k]);
			if (d) return d;
		}
		return null;
	}
	function groupTasksByDay(ts: any[]) {
		const map = new Map<string, any[]>();
		for (const t of ts) {
			const d = taskDueAt(t);
			const key = d
				? new Date(d.getFullYear(), d.getMonth(), d.getDate()).toISOString().slice(0, 10)
				: 'unscheduled';
			if (!map.has(key)) map.set(key, []);
			map.get(key)!.push(t);
		}
		return map;
	}
	function nextNDates(n = 7) {
		const out: string[] = [];
		const now = new Date();
		for (let i = 0; i < n; i++) {
			const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() + i);
			out.push(d.toISOString().slice(0, 10));
		}
		return out;
	}
	function sortBySoonest(a: any, b: any) {
		const da = taskDueAt(a);
		const db = taskDueAt(b);
		if (da && db) return da.getTime() - db.getTime();
		if (da && !db) return -1;
		if (!da && db) return 1;
		return 0;
	}

	// Reactive data
	$: tasks = (data.tasks ?? []).slice().sort(sortBySoonest);
	$: groups = groupTasksByDay(tasks);

	type View = 'week' | '14' | 'all';
	let view: View = 'week';

	function daysForRange(v: View) {
		if (v === 'week') return nextNDates(7);
		if (v === '14') return nextNDates(14);
		// 'all' → show all dated buckets present in tasks (ascending)
		const keys = [...groups.keys()].filter((k) => k !== 'unscheduled');
		keys.sort((a, b) => new Date(a).getTime() - new Date(b).getTime());
		// fallback to a week if no dated tasks exist
		return keys.length ? keys : nextNDates(7);
	}
	$: days = daysForRange(view);

	function fmtDateISOToHuman(iso: string) {
		const d = new Date(iso);
		return d.toLocaleDateString(undefined, { weekday: 'short', month: 'short', day: 'numeric' });
	}
</script>

<div class="mx-auto max-w-6xl px-4 py-6">
	<div class="header-row">
		<h1 class="page-title">Calendar</h1>
		<div class="subtitle">Location #{data.locationId}</div>
	</div>

	<!-- Filter row -->
	<div class="filter-row" role="tablist" aria-label="Calendar range">
		<button
			role="tab"
			aria-selected={view === 'week'}
			class="filter-btn"
			class:active={view === 'week'}
			on:click={() => (view = 'week')}
		>
			This week
		</button>
		<button
			role="tab"
			aria-selected={view === '14'}
			class="filter-btn"
			class:active={view === '14'}
			on:click={() => (view = '14')}
		>
			Next 14 days
		</button>
		<button
			role="tab"
			aria-selected={view === 'all'}
			class="filter-btn"
			class:active={view === 'all'}
			on:click={() => (view = 'all')}
		>
			All
		</button>
	</div>

	<!-- Grid of days -->
	<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 mt-4">
		{#each days as d}
			<div class="cal-cell">
				<div class="cal-date">{fmtDateISOToHuman(d)}</div>
				<ul class="mt-2 space-y-1">
					{#each groups.get(d) ?? [] as t}
						<li class="task-line">• {t.title ?? t.action ?? t.type ?? 'Task'}</li>
					{/each}
					{#if (groups.get(d) ?? []).length === 0}
						<li class="task-empty">—</li>
					{/if}
				</ul>
			</div>
		{/each}
	</div>

	{#if view === 'all' && (groups.get('unscheduled') ?? []).length}
		<div class="unscheduled mt-6">
			<div class="unscheduled-title">Unscheduled</div>
			<ul class="mt-2 space-y-1">
				{#each groups.get('unscheduled') as t}
					<li class="task-line">• {t.title ?? t.action ?? t.type ?? 'Task'}</li>
				{/each}
			</ul>
		</div>
	{/if}
</div>

<style>
	.header-row {
		display: flex;
		align-items: baseline;
		gap: 0.75rem;
	}
	.page-title {
		font-size: 1.5rem;
		font-weight: 800;
		color: #0b1220;
	}
	.subtitle {
		color: #0b1220;
		opacity: 0.8;
	}

	.filter-row {
		margin-top: 0.75rem;
		display: inline-flex;
		gap: 0.4rem;
		padding: 0.25rem;
		border: 1px solid #e5e7eb;
		border-radius: 0.75rem;
		background: #ffffff;
	}
	.filter-btn {
		appearance: none;
		border: 0;
		padding: 0.35rem 0.7rem;
		border-radius: 0.55rem;
		font-weight: 700;
		color: #0b1220;
		background: transparent;
		cursor: pointer;
		transition:
			background 0.15s ease,
			box-shadow 0.15s ease;
	}
	.filter-btn:hover {
		background: #f1f5f9;
	}
	.filter-btn.active {
		background: #0b1220;
		color: #ffffff;
		box-shadow:
			0 1px 0 rgba(0, 0, 0, 0.06),
			inset 0 0 0 1px rgba(255, 255, 255, 0.06);
	}

	.cal-cell {
		background: #fff;
		border: 1px solid #e5e7eb;
		border-radius: 0.5rem;
		padding: 0.6rem 0.7rem;
	}
	.cal-date {
		font-weight: 800;
		color: #0b1220;
	}
	.task-line {
		color: #0b1220;
		font-size: 0.95rem;
	}
	.task-empty {
		color: #0b1220;
		opacity: 0.8;
		font-size: 0.9rem;
	}

	.unscheduled {
		background: #fff;
		border: 1px solid #e5e7eb;
		border-radius: 0.5rem;
		padding: 0.75rem 0.9rem;
	}
	.unscheduled-title {
		font-weight: 800;
		color: #0b1220;
	}
</style>
