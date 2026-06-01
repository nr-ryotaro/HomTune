import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/onboarding_prefs.dart';
import 'onboarding_screen.dart';

/// 機能確認用の開発者設定画面（kDebugMode 時のみ表示）
/// リリース前に削除予定（RELEASE_CHECKLIST.md 参照）
class DevSettingsScreen extends StatefulWidget {
  const DevSettingsScreen({super.key});

  @override
  State<DevSettingsScreen> createState() => _DevSettingsScreenState();
}

class _DevSettingsScreenState extends State<DevSettingsScreen> {
  bool _showOnboardingOnLaunch = false;
  bool _onboardingPrefsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadOnboardingPrefs();
  }

  Future<void> _loadOnboardingPrefs() async {
    final enabled = await OnboardingPrefs.isShowOnLaunchEnabled();
    if (!mounted) return;
    setState(() {
      _showOnboardingOnLaunch = enabled;
      _onboardingPrefsLoaded = true;
    });
  }

  Future<void> _setShowOnboardingOnLaunch(bool value) async {
    await OnboardingPrefs.setShowOnLaunch(value);
    if (!mounted) return;
    setState(() => _showOnboardingOnLaunch = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? '次回起動時に初回LPを表示します。'
              : '次回起動時の初回LP表示をオフにしました。',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _openOnboardingPreview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => OnboardingScreen(
          key: ValueKey<int>(DateTime.now().millisecondsSinceEpoch),
          isPreview: true,
        ),
      ),
    );
  }

  /// Gemini API キーが設定されているかどうか
  static bool get _hasGeminiApiKey {
    const key = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    return key.isNotEmpty;
  }

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
          final isRealApi = config.isUsingRealApi;
          final hasKey = _hasGeminiApiKey;

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

                // --- API / ダミーデータ切り替え ---
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
                      value: isRealApi,
                      onChanged: (v) => config.setUseRealApi(v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // モード表示
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isRealApi
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isRealApi
                          ? const Color(0xFF86EFAC)
                          : const Color(0xFFE5E5E5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isRealApi
                                ? Icons.cloud_done_rounded
                                : Icons.science_rounded,
                            size: 18,
                            color: isRealApi
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF666666),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isRealApi ? '実APIモード' : 'ダミーデータモード',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isRealApi
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildStatusRow(
                        'Gemini API キー',
                        hasKey ? '設定済み ✓' : '未設定',
                        hasKey,
                      ),
                      _buildStatusRow(
                        'AI チャット',
                        isRealApi && hasKey
                            ? 'Gemini API (マルチターン)'
                            : 'ローカル応答 (テンプレート)',
                        isRealApi && hasKey,
                      ),
                      _buildStatusRow(
                        'スマートスキャン OCR',
                        isRealApi && hasKey ? 'Gemini 構造化抽出' : 'ダミーパーサー',
                        isRealApi && hasKey,
                      ),
                      _buildStatusRow(
                        'リコールチェック',
                        'モックデータ (safety-mock-data.json)',
                        false,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- アプリの挙動設定 ---
                const Text(
                  'アプリの挙動設定',
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '詳細メンテナンスモード',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            config.useDetailedMaintenance
                                ? 'ON: パーツごとに個別に完了記録'
                                : 'OFF (ずぼらモード): デバイス単位で一括記録',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: config.useDetailedMaintenance,
                      onChanged: (v) => config.setUseDetailedMaintenance(v),
                    ),
                  ],
                ),

                // API キーが未設定の場合のヒント
                if (!hasKey) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Text(
                      '💡 Gemini API を有効にするには:\n'
                      'flutter run --dart-define=GEMINI_API_KEY=your_key',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF92400E),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                const Text(
                  '初回LP（オンボーディング）',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '次回起動時に初回LPを表示',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text(
                            'ON: 完了済みでも次回起動でLPを操作できます',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _showOnboardingOnLaunch,
                      onChanged: _onboardingPrefsLoaded
                          ? _setShowOnboardingOnLaunch
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _openOnboardingPreview,
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: const Text('今すぐ初回LPを確認'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // --- テスト用操作 ---
                const Text(
                  'テスト用操作',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    config.setUseRealApi(!isRealApi);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          !isRealApi
                              ? '実APIモードに切り替えました。チャットがGemini応答になります。'
                              : 'ダミーモードに切り替えました。チャットがローカル応答になります。',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(
                    isRealApi ? 'ダミーモードに切り替え' : '実APIモードに切り替え',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF333333),
                    side: const BorderSide(color: Color(0xFFE5E5E5)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
