/**
 * Capacitor統合クラス
 * ネイティブ機能へのアクセスを提供
 * Webブラウザでも動作するようにエラーハンドリングを実装
 */

let Capacitor = null;
let App = null;
let StatusBar = null;
let Style = null;
let SplashScreen = null;
let Camera = null;
let Filesystem = null;
let Directory = null;
let Preferences = null;

// Capacitorモジュールを条件付きでインポート
async function loadCapacitorModules() {
  try {
    const capacitorCore = await import('@capacitor/core');
    Capacitor = capacitorCore.Capacitor;
    
    const capacitorApp = await import('@capacitor/app');
    App = capacitorApp.App;
    
    const statusBar = await import('@capacitor/status-bar');
    StatusBar = statusBar.StatusBar;
    Style = statusBar.Style;
    
    const splashScreen = await import('@capacitor/splash-screen');
    SplashScreen = splashScreen.SplashScreen;
    
    const camera = await import('@capacitor/camera');
    Camera = camera.Camera;
    
    const filesystem = await import('@capacitor/filesystem');
    Filesystem = filesystem.Filesystem;
    Directory = filesystem.Directory;
    
    const preferences = await import('@capacitor/preferences');
    Preferences = preferences.Preferences;
    
    return true;
  } catch (error) {
    console.warn('Capacitor modules not available (running in browser):', error.message);
    return false;
  }
}

// モジュールを事前にロード
const capacitorLoaded = loadCapacitorModules();

export class CapacitorService {
  static get isNative() {
    return Capacitor ? Capacitor.isNativePlatform() : false;
  }
  
  static get platform() {
    return Capacitor ? Capacitor.getPlatform() : 'web';
  }

  /**
   * アプリ初期化
   */
  static async initialize() {
    await capacitorLoaded;
    
    if (!Capacitor || !this.isNative) {
      console.log('Running in browser mode - Capacitor features disabled');
      return;
    }
    
    if (this.isNative) {
      // ステータスバーの設定
      try {
        if (StatusBar) {
          await StatusBar.setStyle({ style: Style.Dark });
          await StatusBar.setBackgroundColor({ color: '#ffffff' });
        }
      } catch (error) {
        console.warn('StatusBar not available:', error);
      }

      // スプラッシュスクリーンの設定
      try {
        if (SplashScreen) {
          await SplashScreen.hide();
        }
      } catch (error) {
        console.warn('SplashScreen not available:', error);
      }

      // アプリのバックボタン処理（Android）
      if (this.platform === 'android' && App) {
        App.addListener('backButton', ({ canGoBack }) => {
          if (!canGoBack) {
            App.exitApp();
          } else {
            window.history.back();
          }
        });
      }

      // アプリの状態変更リスナー
      if (App) {
        App.addListener('appStateChange', ({ isActive }) => {
          console.log('App state changed. Is active?', isActive);
        });
      }
    }
  }

  /**
   * カメラで写真を撮影
   */
  static async takePicture() {
    await capacitorLoaded;
    
    if (!Camera) {
      console.warn('Camera not available - running in browser');
      return null;
    }
    try {
      const image = await Camera.getPhoto({
        quality: 90,
        allowEditing: false,
        resultType: 'base64',
      });

      return `data:image/${image.format};base64,${image.base64String}`;
    } catch (error) {
      console.error('Error taking picture:', error);
      return null;
    }
  }

  /**
   * フォトライブラリから画像を選択
   */
  static async pickFromGallery() {
    await capacitorLoaded;
    
    if (!Camera) {
      console.warn('Camera not available - running in browser');
      return null;
    }
    try {
      const image = await Camera.getPhoto({
        quality: 90,
        allowEditing: false,
        resultType: 'base64',
        source: 'photos',
      });

      return `data:image/${image.format};base64,${image.base64String}`;
    } catch (error) {
      console.error('Error picking from gallery:', error);
      return null;
    }
  }

  /**
   * ファイルを保存
   */
  static async saveFile(data, filename, directory = null) {
    await capacitorLoaded;
    
    if (!Filesystem) {
      console.warn('Filesystem not available - running in browser');
      // ブラウザではlocalStorageにフォールバック
      try {
        localStorage.setItem(`file_${filename}`, data);
        return true;
      } catch (error) {
        console.error('Failed to save to localStorage:', error);
        return false;
      }
    }
    try {
      await Filesystem.writeFile({
        path: filename,
        data: data,
        directory: directory || Directory.Data,
      });
      return true;
    } catch (error) {
      console.error('Error saving file:', error);
      return false;
    }
  }

  /**
   * ファイルを読み込み
   */
  static async readFile(filename, directory = null) {
    await capacitorLoaded;
    
    if (!Filesystem) {
      console.warn('Filesystem not available - running in browser');
      // ブラウザではlocalStorageから読み込み
      try {
        return localStorage.getItem(`file_${filename}`);
      } catch (error) {
        console.error('Failed to read from localStorage:', error);
        return null;
      }
    }
    try {
      const result = await Filesystem.readFile({
        path: filename,
        directory: directory || Directory.Data,
      });
      return result.data;
    } catch (error) {
      console.error('Error reading file:', error);
      return null;
    }
  }

  /**
   * データをPreferencesに保存
   */
  static async setPreference(key, value) {
    await capacitorLoaded;
    
    if (!Preferences) {
      // ブラウザではlocalStorageにフォールバック
      localStorage.setItem(key, value);
      return;
    }
    await Preferences.set({ key, value });
  }

  /**
   * Preferencesからデータを取得
   */
  static async getPreference(key) {
    await capacitorLoaded;
    
    if (!Preferences) {
      // ブラウザではlocalStorageから読み込み
      return localStorage.getItem(key);
    }
    const { value } = await Preferences.get({ key });
    return value;
  }

  /**
   * Preferencesからデータを削除
   */
  static async removePreference(key) {
    await capacitorLoaded;
    
    if (!Preferences) {
      // ブラウザではlocalStorageから削除
      localStorage.removeItem(key);
      return;
    }
    await Preferences.remove({ key });
  }
}
