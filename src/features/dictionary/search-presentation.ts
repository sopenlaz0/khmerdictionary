import type { PlatformOSType } from 'react-native';

type SearchUiConfig = {
  useNativeHeaderSearch: boolean;
  showInlineSearchInput: boolean;
  nativeHeaderPlaceholder: string | null;
  nativeHideWhenScrolling: boolean | null;
  nativeTabRole: 'search' | null;
};

export function getSearchUiConfig(platform: PlatformOSType): SearchUiConfig {
  if (platform === 'ios') {
    return {
      useNativeHeaderSearch: false,
      showInlineSearchInput: true,
      nativeHeaderPlaceholder: null,
      nativeHideWhenScrolling: null,
      nativeTabRole: 'search',
    };
  }

  return {
    useNativeHeaderSearch: false,
    showInlineSearchInput: true,
    nativeHeaderPlaceholder: null,
    nativeHideWhenScrolling: null,
    nativeTabRole: null,
  };
}
