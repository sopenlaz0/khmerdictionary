import { Pressable, StyleSheet, Text, View } from 'react-native';
import { IconButton } from 'react-native-paper';

import type { WordSummary } from '../features/dictionary/types';

type WordListItemProps = {
  word: WordSummary;
  onPress: (word: WordSummary) => void;
  onToggleBookmark: (word: WordSummary) => void;
};

export function WordListItem({ word, onPress, onToggleBookmark }: WordListItemProps) {
  return (
    <Pressable onPress={() => onPress(word)} style={styles.item}>
      <View style={styles.textArea}>
        <Text style={styles.word}>{word.word}</Text>
        <Text numberOfLines={2} style={styles.preview}>
          {word.previewDefinition}
        </Text>
      </View>
      <IconButton
        icon={word.isBookmarked ? 'bookmark' : 'bookmark-outline'}
        iconColor={word.isBookmarked ? '#0A4A8B' : '#6A738A'}
        onPress={() => onToggleBookmark(word)}
      />
    </Pressable>
  );
}

const styles = StyleSheet.create({
  item: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    paddingHorizontal: 12,
    paddingVertical: 10,
    marginBottom: 10,
  },
  textArea: {
    flex: 1,
    paddingRight: 8,
  },
  word: {
    fontFamily: 'SuwannaphumBold',
    color: '#092847',
    fontSize: 17,
    marginBottom: 2,
  },
  preview: {
    color: '#44536D',
    fontFamily: 'SuwannaphumRegular',
    fontSize: 13,
    lineHeight: 18,
  },
});
