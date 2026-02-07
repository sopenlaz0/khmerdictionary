import { useCallback, useEffect, useState } from 'react';
import { ScrollView, StyleSheet, Text, View } from 'react-native';
import { useLocalSearchParams } from 'expo-router';
import { Button } from 'react-native-paper';
import { useSQLiteContext } from 'expo-sqlite';

import { getWordById, setBookmark } from '../../src/features/dictionary/repository';
import type { WordDetail } from '../../src/features/dictionary/types';

export default function WordDetailScreen() {
  const db = useSQLiteContext();
  const params = useLocalSearchParams<{ id?: string }>();
  const wordId = Number(params.id);
  const [word, setWord] = useState<WordDetail | null>(null);

  const loadWord = useCallback(async () => {
    if (!Number.isFinite(wordId) || wordId <= 0) {
      setWord(null);
      return;
    }

    const detail = await getWordById(db, wordId);
    setWord(detail);
  }, [db, wordId]);

  useEffect(() => {
    loadWord();
  }, [loadWord]);

  const toggleBookmark = useCallback(async () => {
    if (!word) return;
    await setBookmark(db, word.id, word.isBookmarked);
    setWord({ ...word, isBookmarked: !word.isBookmarked });
  }, [db, word]);

  if (!word) {
    return (
      <View style={styles.emptyRoot}>
        <Text style={styles.emptyText}>មិនមានពាក្យនេះទេ</Text>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.root}>
      <Text style={styles.word}>{word.word}</Text>
      <Button
        icon={word.isBookmarked ? 'bookmark' : 'bookmark-outline'}
        mode="outlined"
        onPress={toggleBookmark}
        style={styles.bookmarkButton}
      >
        {word.isBookmarked ? 'បានចំណាំ' : 'ចំណាំ'}
      </Button>
      <Text style={styles.definition}>{word.definition}</Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  root: {
    padding: 18,
    backgroundColor: '#F8FBFF',
  },
  word: {
    fontFamily: 'SuwannaphumBold',
    fontSize: 28,
    color: '#0A2E52',
    marginBottom: 10,
  },
  bookmarkButton: {
    alignSelf: 'flex-start',
    marginBottom: 16,
  },
  definition: {
    fontFamily: 'SuwannaphumRegular',
    fontSize: 17,
    lineHeight: 30,
    color: '#243D5A',
  },
  emptyRoot: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#F8FBFF',
  },
  emptyText: {
    fontFamily: 'SuwannaphumRegular',
    color: '#5B6B80',
  },
});
