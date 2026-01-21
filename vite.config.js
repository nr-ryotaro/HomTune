import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  root: './src',
  publicDir: '../public',
  build: {
    outDir: '../dist',
    emptyOutDir: true,
    // モバイルアプリ用の最適化
    minify: 'terser',
    terserOptions: {
      compress: {
        drop_console: false, // デバッグ用にconsoleを残す
      },
    },
  },
  server: {
    port: 5173,
    open: true,
    // モバイルデバイスからのアクセスを許可
    host: true,
  },
  resolve: {
    alias: {
      '@data': resolve(__dirname, 'data'),
    },
  },
  // モバイル向けの最適化
  optimizeDeps: {
    include: ['@capacitor/core', '@capacitor/app'],
  },
});
