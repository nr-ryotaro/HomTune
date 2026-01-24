import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';

/// 機能確認用の開発者設定画面（kDebugMode 時のみ表示）
/// リリース前に削除予定（RELEASE_CHECKLIST.md 参照）
class DevSettingsScreen extends StatelessWidget {
  const DevSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('この画面はデバッグビルドでのみ表示されます。')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '開発者設定',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: const Color(0xFFE5E5E5), height: 0.5),
        ),
      ),
      body: Consumer<ConfigService>(
        builder: (context, config, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    border: Border.all(color: Colors.amber.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '機能確認用設定。リリース前に削除予定です。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'API / ダミーデータ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        '実APIを使用',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Switch(
                      value: config.isUsingRealApi,
                      onChanged: (v) => config.setUseRealApi(v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  config.isUsingRealApi ? '実APIモード' : 'ダミーデータモード',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
