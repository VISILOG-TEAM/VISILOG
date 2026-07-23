import React, { useState } from 'react';
import { View, Modal, StyleSheet, Alert } from 'react-native';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

interface ExportModalProps {
  visible: boolean;
  title: string;
  onClose: () => void;
  onExportCsv: () => Promise<void>;
  onExportPdf: () => Promise<void>;
}

// A tiny CSV-or-PDF picker, shared by any screen with a log to export
// (Visitors, Attendance). Both formats hand off to the OS share sheet
// once built -- see src/data/export.ts -- so this only needs to track
// which one is currently running.
export default function ExportModal({ visible, title, onClose, onExportCsv, onExportPdf }: ExportModalProps) {
  const { colors } = useTheme();
  const [busy, setBusy] = useState<'csv' | 'pdf' | null>(null);

  const run = async (kind: 'csv' | 'pdf', fn: () => Promise<void>) => {
    setBusy(kind);
    try {
      await fn();
      onClose();
    } catch (err) {
      Alert.alert('Could not export', err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setBusy(null);
    }
  };

  return (
    <Modal visible={visible} transparent animationType="fade" onRequestClose={onClose}>
      <View style={styles.wrap}>
        <View style={[styles.card, { backgroundColor: colors.surface }]}>
          <Text variant="h3">{title}</Text>
          <Text variant="caption" color={colors.textSecondary} style={{ marginBottom: spacing.md }}>
            Choose a format to share or save.
          </Text>
          <Button
            label="Export as CSV"
            icon="document-text-outline"
            loading={busy === 'csv'}
            disabled={!!busy}
            onPress={() => run('csv', onExportCsv)}
            style={{ marginBottom: spacing.xs }}
          />
          <Button
            label="Export as PDF"
            icon="document-outline"
            variant="secondary"
            loading={busy === 'pdf'}
            disabled={!!busy}
            onPress={() => run('pdf', onExportPdf)}
          />
          <Button
            label="Cancel"
            variant="secondary"
            disabled={!!busy}
            onPress={onClose}
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
    width: '100%', maxWidth: 360,
    borderRadius: radius.lg,
    padding: spacing.lg,
  },
});