import { Directory, File, Paths } from 'expo-file-system';
import { defaultDatabaseDirectory } from 'expo-sqlite';

import type { DatabaseUpdateManifest } from './manifest-security';
import { DATABASE_NAME } from './update-config';

type PendingUpdate = {
  manifest: DatabaseUpdateManifest;
  stagedAt: string;
};

const updatesDir = new Directory(Paths.document, 'updates');
const stagedDatabase = new File(updatesDir, 'dict.staged.db');
const pendingMetadataFile = new File(updatesDir, 'pending-update.json');

function ensureUpdateDir(): void {
  updatesDir.create({ idempotent: true, intermediates: true });
}

function readPendingMetadata(): PendingUpdate | null {
  if (!pendingMetadataFile.exists) {
    return null;
  }

  try {
    const text = pendingMetadataFile.textSync();
    const parsed = JSON.parse(text) as PendingUpdate;
    if (!parsed?.manifest?.release?.versionCode) {
      return null;
    }
    return parsed;
  } catch {
    return null;
  }
}

function writePendingMetadata(pending: PendingUpdate): void {
  if (pendingMetadataFile.exists) {
    pendingMetadataFile.delete();
  }
  pendingMetadataFile.create({ intermediates: true, overwrite: true });
  pendingMetadataFile.write(JSON.stringify(pending));
}

function clearPendingMetadata(): void {
  if (pendingMetadataFile.exists) {
    pendingMetadataFile.delete();
  }
}

export function getStagedDatabaseFile(): File {
  ensureUpdateDir();
  return stagedDatabase;
}

export function stageDownloadedDatabase(manifest: DatabaseUpdateManifest, downloadedFile: File): void {
  ensureUpdateDir();

  if (stagedDatabase.exists) {
    stagedDatabase.delete();
  }

  downloadedFile.move(stagedDatabase);
  writePendingMetadata({ manifest, stagedAt: new Date().toISOString() });
}

export function getPendingUpdateVersionCode(): number | null {
  const pending = readPendingMetadata();
  return pending?.manifest.release.versionCode ?? null;
}

export function applyPendingDatabaseUpdate(): {
  appliedVersionCode: number | null;
  errorMessage: string | null;
} {
  ensureUpdateDir();

  const pending = readPendingMetadata();
  if (!pending || !stagedDatabase.exists) {
    clearPendingMetadata();
    return { appliedVersionCode: null, errorMessage: null };
  }

  try {
    const targetDatabase = new File(defaultDatabaseDirectory, DATABASE_NAME);
    targetDatabase.parentDirectory.create({ idempotent: true, intermediates: true });
    if (targetDatabase.exists) {
      targetDatabase.delete();
    }

    stagedDatabase.move(targetDatabase);
    clearPendingMetadata();
    return {
      appliedVersionCode: pending.manifest.release.versionCode,
      errorMessage: null,
    };
  } catch (error) {
    return {
      appliedVersionCode: null,
      errorMessage:
        error instanceof Error
          ? `Failed to apply staged update: ${error.message}`
          : 'Failed to apply staged update',
    };
  }
}
