import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.budgienest.app',
  appName: 'BudgieBreedingTracker',
  webDir: 'dist',
  plugins: {
    LocalNotifications: {
      smallIcon: 'ic_stat_budgie_notification',
      iconColor: '#22C55E',
      sound: 'notification.wav',
      requestPermissions: true,
      scheduleOn: 'trigger'
    },
    SplashScreen: {
      launchShowDuration: 2000,
      backgroundColor: '#22C55E',
      showSpinner: false
    },
    StatusBar: {
      style: 'default',
      backgroundColor: '#22C55E'
    }
  },
  // Security configurations
  android: {
    allowMixedContent: true,
    captureInput: true,
    webContentsDebuggingEnabled: true // Enable for debugging
  },
  ios: {
    contentInset: 'automatic',
    scrollEnabled: true,
    backgroundColor: '#22C55E'
  }
};

export default config;
