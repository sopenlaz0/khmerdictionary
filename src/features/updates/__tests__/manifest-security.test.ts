import nacl from 'tweetnacl';

import {
  buildManifestSigningPayload,
  isNewerRelease,
  type DatabaseUpdateManifest,
  verifyManifestSignature,
} from '../manifest-security';

const textEncoder = new TextEncoder();

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = Number.parseInt(hex.slice(i, i + 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  let out = '';
  for (const b of bytes) {
    out += b.toString(16).padStart(2, '0');
  }
  return out;
}

function sampleManifest(): DatabaseUpdateManifest {
  return {
    schemaVersion: 1,
    release: {
      versionCode: 2,
      versionName: '2.0.0',
      publishedAt: '2026-02-07T12:00:00.000Z',
    },
    database: {
      url: 'https://cdn.example.com/khmerdict/dict-v2.db',
      sha256: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      sizeBytes: 18432000,
      signatureHex: '',
    },
  };
}

describe('manifest security', () => {
  test('buildManifestSigningPayload is deterministic and complete', () => {
    const manifest = sampleManifest();
    expect(buildManifestSigningPayload(manifest)).toBe(
      [
        '1',
        '2',
        '2.0.0',
        '2026-02-07T12:00:00.000Z',
        'https://cdn.example.com/khmerdict/dict-v2.db',
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        '18432000',
      ].join('\n')
    );
  });

  test('verifyManifestSignature accepts valid signature and rejects tampering', async () => {
    const manifest = sampleManifest();
    const seedHex =
      '1f1e1d1c1b1a19181716151413121110a0a1a2a3a4a5a6a7a8a9aaabacadaeaf';
    const seed = hexToBytes(seedHex);
    const keyPair = nacl.sign.keyPair.fromSeed(seed);
    const payload = buildManifestSigningPayload(manifest);
    const signature = nacl.sign.detached(textEncoder.encode(payload), keyPair.secretKey);
    manifest.database.signatureHex = bytesToHex(signature);

    const isValid = await verifyManifestSignature(
      manifest,
      bytesToHex(keyPair.publicKey)
    );
    expect(isValid).toBe(true);

    const tampered = {
      ...manifest,
      database: { ...manifest.database, url: 'https://evil.example.com/bad.db' },
    };
    const isTamperedValid = await verifyManifestSignature(
      tampered,
      bytesToHex(keyPair.publicKey)
    );
    expect(isTamperedValid).toBe(false);
  });

  test('isNewerRelease compares versionCode safely', () => {
    const manifest = sampleManifest();
    expect(isNewerRelease(manifest, null)).toBe(true);
    expect(isNewerRelease(manifest, 1)).toBe(true);
    expect(isNewerRelease(manifest, 2)).toBe(false);
    expect(isNewerRelease(manifest, 7)).toBe(false);
  });
});
