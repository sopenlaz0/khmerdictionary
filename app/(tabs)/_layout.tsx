import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
import { Icon, Label, NativeTabs, VectorIcon } from 'expo-router/unstable-native-tabs';
import type { PlatformOSType } from 'react-native';

import { getSearchUiConfig } from '../../src/features/dictionary/search-presentation';

export default function TabsLayout() {
  const os = (process.env.EXPO_OS ?? 'ios') as PlatformOSType;
  const searchUi = getSearchUiConfig(os);
  const useSystemSearchRole = os === 'ios' && searchUi.nativeTabRole === 'search';

  return (
    <NativeTabs
      backgroundColor="#F7FAFF"
      tintColor="#0A4A8B"
      iconColor={{ default: '#6C7A90', selected: '#0A4A8B' }}
      labelStyle={{ fontFamily: 'SuwannaphumRegular', fontSize: 12 }}
      minimizeBehavior={os === 'ios' ? 'onScrollDown' : undefined}
    >
      <NativeTabs.Trigger name="saved" role={os === 'ios' ? 'bookmarks' : undefined}>
        <Label>ចំណាំ</Label>
        <Icon src={<VectorIcon family={MaterialCommunityIcons} name="bookmark-outline" />} />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="history" role={os === 'ios' ? 'history' : undefined}>
        <Label>ប្រវត្តិ</Label>
        <Icon src={<VectorIcon family={MaterialCommunityIcons} name="history" />} />
      </NativeTabs.Trigger>

      <NativeTabs.Trigger name="index" role={useSystemSearchRole ? 'search' : undefined}>
        <Label>{useSystemSearchRole ? 'Search' : 'វចនានុក្រម'}</Label>
        {!useSystemSearchRole ? (
          <Icon src={<VectorIcon family={MaterialCommunityIcons} name="book-open-page-variant-outline" />} />
        ) : null}
      </NativeTabs.Trigger>
    </NativeTabs>
  );
}
