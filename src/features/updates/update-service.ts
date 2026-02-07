import { File, Paths } from 'expo-file-system';
import type { SQLiteDatabase } from 'expo-sqlite';

import { parseManifestOrThrow } from './manifest-parser';
import {
  isNewerRelease,
  type DatabaseUpdateManifest,
  verifyManifestSignature,
} from './manifest-security';
import { sha256Hex } from './hash';
import {
  getUpdateManifestUrl,
  getUpdatePublicKeyHex,
} from './update-config';
import { stageDownloadedDatabase } from './staged-update';

const SHA256_HEX_RE = /^[0-9a-f]{64}$/i;

type CheckUpdateResult =
  | { status: 'missing-config'; message: string }
  | { status: 'up-to-date'; currentVersionCode: number | null; remoteVersionCode: number }
  | { status: 'staged'; remoteVersionCode: number; restartRequired: true }
  | { status: 'error'; message: string };

export async function getCurrentDictionaryVersionCode(db: SQLiteDatabase): Promise<number | null> {
  const row = await db.getFirstAsync<{ value: string }>(
    'SELECT value FROM app_meta WHERE key = ? LIMIT 1',
    ['dictionary_version_code']
  );

  if (!row?.value) {
    return null;
  }

  const code = Number.parseInt(row.value, 10);
  return Number.isFinite(code) ? code : null;
}

export async function setCurrentDictionaryVersionCode(
  db: SQLiteDatabase,
  versionCode: number
): Promise<void> {
  await db.runAsync(
    `
      INSERT INTO app_meta(key, value)
      VALUES (?, ?)
      ON CONFLICT(key)
      DO UPDATE SET value = excluded.value;
    `,
    ['dictionary_version_code', String(versionCode)]
  );
}

async function fetchRemoteManifest(manifestUrl: string): Promise<DatabaseUpdateManifest> {
  const response = await fetch(manifestUrl, {
    method: 'GET',
    headers: { Accept: 'application/json', 'Cache-Control': 'no-cache' },
  });

  if (!response.ok) {
    throw new Error(`Manifest request failed: HTTP ${response.status}`);
  }

  const rawJson = await response.json();
  return parseManifestOrThrow(rawJson);
}

async function downloadAndVerifyDatabase(manifest: DatabaseUpdateManifest): Promise<File> {
  const tempFile = new File(Paths.cache, `dict-${manifest.release.versionCode}.download.db`);
  if (tempFile.exists) {
    tempFile.delete();
  }

  await File.downloadFileAsync(manifest.database.url, tempFile, {
    idempotent: true,
  });

  const bytes = await tempFile.bytes();
  const actualHash = await sha256Hex(bytes);
  if (actualHash !== manifest.database.sha256.toLowerCase()) {
    tempFile.delete();
    throw new Error('Downloaded DB checksum did not match manifest');
  }

  if (manifest.database.sizeBytes > 0 && tempFile.size !== manifest.database.sizeBytes) {
    tempFile.delete();
    throw new Error('Downloaded DB size did not match manifest');
  }

  return tempFile;
}

export async function checkAndStageDatabaseUpdate(db: SQLiteDatabase): Promise<CheckUpdateResult> {
  const manifestUrl = getUpdateManifestUrl();
  const publicKeyHex = getUpdatePublicKeyHex();

  if (!manifestUrl || !publicKeyHex) {
    return {
      status: 'missing-config',
      message: 'Update manifest URL or public key is not configured.',
    };
  }

  if (!SHA256_HEX_RE.test(publicKeyHex) || publicKeyHex.length !== 64) {
    return {
      status: 'missing-config',
      message: 'Configured update public key must be a 64-char hex ed25519 key.',
    };
  }

  try {
    const manifest = await fetchRemoteManifest(manifestUrl);
    const isSignatureValid = await verifyManifestSignature(manifest, publicKeyHex);

    if (!isSignatureValid) {
      return {
        status: 'error',
        message: 'Manifest signature verification failed.',
      };
    }

    const currentVersionCode = await getCurrentDictionaryVersionCode(db);
    if (!isNewerRelease(manifest, currentVersionCode)) {
      return {
        status: 'up-to-date',
        currentVersionCode,
        remoteVersionCode: manifest.release.versionCode,
      };
    }

    const downloaded = await downloadAndVerifyDatabase(manifest);
    stageDownloadedDatabase(manifest, downloaded);

    return {
      status: 'staged',
      remoteVersionCode: manifest.release.versionCode,
      restartRequired: true,
    };
  } catch (error) {
    return {
      status: 'error',
      message: error instanceof Error ? error.message : 'Unexpected update failure',
    };
  }
}
