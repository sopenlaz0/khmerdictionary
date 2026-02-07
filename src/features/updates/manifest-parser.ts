import type { DatabaseUpdateManifest } from './manifest-security';

const SHA256_HEX_RE = /^[0-9a-f]{64}$/i;
const SIGNATURE_HEX_RE = /^[0-9a-f]{128}$/i;

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

export function parseManifestOrThrow(raw: unknown): DatabaseUpdateManifest {
  if (!isRecord(raw)) {
    throw new Error('Manifest must be an object');
  }

  if (raw.schemaVersion !== 1) {
    throw new Error('Unsupported schemaVersion');
  }

  if (!isRecord(raw.release)) {
    throw new Error('release must be an object');
  }

  if (!isRecord(raw.database)) {
    throw new Error('database must be an object');
  }

  const versionCode = raw.release.versionCode;
  const versionName = raw.release.versionName;
  const publishedAt = raw.release.publishedAt;

  const url = raw.database.url;
  const sha256 = raw.database.sha256;
  const sizeBytes = raw.database.sizeBytes;
  const signatureHex = raw.database.signatureHex;
  const versionCodeNumber = Number(versionCode);
  const sizeBytesNumber = Number(sizeBytes);

  if (!Number.isInteger(versionCodeNumber) || versionCodeNumber <= 0) {
    throw new Error('release.versionCode must be a positive integer');
  }

  if (typeof versionName !== 'string' || versionName.length === 0) {
    throw new Error('release.versionName must be a non-empty string');
  }

  if (typeof publishedAt !== 'string' || Number.isNaN(Date.parse(publishedAt))) {
    throw new Error('release.publishedAt must be a valid ISO date string');
  }

  if (typeof url !== 'string' || !/^https:\/\//i.test(url)) {
    throw new Error('database.url must be an https URL');
  }

  if (typeof sha256 !== 'string' || !SHA256_HEX_RE.test(sha256)) {
    throw new Error('database.sha256 must be a 64-char hex string');
  }

  if (!Number.isInteger(sizeBytesNumber) || sizeBytesNumber <= 0) {
    throw new Error('database.sizeBytes must be a positive integer');
  }

  if (typeof signatureHex !== 'string' || !SIGNATURE_HEX_RE.test(signatureHex)) {
    throw new Error('database.signatureHex must be a 128-char hex string');
  }

  return {
    schemaVersion: 1,
    release: {
      versionCode: versionCodeNumber,
      versionName,
      publishedAt,
    },
    database: {
      url,
      sha256: sha256.toLowerCase(),
      sizeBytes: sizeBytesNumber,
      signatureHex: signatureHex.toLowerCase(),
    },
  };
}
