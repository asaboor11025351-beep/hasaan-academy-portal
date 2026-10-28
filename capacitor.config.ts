import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'pk.hasaanacademy.portal',
  appName: 'HASAAN Academy',
  webDir: 'dist',
  bundledWebRuntime: false,
  plugins: {
    StatusBar: { backgroundColor: '#12396b', style: 'LIGHT' }
  },
  server: {
    // For production, leave this unset so the Android app uses bundled web assets.
    // Do not set cleartext traffic or a remote development URL for production builds.
  }
};
export default config;
