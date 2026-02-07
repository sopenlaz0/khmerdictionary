import { CryptoDigestAlgorithm, digest } from 'expo-crypto';

function toHex(bytes: Uint8Array): string {
  let out = '';
  for (const b of bytes) {
    out += b.toString(16).padStart(2, '0');
  }
  return out;
}

export async function sha256Hex(data: Uint8Array): Promise<string> {
  const digestBuffer = await digest(CryptoDigestAlgorithm.SHA256, data as unknown as BufferSource);
  return toHex(new Uint8Array(digestBuffer));
}
