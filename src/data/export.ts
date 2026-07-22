// Shared CSV/PDF export helpers -- build a plain column spec once per
// screen, then hand it to exportCsvFile/exportPdfFile. Both write into
// the app's cache dir and hand off to the OS share sheet, so "export"
// always ends in the same save/share/print picker regardless of format.
import * as FileSystem from 'expo-file-system/legacy';
import * as Sharing from 'expo-sharing';
import * as Print from 'expo-print';

export interface ExportColumn<T> {
  header: string;
  get: (item: T) => string;
}

const escapeCsvCell = (value: string): string => {
  const s = value == null ? '' : String(value);
  return /[",\r\n]/.test(s) ? `"${s.replace(/"/g, '""')}"` : s;
};

export const toCsv = <T,>(items: T[], columns: ExportColumn<T>[]): string => {
  const rows = [columns.map((c) => c.header), ...items.map((item) => columns.map((c) => c.get(item)))];
  return rows.map((r) => r.map(escapeCsvCell).join(',')).join('\r\n');
};

const escapeHtml = (value: string): string => {
  const s = value == null ? '' : String(value);
  return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
};

export const toHtmlTable = <T,>(title: string, items: T[], columns: ExportColumn<T>[]): string => {
  const head = columns.map((c) => `<th>${escapeHtml(c.header)}</th>`).join('');
  const body = items
    .map((item) => `<tr>${columns.map((c) => `<td>${escapeHtml(c.get(item))}</td>`).join('')}</tr>`)
    .join('');
  return `<!doctype html>
<html><head><meta charset="utf-8" />
<style>
  body { font-family: -apple-system, Helvetica, Arial, sans-serif; padding: 24px; color: #1A2E22; }
  h1 { font-size: 18px; margin: 0 0 4px; }
  .meta { color: #6B7B71; font-size: 11px; margin-bottom: 16px; }
  table { width: 100%; border-collapse: collapse; font-size: 11px; }
  th, td { border: 1px solid #D8E2DC; padding: 6px 8px; text-align: left; }
  th { background: #F1F5F2; }
</style>
</head><body>
  <h1>${escapeHtml(title)}</h1>
  <div class="meta">${items.length} record${items.length === 1 ? '' : 's'} - generated ${new Date().toLocaleString()}</div>
  <table><thead><tr>${head}</tr></thead><tbody>${body}</tbody></table>
</body></html>`;
};

const shareFile = async (uri: string, mimeType: string): Promise<void> => {
  if (!(await Sharing.isAvailableAsync())) {
    throw new Error('Sharing is not available on this device.');
  }
  await Sharing.shareAsync(uri, { mimeType });
};

export const exportCsvFile = async (filename: string, csv: string): Promise<void> => {
  const uri = FileSystem.cacheDirectory + filename;
  await FileSystem.writeAsStringAsync(uri, csv, { encoding: 'utf8' });
  await shareFile(uri, 'text/csv');
};

export const exportPdfFile = async (filename: string, html: string): Promise<void> => {
  const { uri } = await Print.printToFileAsync({ html });
  const dest = FileSystem.cacheDirectory + filename;
  await FileSystem.copyAsync({ from: uri, to: dest });
  await shareFile(dest, 'application/pdf');
};