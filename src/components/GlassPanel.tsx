import { ReactNode } from 'react';
import { Platform, StyleProp, StyleSheet, ViewStyle } from 'react-native';
import { BlurView } from 'expo-blur';
import { Surface } from 'react-native-paper';

type GlassPanelProps = {
  children: ReactNode;
  style?: StyleProp<ViewStyle>;
};

export function GlassPanel({ children, style }: GlassPanelProps) {
  if (Platform.OS === 'ios') {
    return (
      <BlurView intensity={45} tint="light" style={[styles.iosGlass, style]}>
        {children}
      </BlurView>
    );
  }

  return (
    <Surface style={[styles.androidSurface, style]} elevation={2}>
      {children}
    </Surface>
  );
}

const styles = StyleSheet.create({
  iosGlass: {
    borderRadius: 20,
    padding: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: 'rgba(255, 255, 255, 0.7)',
    backgroundColor: 'rgba(255, 255, 255, 0.24)',
  },
  androidSurface: {
    borderRadius: 20,
    padding: 14,
    backgroundColor: '#FFFFFF',
  },
});
