import React from 'react';
import { View, StyleSheet } from 'react-native';
import Text from './Text';
import Button from './Button';
import { useTheme } from '../theme/ThemeContext';
import { spacing, radius } from '../theme/spacing';

// Chrome for breaking one long form into a few short ones. Two pieces,
// used together but kept separate so a screen can put its own content
// between them:
//
//   <StepProgress steps={[...]} current={step} />
//   ...fields for the current step...
//   <StepNav ... />
//
// Deliberately NOT a wrapper component that owns the step state: the
// screen still decides what "valid enough to continue" means for each
// step, which differs a lot between forms (a booking can't advance
// without a room; Company Setup can skip almost anything).

interface StepProgressProps {
  /** Short labels, one per step, e.g. ['Details', 'People', 'When']. */
  steps: string[];
  /** Zero-based index of the step being shown. */
  current: number;
}

export function StepProgress({ steps, current }: StepProgressProps) {
  const { colors } = useTheme();
  return (
    <View style={styles.progressWrap}>
      <View style={styles.barRow}>
        {steps.map((label, i) => (
          <View
            key={label}
            style={[
              styles.barSegment,
              { backgroundColor: i <= current ? colors.primary : colors.border },
              i > 0 && { marginLeft: 4 },
            ]}
          />
        ))}
      </View>
      <Text variant="caption" color={colors.textSecondary}>
        Step {current + 1} of {steps.length} - {steps[current]}
      </Text>
    </View>
  );
}

interface StepNavProps {
  current: number;
  total: number;
  onBack: () => void;
  onNext: () => void;
  /** Label for the forward button on the LAST step (e.g. 'Book meeting'). */
  finishLabel: string;
  finishIcon?: React.ComponentProps<typeof Button>['icon'];
  loading?: boolean;
}

export function StepNav({
  current,
  total,
  onBack,
  onNext,
  finishLabel,
  finishIcon,
  loading = false,
}: StepNavProps) {
  const isLast = current === total - 1;
  return (
    <View style={styles.navRow}>
      {/* No Back on the first step -- there's nothing behind it, and a
          disabled button there just looks broken. */}
      {current > 0 ? (
        <Button
          label="Back"
          variant="secondary"
          icon="chevron-back"
          onPress={onBack}
          disabled={loading}
          style={{ flex: 1, marginRight: spacing.xs }}
        />
      ) : null}
      <Button
        label={isLast ? finishLabel : 'Next'}
        icon={isLast ? finishIcon : 'chevron-forward'}
        iconPosition="right"
        onPress={onNext}
        loading={loading}
        style={{ flex: 1, marginLeft: current > 0 ? spacing.xs : 0 }}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  progressWrap: { marginBottom: spacing.md },
  barRow: { flexDirection: 'row', marginBottom: 6 },
  barSegment: { flex: 1, height: 4, borderRadius: radius.pill },
  navRow: { flexDirection: 'row', marginTop: spacing.md },
});
