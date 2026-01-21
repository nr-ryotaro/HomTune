const config = {
  appId: 'com.homtune.app',
  appName: 'HomTune',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    iosScheme: 'https',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 2000,
      launchAutoHide: true,
      backgroundColor: '#ffffff',
      androidSplashResourceName: 'splash',
      androidScaleType: 'CENTER_CROP',
      showSpinner: false,
      iosSpinnerStyle: 'small',
      spinnerColor: '#1a1a1a',
    },
    StatusBar: {
      style: 'dark',
      backgroundColor: '#ffffff',
    },
    Camera: {
      permissions: {
        camera: 'HomTuneはデバイスの写真を撮影するためにカメラへのアクセスが必要です。',
        photos: 'HomTuneはデバイスの写真を保存するためにフォトライブラリへのアクセスが必要です。',
      },
    },
  },
};

export default config;
