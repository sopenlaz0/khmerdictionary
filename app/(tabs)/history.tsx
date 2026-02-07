import { useCallback, useState } from 'react';
import { FlatList, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { router } from 'expo-router';
import { useSQLiteContext } from 'expo-sqlite';

import { WordListItem } from '../../src/components/WordListItem';
import { addToHistory, listHistory, setBookmark } from '../../src/features/dictionary/repository';
import type { WordSummary } from '../../src/features/dictionary/types';

export default function HistoryScreen() {
  const db = useSQLiteContext();
  const [rows, setRows] = useState<WordSummary[]>([]);

  const reload = useCallback(async () => {
    const next = await listHistory(db);
    setRows(next);
  }, [db]);

  useFocusEffect(
    useCallback(() => {
      reload();
    }, [reload])
  );

  const handleOpen = useCallback(
    async (word: WordSummary) => {
      await addToHistory(db, word.id);
      router.push({ pathname: '/word/[id]', params: { id: String(word.id) } });
    },
    [db]
  );

  const handleToggle = useCallback(
    async (word: WordSummary) => {
      await setBookmark(db, word.id, word.isBookmarked);
      await reload();
    },
    [db, reload]
  );

  return (
    <View style={styles.root}>
      <FlatList
        contentContainerStyle={styles.listContent}
        data={rows}
        keyExtractor={(item) => String(item.id)}
        renderItem={({ item }) => <WordListItem word={item} onPress={handleOpen} onToggleBookmark={handleToggle} />}
        ListEmptyComponent={<Text style={styles.empty}>មិនទាន់មានប្រវត្តិការមើល</Text>}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    padding: 14,
    backgroundColor: '#F3F7FC',
  },
  listContent: {
    paddingBottom: 100,
  },
  empty: {
    marginTop: 40,
    textAlign: 'center',
    color: '#52657F',
    fontFamily: 'SuwannaphumRegular',
  },
});
