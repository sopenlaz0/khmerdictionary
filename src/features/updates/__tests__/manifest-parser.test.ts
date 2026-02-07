import { parseManifestOrThrow } from '../manifest-parser';

describe('manifest parser', () => {
  test('accepts valid manifest structure', () => {
    const parsed = parseManifestOrThrow({
      schemaVersion: 1,
      release: {
        versionCode: 3,
        versionName: '3.0.0',
        publishedAt: '2026-02-07T12:00:00.000Z',
      },
      database: {
        url: 'https://cdn.example.com/dict-v3.db',
        sha256: '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        sizeBytes: 18399321,
        signatureHex: 'a'.repeat(128),
      },
    });

    expect(parsed.release.versionCode).toBe(3);
  });

  test('rejects malformed hash/signature fields', () => {
    expect(() =>
      parseManifestOrThrow({
        schemaVersion: 1,
        release: {
          versionCode: 3,
          versionName: '3.0.0',
          publishedAt: '2026-02-07T12:00:00.000Z',
        },
        database: {
          url: 'https://cdn.example.com/dict-v3.db',
          sha256: 'not-hex',
          sizeBytes: 18399321,
          signatureHex: 'bad-signature',
        },
      })
    ).toThrow(/sha256/i);
  });
});
