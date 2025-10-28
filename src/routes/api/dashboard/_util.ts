import type { RequestEvent } from "@sveltejs/kit";

export function getLocationIdOrThrow(event: RequestEvent): number {
  const id = Number(event.url.searchParams.get("location_id"));
  if (!Number.isFinite(id) || id <= 0) {
    throw new Error('Missing or invalid ?location_id');
  }
  return id;
}

export function getNum(event: RequestEvent, key: string, fallback: number, min?: number, max?: number) {
  const raw = event.url.searchParams.get(key);
  const v = raw === null ? fallback : Number(raw);
  if (!Number.isFinite(v)) return fallback;
  if (min !== undefined && v < min) return min;
  if (max !== undefined && v > max) return max;
  return v;
}

export function yyyymmdd(d: Date) {
  return d.toISOString().slice(0, 10);
}
