import { SQLiteDatabase } from 'expo-sqlite';

import { BUNDLED_DICTIONARY_VERSION_CODE } from '../updates/update-config';

type InitDatabaseOptions = {
  appliedVersionCode?: number | null;
};

export async function initDatabase(
  db: SQLiteDatabase,
  options: InitDatabaseOptions = {}
): Promise<void> {
  await db.execAsync(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS bookmarks (
      word_id INTEGER PRIMARY KEY,
      created_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS history (
      word_id INTEGER PRIMARY KEY,
      viewed_at INTEGER NOT NULL
    );
    CREATE TABLE IF NOT EXISTS app_meta (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_history_viewed_at ON history(viewed_at DESC);
  `);

  const existingVersion = await db.getFirstAsync<{ value: string }>(
    'SELECT value FROM app_meta WHERE key = ? LIMIT 1',
    ['dictionary_version_code']
  );

  if (!existingVersion) {
    await db.runAsync(
      `INSERT INTO app_meta(key, value) VALUES (?, ?)`,
      ['dictionary_version_code', String(BUNDLED_DICTIONARY_VERSION_CODE)]
    );
  }

  if (options.appliedVersionCode != null) {
    await db.runAsync(
      `
        INSERT INTO app_meta(key, value)
        VALUES (?, ?)
        ON CONFLICT(key)
        DO UPDATE SET value = excluded.value
      `,
      ['dictionary_version_code', String(options.appliedVersionCode)]
    );
  }
}
