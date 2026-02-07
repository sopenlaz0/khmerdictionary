import nacl from 'tweetnacl';

export type DatabaseUpdateManifest = {
  schemaVersion: 1;
  release: {
    versionCode: number;
    versionName: string;
    publishedAt: string;
  };
  database: {
    url: string;
    sha256: string;
    sizeBytes: number;
    signatureHex: string;
  };
};

function hexToBytes(hex: string): Uint8Array {
  if (hex.length % 2 !== 0) {
    throw new Error('hex string must have an even length');
  }
  const normalized = hex.toLowerCase();
  if (!/^[0-9a-f]+$/.test(normalized)) {
    throw new Error('invalid hex string');
  }

  const bytes = new Uint8Array(normalized.length / 2);
  for (let i = 0; i < normalized.length; i += 2) {
    bytes[i / 2] = Number.parseInt(normalized.slice(i, i + 2), 16);
  }

  return bytes;
}

export function buildManifestSigningPayload(manifest: DatabaseUpdateManifest): string {
  return [
    String(manifest.schemaVersion),
    String(manifest.release.versionCode),
    manifest.release.versionName,
    manifest.release.publishedAt,
    manifest.database.url,
    manifest.database.sha256.toLowerCase(),
    String(manifest.database.sizeBytes),
  ].join('\n');
}

export async function verifyManifestSignature(
  manifest: DatabaseUpdateManifest,
  publicKeyHex: string
): Promise<boolean> {
  try {
    const payload = buildManifestSigningPayload(manifest);
    const signatureBytes = hexToBytes(manifest.database.signatureHex);
    const publicKeyBytes = hexToBytes(publicKeyHex);
    if (signatureBytes.length !== 64 || publicKeyBytes.length !== 32) {
      return false;
    }

    return nacl.sign.detached.verify(
      new TextEncoder().encode(payload),
      signatureBytes,
      publicKeyBytes
    );
  } catch {
    return false;
  }
}

export function isNewerRelease(
  manifest: Pick<DatabaseUpdateManifest, 'release'>,
  currentVersionCode: number | null
): boolean {
  if (currentVersionCode == null) {
    return true;
  }

  return manifest.release.versionCode > currentVersionCode;
}
