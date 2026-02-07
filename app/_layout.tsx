import { useEffect, useState } from 'react';
import { StatusBar } from 'expo-status-bar';
import { Stack } from 'expo-router';
import { useFonts } from 'expo-font';
import { ActivityIndicator, StyleSheet, Text, View } from 'react-native';
import { PaperProvider } from 'react-native-paper';
import { SQLiteProvider } from 'expo-sqlite';

import { initDatabase } from '../src/features/dictionary/database';
import { applyPendingDatabaseUpdate } from '../src/features/updates/staged-update';
import { appTheme } from '../src/theme/paperTheme';

export default function RootLayout() {
  const [fontsLoaded] = useFonts({
    SuwannaphumRegular: require('../assets/fonts/suwannaphum_regular.ttf'),
    SuwannaphumBold: require('../assets/fonts/suwannaphum_bold.ttf'),
    SuwannaphumLight: require('../assets/fonts/suwannaphum_light.ttf'),
    Tacteang: require('../assets/fonts/tacteing.ttf'),
  });

  const [bootstrapResult, setBootstrapResult] = useState<{
    appliedVersionCode: number | null;
    errorMessage: string | null;
  } | null>(null);

  useEffect(() => {
    if (!fontsLoaded) return;
    setBootstrapResult(applyPendingDatabaseUpdate());
  }, [fontsLoaded]);

  if (!fontsLoaded || !bootstrapResult) {
    return (
      <View style={styles.loadingRoot}>
        <ActivityIndicator size="large" color="#0A4A8B" />
      </View>
    );
  }

  return (
    <PaperProvider theme={appTheme}>
      <SQLiteProvider
        databaseName="dict.db"
        assetSource={{ assetId: require('../assets/data/dict.db') }}
        onInit={(db) =>
          initDatabase(db, {
            appliedVersionCode: bootstrapResult?.appliedVersionCode ?? null,
          })
        }
      >
        <StatusBar style="dark" />
        {bootstrapResult?.errorMessage ? (
          <View style={styles.bootstrapErrorWrap}>
            <Text style={styles.bootstrapErrorText}>{bootstrapResult.errorMessage}</Text>
          </View>
        ) : null}
        <Stack
          screenOptions={{
            headerShadowVisible: false,
            headerTitleStyle: { fontFamily: 'SuwannaphumBold' },
          }}
        >
          <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
          <Stack.Screen name="word/[id]" options={{ title: 'ពន្យល់ន័យ' }} />
          <Stack.Screen name="settings" options={{ title: 'ការកំណត់' }} />
        </Stack>
      </SQLiteProvider>
    </PaperProvider>
  );
}

const styles = StyleSheet.create({
  loadingRoot: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#EEF4FF',
  },
  bootstrapErrorWrap: {
    backgroundColor: '#FDECEC',
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  bootstrapErrorText: {
    color: '#8A1C1C',
    fontFamily: 'SuwannaphumRegular',
    fontSize: 12,
  },
});
