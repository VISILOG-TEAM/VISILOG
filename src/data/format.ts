// Tiny date/time/duration helpers used across the UI. Pure functions —
// safe to import from any screen without side effects.

const pad = (n: number): string => String(n).padStart(2, '0');

// "08 May 2026" — for date columns
export const fmtDate = (iso?: string | null): string => {
  if (!iso) return '—';
  const d = new Date(iso);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${pad(d.getDate())} ${months[d.getMonth()]} ${d.getFullYear()}`;
};

// "14:25" — 24-hour time for log readability
export const fmtTime = (iso?: string | null): string => {
  if (!iso) return '—';
  const d = new Date(iso);
  return `${pad(d.getHours())}:${pad(d.getMinutes())}`;
};

// "08 May · 14:25"
export const fmtDateTime = (iso?: string | null): string => {
  if (!iso) return '—';
  return `${fmtDate(iso)} · ${fmtTime(iso)}`;
};

// "just now", "5m ago", "2h ago", "3d ago" — for activity streams.
export const fmtRelative = (iso?: string | null): string => {
  if (!iso) return '—';
  const diffMs = Date.now() - new Date(iso).getTime();
  const diffMin = Math.floor(diffMs / 60000);
  if (diffMin < 1) return 'just now';
  if (diffMin < 60) return `${diffMin}m ago`;
  const diffH = Math.floor(diffMin / 60);
  if (diffH < 24) return `${diffH}h ago`;
  const diffD = Math.floor(diffH / 24);
  return `${diffD}d ago`;
};

// "1h 24m" — duration between two ISO timestamps (or between an ISO and now).
export const fmtDuration = (startIso?: string | null, endIso?: string | null): string => {
  if (!startIso) return '—';
  const start = new Date(startIso).getTime();
  const end = endIso ? new Date(endIso).getTime() : Date.now();
  const totalMin = Math.max(0, Math.floor((end - start) / 60000));
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  if (h === 0) return `${m}m`;
  return `${h}h ${pad(m)}m`;
};
