import Constants from 'expo-constants';

export const BUNDLED_DICTIONARY_VERSION_CODE = 1;
export const DATABASE_NAME = 'dict.db';

type UpdateExtraConfig = {
  updates?: {
    manifestUrl?: string;
    publicKeyHex?: string;
  };
};

function getUpdatesExtra(): UpdateExtraConfig['updates'] {
  const extra = (Constants.expoConfig?.extra ?? {}) as UpdateExtraConfig;
  return extra.updates;
}

export function getUpdateManifestUrl(): string | null {
  const url = getUpdatesExtra()?.manifestUrl?.trim();
  return url ? url : null;
}

export function getUpdatePublicKeyHex(): string | null {
  const key = getUpdatesExtra()?.publicKeyHex?.trim().toLowerCase();
  return key ? key : null;
}
