package com.visilog.api.dto;

import java.util.List;

// Bulk CSV import result — succeeds row-by-row rather than all-or-
// nothing, so one bad row (a duplicate code, a missing email) doesn't
// block every other valid row in the file. `row` is 1-based against
// the CSV's data rows (the header doesn't count), so it matches what
// the person sees if they open the file in a spreadsheet.
public record BulkImportResult<T>(List<T> created, List<RowError> errors) {
    public record RowError(int row, String message) {
    }
}
