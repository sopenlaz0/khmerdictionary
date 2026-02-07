import { getSearchUiConfig } from '../search-presentation';

describe('getSearchUiConfig', () => {
  it('uses iOS native tab search role and inline input on iOS', () => {
    const config = getSearchUiConfig('ios');

    expect(config.useNativeHeaderSearch).toBe(false);
    expect(config.showInlineSearchInput).toBe(true);
    expect(config.nativeHeaderPlaceholder).toBeNull();
    expect(config.nativeHideWhenScrolling).toBeNull();
    expect(config.nativeTabRole).toBe('search');
  });

  it('keeps inline search and no special tab role on Android', () => {
    const config = getSearchUiConfig('android');

    expect(config.useNativeHeaderSearch).toBe(false);
    expect(config.showInlineSearchInput).toBe(true);
    expect(config.nativeHeaderPlaceholder).toBeNull();
    expect(config.nativeHideWhenScrolling).toBeNull();
    expect(config.nativeTabRole).toBeNull();
  });
});
