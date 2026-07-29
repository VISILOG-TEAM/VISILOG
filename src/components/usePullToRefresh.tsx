import React, { useState } from 'react';
import { RefreshControl, type RefreshControlProps } from 'react-native';
import { useData } from '../context/DataContext';
import { useTheme } from '../theme/ThemeContext';

// Pull-to-refresh, wired to reload everything from the API.
//
// Data in this app goes stale constantly and invisibly: a visitor is
// admitted at reception while you're looking at the appointments list,
// a colleague books the room you were about to take. Screens refetch
// when focused, but that does nothing while you're already sitting on
// one -- and "pull down to reload" is the gesture every phone user
// already reaches for.
//
// Two shapes for the two kinds of screen this app has:
//   useRefreshState()   -> { refreshing, onRefresh } for anything that
//                          needs the raw values (Screen, or a list that
//                          also does something of its own).
//   usePullToRefresh()  -> a ready-made <RefreshControl>, for the
//                          screens that render their own FlatList and
//                          just need to drop it into refreshControl.
export function useRefreshState(): { refreshing: boolean; onRefresh: () => void } {
  const { refreshAll } = useData();
  const [refreshing, setRefreshing] = useState(false);

  const onRefresh = (): void => {
    if (refreshing) return;
    setRefreshing(true);
    refreshAll().finally(() => setRefreshing(false));
  };

  return { refreshing, onRefresh };
}

// Typed as ReactElement<RefreshControlProps> rather than a bare
// ReactElement: FlatList/SectionList's refreshControl prop demands that
// exact element type, and a looser return makes every call site fail to
// typecheck.
export function usePullToRefresh(): React.ReactElement<RefreshControlProps> {
  const { colors } = useTheme();
  const { refreshing, onRefresh } = useRefreshState();
  return <RefreshControl refreshing={refreshing} onRefresh={onRefresh} tintColor={colors.primary} />;
}
