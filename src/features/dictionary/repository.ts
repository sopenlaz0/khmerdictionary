import { SQLiteDatabase } from 'expo-sqlite';

import { buildPrefixPattern, formatDefinitionPlainText, normalizeSearchTerm } from './search-utils';
import type { WordDetail, WordSummary } from './types';

type RawWordRow = {
  id: number;
  word: string;
  definition: string;
  isBookmarked: number;
};

function toWordSummary(row: RawWordRow): WordSummary {
  return {
    id: row.id,
    word: row.word,
    definition: row.definition,
    previewDefinition: formatDefinitionPlainText(row.definition).replace(/\n+/g, ' ').slice(0, 140),
    isBookmarked: row.isBookmarked === 1,
  };
}

export async function searchWords(
  db: SQLiteDatabase,
  rawSearchTerm: string,
  limit = 90
): Promise<WordSummary[]> {
  const term = normalizeSearchTerm(rawSearchTerm);
  const pattern = buildPrefixPattern(term);
  const rows = await db.getAllAsync<RawWordRow>(
    `
      SELECT
        d.id,
        d.word,
        d.definition,
        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
      FROM dict d
      WHERE d.word LIKE ?
      ORDER BY d.word ASC
      LIMIT ?;
    `,
    [pattern, limit]
  );

  return rows.map(toWordSummary);
}

export async function getWordById(db: SQLiteDatabase, wordId: number): Promise<WordDetail | null> {
  const row = await db.getFirstAsync<RawWordRow>(
    `
      SELECT
        d.id,
        d.word,
        d.definition,
        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
      FROM dict d
      WHERE d.id = ?
      LIMIT 1;
    `,
    [wordId]
  );

  if (!row) {
    return null;
  }

  return {
    id: row.id,
    word: row.word,
    definition: formatDefinitionPlainText(row.definition),
    isBookmarked: row.isBookmarked === 1,
  };
}

export async function listBookmarks(db: SQLiteDatabase, limit = 200): Promise<WordSummary[]> {
  const rows = await db.getAllAsync<RawWordRow>(
    `
      SELECT
        d.id,
        d.word,
        d.definition,
        1 AS isBookmarked
      FROM bookmarks b
      JOIN dict d ON d.id = b.word_id
      ORDER BY d.word ASC
      LIMIT ?;
    `,
    [limit]
  );

  return rows.map(toWordSummary);
}

export async function listHistory(db: SQLiteDatabase, limit = 200): Promise<WordSummary[]> {
  const rows = await db.getAllAsync<RawWordRow>(
    `
      SELECT
        d.id,
        d.word,
        d.definition,
        EXISTS(SELECT 1 FROM bookmarks b WHERE b.word_id = d.id) AS isBookmarked
      FROM history h
      JOIN dict d ON d.id = h.word_id
      ORDER BY h.viewed_at DESC
      LIMIT ?;
    `,
    [limit]
  );

  return rows.map(toWordSummary);
}

export async function setBookmark(
  db: SQLiteDatabase,
  wordId: number,
  isBookmarked: boolean
): Promise<void> {
  if (isBookmarked) {
    await db.runAsync('DELETE FROM bookmarks WHERE word_id = ?', [wordId]);
    return;
  }

  await db.runAsync('INSERT OR REPLACE INTO bookmarks(word_id, created_at) VALUES (?, ?)', [
    wordId,
    Date.now(),
  ]);
}

export async function addToHistory(db: SQLiteDatabase, wordId: number): Promise<void> {
  await db.runAsync(
    `
      INSERT INTO history(word_id, viewed_at)
      VALUES (?, ?)
      ON CONFLICT(word_id)
      DO UPDATE SET viewed_at = excluded.viewed_at;
    `,
    [wordId, Date.now()]
  );
}
