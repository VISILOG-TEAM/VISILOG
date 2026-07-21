// Minimal CSV parsing for bulk-import (staff roster, meeting rooms).
// Handles quoted fields (with "" escaping and embedded commas/
// newlines) and both \r\n and \n line endings — not a full RFC 4180
// implementation, but enough for the plain exports a spreadsheet
// produces.

export function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  const s = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

  while (i < s.length) {
    const c = s[i];
    if (inQuotes) {
      if (c === '"') {
        if (s[i + 1] === '"') { field += '"'; i += 2; continue; }
        inQuotes = false; i += 1; continue;
      }
      field += c; i += 1; continue;
    }
    if (c === '"') { inQuotes = true; i += 1; continue; }
    if (c === ',') { row.push(field); field = ''; i += 1; continue; }
    if (c === '\n') { row.push(field); rows.push(row); row = []; field = ''; i += 1; continue; }
    field += c; i += 1;
  }
  row.push(field);
  rows.push(row);

  return rows.filter((r) => r.length > 1 || r[0].trim() !== '');
}

// Turns parsed rows (first row = header) into case-insensitive
// header→value maps, one per data row — so callers can look up
// `record['email']` regardless of how the header was capitalized.
export function csvRowsToRecords(rows: string[][]): Record<string, string>[] {
  if (rows.length === 0) return [];
  const headers = rows[0].map((h) => h.trim().toLowerCase());
  return rows.slice(1).map((r) => {
    const record: Record<string, string> = {};
    headers.forEach((h, i) => { record[h] = (r[i] || '').trim(); });
    return record;
  });
}
