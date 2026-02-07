import { useCallback, useEffect, useMemo, useState } from 'react';
import { FlatList, RefreshControl, StyleSheet, Text, View } from 'react-native';
import { LinearGradient } from 'expo-linear-gradient';
import { router } from 'expo-router';
import { Searchbar } from 'react-native-paper';
import { useSQLiteContext } from 'expo-sqlite';
import type { PlatformOSType } from 'react-native';

import { GlassPanel } from '../../src/components/GlassPanel';
import { WordListItem } from '../../src/components/WordListItem';
import { addToHistory, searchWords, setBookmark } from '../../src/features/dictionary/repository';
import { getSearchUiConfig } from '../../src/features/dictionary/search-presentation';
import { useDebouncedValue } from '../../src/shared/hooks/useDebouncedValue';
import type { WordSummary } from '../../src/features/dictionary/types';

export default function HomeScreen() {
  const db = useSQLiteContext();
  const [query, setQuery] = useState('');
  const [rows, setRows] = useState<WordSummary[]>([]);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [errorText, setErrorText] = useState<string | null>(null);
  const debouncedQuery = useDebouncedValue(query, 220);
  const os = (process.env.EXPO_OS ?? 'ios') as PlatformOSType;
  const searchUi = useMemo(() => getSearchUiConfig(os), [os]);

  const load = useCallback(async () => {
    try {
      setErrorText(null);
      const next = await searchWords(db, debouncedQuery);
      setRows(next);
    } catch (error) {
      setErrorText(error instanceof Error ? error.message : 'Unexpected error while loading words.');
    }
  }, [db, debouncedQuery]);

  useEffect(() => {
    load();
  }, [load]);

  const onRefresh = useCallback(async () => {
    setIsRefreshing(true);
    await load();
    setIsRefreshing(false);
  }, [load]);

  const handleToggleBookmark = useCallback(
    async (word: WordSummary) => {
      await setBookmark(db, word.id, word.isBookmarked);
      setRows((current) =>
        current.map((item) =>
          item.id === word.id ? { ...item, isBookmarked: !item.isBookmarked } : item
        )
      );
    },
    [db]
  );

  const handleSelectWord = useCallback(
    async (word: WordSummary) => {
      await addToHistory(db, word.id);
      router.push({ pathname: '/word/[id]', params: { id: String(word.id) } });
    },
    [db]
  );

  const listEmpty = useMemo(
    () => (
      <View style={styles.emptyWrap}>
        <Text style={styles.emptyTitle}>មិនមានលទ្ធផល</Text>
        <Text style={styles.emptySub}>សូមសាកល្បងស្វែងរកដោយពាក្យខ្លី ឬការបញ្ចូលខុសគ្នាបន្តិច។</Text>
      </View>
    ),
    []
  );

  return (
    <LinearGradient colors={['#E9F4FF', '#F8FCFF', '#F3F7FC']} style={styles.root}>
      <View style={styles.bubbleTop} />
      <View style={styles.bubbleBottom} />
      {searchUi.showInlineSearchInput ? (
        <GlassPanel style={styles.searchPanel}>
          <Text style={styles.title}>វចនានុក្រមខ្មែរ</Text>
          <Searchbar
            value={query}
            onChangeText={setQuery}
            placeholder="ស្វែងរកពាក្យ"
            style={styles.searchbar}
            inputStyle={styles.searchInput}
          />
        </GlassPanel>
      ) : null}

      {errorText ? <Text style={styles.errorText}>{errorText}</Text> : null}

      <FlatList
        contentContainerStyle={styles.listContent}
        data={rows}
        keyExtractor={(item) => String(item.id)}
        renderItem={({ item }) => (
          <WordListItem word={item} onPress={handleSelectWord} onToggleBookmark={handleToggleBookmark} />
        )}
        ListEmptyComponent={listEmpty}
        refreshControl={<RefreshControl refreshing={isRefreshing} onRefresh={onRefresh} />}
      />
    </LinearGradient>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    paddingHorizontal: 14,
    paddingTop: 12,
  },
  bubbleTop: {
    position: 'absolute',
    top: -80,
    right: -40,
    width: 220,
    height: 220,
    borderRadius: 999,
    backgroundColor: 'rgba(52, 126, 230, 0.16)',
  },
  bubbleBottom: {
    position: 'absolute',
    bottom: -90,
    left: -50,
    width: 240,
    height: 240,
    borderRadius: 999,
    backgroundColor: 'rgba(35, 177, 170, 0.12)',
  },
  searchPanel: {
    marginBottom: 12,
  },
  title: {
    fontFamily: 'Tacteang',
    color: '#0A4A8B',
    fontSize: 28,
    marginBottom: 8,
  },
  searchbar: {
    backgroundColor: 'rgba(255, 255, 255, 0.92)',
    borderRadius: 14,
  },
  searchInput: {
    fontFamily: 'SuwannaphumRegular',
    fontSize: 15,
  },
  listContent: {
    paddingBottom: 120,
  },
  errorText: {
    marginBottom: 8,
    color: '#B3261E',
    fontFamily: 'SuwannaphumRegular',
  },
  emptyWrap: {
    marginTop: 36,
    alignItems: 'center',
  },
  emptyTitle: {
    fontFamily: 'SuwannaphumBold',
    color: '#243C56',
    fontSize: 18,
  },
  emptySub: {
    marginTop: 6,
    textAlign: 'center',
    color: '#486280',
    fontFamily: 'SuwannaphumRegular',
  },
});
