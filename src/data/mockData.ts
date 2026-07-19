// VisiLog static reference data
// -------------------------------------------------------------
// Everything that used to live here as demo data (organizations,
// employees, visitors, appointments, calls, billing, etc.) now comes
// from the real backend via DataContext/AuthContext. What's left are
// plain option lists with no backend model of their own, plus one
// pure client-side formatting helper.

// ---------- purpose-of-visit options ----------
export const visitPurposes = [
  'Official Business',
  'Meeting with Host',
  'Job Interview',
  'Delivery',
  'Maintenance',
  'Contractor Work',
  'Personal',
  'Other',
];

// ---------- call types ----------
export const callTypes = ['Incoming', 'Outgoing', 'Missed'];

// Auto-generated badge IDs use a "VIS-YYYY-NNN" format, mirroring the
// pattern the backend itself generates (CodeGenerator.nextBadgeId) —
// used here only for the read-only preview on RegisterVisitorScreen
// before the real badge is assigned server-side.
export const nextBadgeId = (existing: Array<{ badgeId?: string | null }> = []): string => {
  const year = new Date().getFullYear();
  const nums = existing
    .map((v) => v.badgeId || '')
    .filter((id) => id.startsWith(`VIS-${year}-`))
    .map((id) => parseInt(id.split('-')[2], 10))
    .filter((n) => !isNaN(n));
  const next = (nums.length ? Math.max(...nums) : 0) + 1;
  return `VIS-${year}-${String(next).padStart(3, '0')}`;
};
