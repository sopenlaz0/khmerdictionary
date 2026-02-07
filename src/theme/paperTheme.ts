import { Platform } from 'react-native';
import { MD3LightTheme } from 'react-native-paper';

const iosPalette = {
  primary: '#0A4A8B',
  secondary: '#0A6685',
  background: '#EDF4FF',
  surface: '#F7FBFF',
  onSurface: '#0F243D',
};

const androidPalette = {
  primary: '#0B57D0',
  secondary: '#2C6B57',
  background: '#F4F7FC',
  surface: '#FFFFFF',
  onSurface: '#1B1D22',
};

const palette = Platform.OS === 'ios' ? iosPalette : androidPalette;

export const appTheme = {
  ...MD3LightTheme,
  roundness: 18,
  colors: {
    ...MD3LightTheme.colors,
    ...palette,
  },
};
