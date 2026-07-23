import React, { useState } from 'react';
import {
  View, Modal, StyleSheet, Alert, ActivityIndicator, ScrollView,
} from 'react-native';
import * as DocumentPicker from 'expo-document-picker';
import * as FileSystem from 'expo-file-system/legacy';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';
import { parseCsv, csvRowsToRecords } from '../data/csv';
import { ApiError } from '../api/client';
import type { BulkImportResult } from '../types';

interface CsvImportModalProps<T> {
  visible: boolean;
  onClose: () => void;
  title: string;
  columnsHint: string;
  mapRow: (record: Record<string, string>) => T;
  onImport: (rows: T[]) => Promise<BulkImportResult<unknown>>;
}

// CsvImportModal -- bulk-add staff or meeting rooms from a spreadsheet
// export instead of one-at-a-time. The backend still validates every
// row and reports back what failed and why (see EmployeeService/
// MeetingRoomService.bulkCreate) -- a CSV can have typos a single-add
// form would never let through.
export default function CsvImportModal<T>({
  visible, onClose, title, columnsHint, mapRow, onImport,
}: CsvImportModalProps<T>) {
  const { colors } = useTheme();
  const [busy, setBusy] = useState(false);
  const [result, setResult] = useState<BulkImportResult<unknown> | null>(null);

  const onPickFile = async () => {
    let picked: DocumentPicker.DocumentPickerResult;
    try {
      picked = await DocumentPicker.getDocumentAsync({ type: '*/*', copyToCacheDirectory: true });
    } catch {
      Alert.alert('Could not open file picker', 'Please try again.');
      return;
    }
    if (picked.canceled || !picked.assets?.[0]) return;

    setBusy(true);
    try {
      const text = await FileSystem.readAsStringAsync(picked.assets[0].uri, { encoding: 'utf8' });
      const records = csvRowsToRecords(parseCsv(text));
      if (records.length === 0) {
        Alert.alert('Empty file', 'That file has no data rows to import.');
        return;
      }
      const rows = records.map(mapRow);
      const res = await onImport(rows);
      setResult(res);
    } catch (err) {
      const message = err instanceof ApiError ? err.message : 'Check the file is a valid CSV and try again.';
      Alert.alert('Could not import', message);
    } finally {
      setBusy(false);
    }
  };

  const onDoneClose = () => {
    setResult(null);
    onClose();
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onDoneClose}>
      <View style={styles.wrap}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">{title}</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            {columnsHint}
          </Text>

          {result ? (
            <ScrollView style={styles.resultScroll}>
              <Text variant="bodySemibold" color={colors.brand}>
                {result.created.length} added
              </Text>
              {result.errors.length > 0 ? (
                <>
                  <Text variant="bodySemibold" color={colors.status.rejected.solid} style={{ marginTop: spacing.sm }}>
                    {result.errors.length} skipped
                  </Text>
                  {result.errors.map((e) => (
                    <Text key={e.row} variant="caption" color={colors.textSecondary}>
                      Row {e.row}: {e.message}
                    </Text>
                  ))}
                </>
              ) : null}
            </ScrollView>
          ) : busy ? (
            <View style={styles.busyWrap}>
              <ActivityIndicator color={colors.primary} />
            </View>
          ) : (
            <Button label="Choose CSV file" icon="document-attach-outline" onPress={onPickFile} />
          )}

          <Button
            label={result ? 'Done' : 'Cancel'}
            variant="secondary"
            onPress={onDoneClose}
            style={{ marginTop: spacing.sm }}
          />
        </View>
      </View>
    </Modal>
  );
}

const styles = StyleSheet.create({
  wrap: {
    flex: 1, backgroundColor: 'rgba(10,42,29,0.55)',
    alignItems: 'center', justifyContent: 'center', padding: spacing.lg,
  },
  card: {
    width: '100%', maxWidth: 380,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
  resultScroll: { maxHeight: 260 },
  busyWrap: { paddingVertical: spacing.lg, alignItems: 'center' },
});