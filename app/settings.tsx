import { useCallback, useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';
import { useSQLiteContext } from 'expo-sqlite';
import { Button } from 'react-native-paper';

import { getPendingUpdateVersionCode } from '../src/features/updates/staged-update';
import {
  checkAndStageDatabaseUpdate,
  getCurrentDictionaryVersionCode,
} from '../src/features/updates/update-service';

export default function SettingsScreen() {
  const db = useSQLiteContext();
  const [isChecking, setIsChecking] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [currentVersionCode, setCurrentVersionCode] = useState<number | null>(null);
  const [pendingVersionCode, setPendingVersionCode] = useState<number | null>(null);

  const refreshStatus = useCallback(async () => {
    const currentVersion = await getCurrentDictionaryVersionCode(db);
    setCurrentVersionCode(currentVersion);
    setPendingVersionCode(getPendingUpdateVersionCode());
  }, [db]);

  useEffect(() => {
    refreshStatus();
  }, [refreshStatus]);

  const handleCheckUpdates = useCallback(async () => {
    setIsChecking(true);
    setStatusMessage(null);

    const result = await checkAndStageDatabaseUpdate(db);

    if (result.status === 'missing-config') {
      setStatusMessage(result.message);
    } else if (result.status === 'up-to-date') {
      setStatusMessage('ទិន្នន័យរបស់អ្នកគឺថ្មីបំផុតហើយ។');
    } else if (result.status === 'staged') {
      setStatusMessage('បានទាញយក និងផ្ទៀងផ្ទាត់រួច។ សូមបិទបើកកម្មវិធីឡើងវិញដើម្បីអនុវត្ត update។');
      setPendingVersionCode(result.remoteVersionCode);
    } else {
      setStatusMessage(result.message);
    }

    await refreshStatus();
    setIsChecking(false);
  }, [db, refreshStatus]);

  return (
    <View style={styles.root}>
      <Text style={styles.title}>ការកំណត់</Text>

      <View style={styles.card}>
        <Text style={styles.cardTitle}>Dictionary Updates (Phase 2)</Text>
        <Text style={styles.metaText}>Version ដែលកំពុងប្រើ: {currentVersionCode ?? 'unknown'}</Text>
        <Text style={styles.metaText}>
          Pending update: {pendingVersionCode == null ? 'none' : String(pendingVersionCode)}
        </Text>

        <Button mode="contained" onPress={handleCheckUpdates} disabled={isChecking} style={styles.button}>
          {isChecking ? 'កំពុងពិនិត្យ…' : 'ពិនិត្យ និងទាញយក Update'}
        </Button>

        <Text style={styles.note}>
          Update នឹងត្រូវអនុវត្តនៅពេលបិទបើកកម្មវិធីឡើងវិញ បន្ទាប់ពី signature/hash verification ជោគជ័យ។
        </Text>

        {statusMessage ? <Text style={styles.status}>{statusMessage}</Text> : null}
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    padding: 18,
    backgroundColor: '#F8FBFF',
  },
  title: {
    fontFamily: 'SuwannaphumBold',
    fontSize: 24,
    color: '#123A60',
    marginBottom: 12,
  },
  card: {
    backgroundColor: '#FFFFFF',
    borderRadius: 16,
    padding: 14,
  },
  cardTitle: {
    fontFamily: 'SuwannaphumBold',
    color: '#123A60',
    marginBottom: 6,
  },
  metaText: {
    fontFamily: 'SuwannaphumRegular',
    color: '#425975',
    marginBottom: 4,
  },
  button: {
    marginTop: 10,
    marginBottom: 8,
  },
  note: {
    fontFamily: 'SuwannaphumRegular',
    color: '#58708D',
    fontSize: 12,
    lineHeight: 18,
  },
  status: {
    marginTop: 10,
    fontFamily: 'SuwannaphumRegular',
    color: '#163F66',
  },
});
