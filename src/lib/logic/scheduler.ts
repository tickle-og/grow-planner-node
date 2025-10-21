// src/lib/logic/scheduler.ts
type Step = {
  key: string;
  title: string;
  duration?: string | number; // "14d" | "2h" | "120m" | minutes
  depends_on?: string[];
};

export function parseDurationToMs(d: string | number | undefined): number {
  if (d == null) return 0;
  if (typeof d === 'number') return d * 60_000;
  const m = String(d).trim().match(/^(\d+)\s*([dhm])$/i);
  if (!m) {
    const asNum = Number(d);
    return Number.isFinite(asNum) ? asNum * 60_000 : 0;
  }
  const val = Number(m[1]);
  const unit = m[2].toLowerCase();
  if (unit === 'd') return val * 24 * 60 * 60_000;
  if (unit === 'h') return val * 60 * 60_000;
  return val * 60_000;
}

export function topoSort(steps: Step[]): Step[] {
  const map = new Map(steps.map(s => [s.key, s]));
  const visited = new Set<string>();
  const out: Step[] = [];
  function visit(k: string) {
    if (visited.has(k)) return;
    const s = map.get(k);
    if (!s) return;
    (s.depends_on ?? []).forEach(visit);
    visited.add(k);
    out.push(s);
  }
  steps.forEach(s => visit(s.key));
  return out;
}

/**
 * Generate schedule entries with durations
 */
export function generateSchedule(steps: Step[], startMs: number): {
  title: string; dueAt: number; stepKey: string; durationMin: number;
}[] {
  const order = topoSort(steps);
  let elapsed = 0;
  return order.map((s) => {
    const durMs = parseDurationToMs(s.duration);
    elapsed += durMs;
    return {
      title: s.title,
      stepKey: s.key,
      durationMin: Math.max(0, Math.round(durMs / 60_000)),
      dueAt: startMs + elapsed
    };
  });
}
