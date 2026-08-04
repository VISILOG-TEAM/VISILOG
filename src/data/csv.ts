// Minimal CSV parsing for bulk-import (staff roster, meeting rooms).
// Handles quoted fields (with "" escaping and embedded commas/
// newlines) and both \r\n and \n line endings -- not a full RFC 4180
// implementation, but enough for the plain exports a spreadsheet
// produces.

// Which character actually separates the columns. Excel writes
// semicolons in a lot of European locales, "Save as tab-delimited"
// writes tabs, and some exports use pipes -- all of which used to parse
// as ONE giant column, so every row arrived with no recognisable fields
// and the import rejected the entire file. Picks whichever candidate
// appears most often on the header line.
function detectDelimiter(headerLine: string): string {
  const candidates = [',', ';', '\t', '|'];
  let best = ',';
  let bestCount = 0;
  candidates.forEach((c) => {
    const count = headerLine.split(c).length - 1;
    if (count > bestCount) {
      best = c;
      bestCount = count;
    }
  });
  return best;
}

export function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let inQuotes = false;
  let i = 0;
  const s = text
    // A UTF-8 BOM is invisible but glues itself to the first header,
    // turning "code" into a key nothing matches. Excel adds one by
    // default, so this is the single most likely reason a perfectly
    // good file imports zero rows.
    .replace(/^\uFEFF/, '')
    .replace(/\r\n/g, '\n')
    .replace(/\r/g, '\n');
  const delimiter = detectDelimiter(s.split('\n')[0] || '');

  while (i < s.length) {
    const c = s[i];
    if (inQuotes) {
      if (c === '"') {
        if (s[i + 1] === '"') {
          field += '"';
          i += 2;
          continue;
        }
        inQuotes = false;
        i += 1;
        continue;
      }
      field += c;
      i += 1;
      continue;
    }
    if (c === '"') {
      inQuotes = true;
      i += 1;
      continue;
    }
    if (c === delimiter) {
      row.push(field);
      field = '';
      i += 1;
      continue;
    }
    if (c === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
      i += 1;
      continue;
    }
    field += c;
    i += 1;
  }
  row.push(field);
  rows.push(row);

  return rows.filter((r) => r.length > 1 || r[0].trim() !== '');
}

// Turns parsed rows (first row = header) into case-insensitive
// header - value maps, one per data row -- so callers can look up
// `record['email']` regardless of how the header was capitalized.
//
// `rows` is typed string[][] but an Excel sheet doesn't actually
// guarantee that: XLSX.utils.sheet_to_json returns whatever type each
// cell actually holds (numbers for a numeric-formatted capacity or
// phone column, even Dates), not strings coerced from the display
// text. Calling .trim() directly on one of those threw
// "r[i].trim is not a function" and rejected the whole import --
// String(...) first handles every cell type instead of just the ones
// a hand-typed CSV happens to produce.
export function csvRowsToRecords(rows: unknown[][]): Record<string, string>[] {
  if (rows.length === 0) return [];
  const headers = rows[0].map((h) => String(h ?? '').trim().toLowerCase());
  return rows.slice(1).map((r) => {
    const record: Record<string, string> = {};
    headers.forEach((h, i) => {
      const value = String(r[i] ?? '').trim();
      record[h] = value;
      // Also stored under a squashed key, so a caller can look up
      // 'employeeid' and match a column headed "Employee ID",
      // "employee_id" or "Employee-Id" without listing every spelling.
      const squashed = h.replace(/[^a-z0-9]/g, '');
      if (squashed && !(squashed in record)) record[squashed] = value;
    });
    return record;
  });
}
