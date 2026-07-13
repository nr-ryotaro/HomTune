import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/ai_usage_policy.dart';
import '../models/cloud_connection_test_result.dart';
import '../services/ai_usage_service.dart';
import '../services/billing_control_service.dart';
import '../services/config_service.dart';
import '../services/onboarding_prefs.dart';
import 'onboarding_screen.dart';
import 'remote_account_screen.dart';
import 'remote_control_preview_screen.dart';

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
  final TextEditingController _actualCostController =
      TextEditingController(text: '1.20');
  final TextEditingController _proUsersController =
      TextEditingController(text: '120');
  final TextEditingController _fxController =
      TextEditingController(text: '155');
  bool _isAutoTuning = false;
  bool _isConnectionTesting = false;
  bool _isSavingCloud = false;
  BillingAutoTuneResult? _lastTuneResult;
  AiUsagePolicy? _effectivePolicy;

  @override
  void initState() {
    super.initState();
    _loadOnboardingPrefs();
    _loadEffectivePolicy();
  }

  @override
  void dispose() {
    _actualCostController.dispose();
    _proUsersController.dispose();
    _fxController.dispose();
    super.dispose();
  }

  Future<void> _loadOnboardingPrefs() async {
    final enabled = await OnboardingPrefs.isShowOnLaunchEnabled();
    if (!mounted) return;
    setState(() {
      _showOnboardingOnLaunch = enabled;
      _onboardingPrefsLoaded = true;
    });
  }

  Future<void> _loadEffectivePolicy() async {
    final policy = await AiUsageService.instance.getEffectivePolicy();
    if (!mounted) return;
    setState(() => _effectivePolicy = policy);
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

  Future<void> _runBillingAutoTune() async {
    final actualCost = double.tryParse(_actualCostController.text.trim());
    final proUsers = int.tryParse(_proUsersController.text.trim());
    final fx = double.tryParse(_fxController.text.trim());
    if (actualCost == null || proUsers == null || fx == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('入力値が不正です。数値を確認してください。')),
      );
      return;
    }
    setState(() => _isAutoTuning = true);
    try {
      final result = await BillingControlService().autoTuneFromActualBilling(
        actualCostUsd: actualCost,
        proSubscriberCount: proUsers,
        fxJpyPerUsd: fx,
      );
      final policy = await AiUsageService.instance.getEffectivePolicy();
      if (!mounted) return;
      setState(() {
        _lastTuneResult = result;
        _effectivePolicy = policy;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('実請求ベースの自動調整を適用しました。')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('自動調整に失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAutoTuning = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// テスト用: Free/Pro 表示の切り替え（リリース前に削除）
  Widget _buildPlanTestSection(ConfigService config) {
    final tier = config.subscriptionTier;
    final isPro = tier == SubscriptionTier.pro;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.science_outlined, size: 20, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'プラン切替（表示確認・テスト用）',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '広告・Pro機能（相場DB/AI相場・AI枠）の見え方を確認できます。'
            'ホームに戻ると反映されます。',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          SegmentedButton<SubscriptionTier>(
            segments: const [
              ButtonSegment(
                value: SubscriptionTier.free,
                label: Text('Free'),
                icon: Icon(Icons.ads_click_outlined, size: 18),
              ),
              ButtonSegment(
                value: SubscriptionTier.pro,
                label: Text('Pro'),
                icon: Icon(Icons.workspace_premium_outlined, size: 18),
              ),
            ],
            selected: {tier},
            onSelectionChanged: (selected) async {
              final next = selected.first;
              await config.setSubscriptionTier(next);
              if (!mounted) return;
              _showSnack(
                next == SubscriptionTier.pro
                    ? 'Pro に切り替えました（広告非表示・Pro機能ON）'
                    : 'Free に切り替えました（下部バナー表示）',
              );
            },
          ),
          const SizedBox(height: 12),
          _planPreviewRow(
            label: '下部バナー広告',
            value: isPro ? '非表示' : '表示（ホーム・一覧）',
            active: !isPro,
          ),
          _planPreviewRow(
            label: '相場DB / AI相場（L1・L2）',
            value: isPro ? '利用可' : 'Freeでは不可',
            active: isPro,
          ),
          _planPreviewRow(
            label: '月間AIクレジット上限',
            value: isPro ? '120（Pro）' : '40（Free）',
            active: true,
          ),
          _planPreviewRow(
            label: 'スマートリモコン（Remo/SwitchBot）',
            value: isPro ? '連携・操作可' : 'Pro限定',
            active: isPro,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemoteAccountScreen(),
                ),
              );
            },
            icon: const Icon(Icons.sensors, size: 18),
            label: const Text('スマートリモコン連携を開く'),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemoteControlPreviewScreen(),
                ),
              );
            },
            icon: const Icon(Icons.preview_outlined, size: 18),
            label: const Text('リモコン UI プレビュー'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planPreviewRow({
    required String label,
    required String value,
    required bool active,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            active ? Icons.check_circle_outline : Icons.remove_circle_outline,
            size: 16,
            color: active ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _withCloudBusyOverlay(Future<void> Function() action) async {
    if (_isSavingCloud || _isConnectionTesting) return;
    setState(() => _isSavingCloud = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _isSavingCloud = false);
    }
  }

  Future<void> _pasteCloudCredentialFromClipboard(ConfigService config) async {
    if (_isSavingCloud) return;
    try {
      final data = await Clipboard.getData('text/plain');
      if (!mounted) return;
      final text = data?.text?.trim() ?? '';
      if (text.isEmpty) {
        _showSnack('クリップボードに接続シークレットがありません。');
        return;
      }
      await _saveCloudConnectionOnly(
        config: config,
        secret: text,
        profile: config.geminiModel,
      );
    } catch (e) {
      _showSnack('貼り付けに失敗しました: $e');
    }
  }

  Future<bool> _saveCloudConnectionOnly({
    required ConfigService config,
    required String secret,
    required String profile,
  }) async {
    final trimmedSecret = config.resolveCloudSecretInput(secret);
    final trimmedProfile = profile.trim().isEmpty
        ? 'gemini-2.5-flash'
        : profile.trim();
    if (trimmedSecret.isEmpty) {
      _showSnack('接続シークレットを入力してください。');
      return false;
    }

    await _withCloudBusyOverlay(() async {
      try {
        final saved = await config.setCloudConnection(
          secret: trimmedSecret,
          profile: trimmedProfile,
        );
        if (!mounted) return;
        if (saved) {
          _showSnack(
            '接続情報を保存しました。続けて「接続テスト実行」を押してください。',
          );
        } else {
          _showSnack('保存に失敗しました。');
        }
      } catch (e) {
        _showSnack('保存中にエラーが発生しました: $e');
      }
    });
    return config.hasGeminiApiKey;
  }

  Future<void> _openCloudCredentialDialog(ConfigService config) async {
    if (_isSavingCloud) return;
    final alreadyRegistered = config.hasGeminiApiKey;
    final secretController = TextEditingController(
      text: alreadyRegistered ? config.cloudSecretMaskedSummary : '',
    );
    final profileController = TextEditingController(text: config.geminiModel);
    var secret = '';
    var profile = config.geminiModel;

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          var secretLocked = alreadyRegistered;
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('接続情報を更新'),
                content: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (alreadyRegistered) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 18,
                                  color: Color(0xFF16A34A),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '接続シークレットは登録済みです',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: secretController,
                          obscureText: !secretLocked,
                          readOnly: secretLocked,
                          autocorrect: false,
                          enableSuggestions: false,
                          keyboardType: TextInputType.visiblePassword,
                          decoration: InputDecoration(
                            labelText: '接続シークレット',
                            hintText:
                                secretLocked ? null : 'APIキーを貼り付け',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            suffixIcon: secretLocked
                                ? IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 20,
                                    ),
                                    tooltip: 'キーを変更',
                                    onPressed: () {
                                      secretController.clear();
                                      setDialogState(() => secretLocked = false);
                                    },
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: profileController,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: const InputDecoration(
                            labelText: '推論プロファイル',
                            hintText: 'gemini-2.5-flash',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          alreadyRegistered
                              ? 'そのまま保存で登録済みキーを維持します。変更時は鉛筆アイコンを押してください。'
                              : '保存後に「接続テスト実行」で確認してください。',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF666666),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('キャンセル'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('保存'),
                  ),
                ],
              );
            },
          );
        },
      );
      if (confirmed != true) return;

      secret = config.resolveCloudSecretInput(secretController.text);
      profile = profileController.text.trim();
    } catch (e) {
      _showSnack('入力画面の表示に失敗しました: $e');
      return;
    } finally {
      secretController.dispose();
      profileController.dispose();
    }

    if (secret.isEmpty) {
      _showSnack('接続シークレットを入力してください。');
      return;
    }

    await _saveCloudConnectionOnly(
      config: config,
      secret: secret,
      profile: profile,
    );
  }

  Future<void> _handleCloudInferenceToggle(
    ConfigService config,
    bool nextValue,
  ) async {
    if (!config.canUseClientSideGemini && nextValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(config.cloudInferenceBlockedReason)),
      );
      return;
    }
    if (!nextValue) {
      await config.setUseRealApi(false);
      return;
    }
    if (!config.hasGeminiApiKey) {
      await _openCloudCredentialDialog(config);
      if (!mounted) return;
      if (!config.hasGeminiApiKey) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(config.cloudInferenceBlockedReason)),
        );
        await config.setUseRealApi(false);
        return;
      }
    }

    await _runCloudConnectionTest(config, enableCloudOnSuccess: true);
  }

  Future<void> _runCloudConnectionTest(
    ConfigService config, {
    bool enableCloudOnSuccess = false,
  }) async {
    if (_isConnectionTesting || _isSavingCloud) return;

    if (!config.canUseClientSideGemini) {
      _showSnack(config.cloudInferenceBlockedReason);
      return;
    }
    if (!config.hasGeminiApiKey) {
      _showSnack('接続情報が未登録です。先に接続情報を登録してください。');
      return;
    }

    setState(() => _isConnectionTesting = true);
    try {
      CloudConnectionTestResult result;
      try {
        result = await config.testCloudConnection();
      } catch (e) {
        result = CloudConnectionTestResult(
          success: false,
          modelId: '',
          message: e.toString(),
        );
      }
      if (!mounted) return;
      if (result.success) {
        await config.setGeminiModel(result.modelId);
        if (enableCloudOnSuccess) {
          await config.setUseRealApi(true);
        }
        _showSnack(
          enableCloudOnSuccess
              ? 'クラウド推論を有効化しました（${result.modelId}）'
              : '接続テスト成功: ${result.modelId}',
        );
      } else {
        if (enableCloudOnSuccess) {
          await config.setUseRealApi(false);
        }
        _showSnack(
          enableCloudOnSuccess
              ? 'クラウド推論を有効化できません: ${result.message}'
              : '接続テスト失敗: ${result.message}',
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectionTesting = false);
    }
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
          final isCloudReady = isRealApi && config.hasGeminiApiKey;

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

                _buildPlanTestSection(config),

                const SizedBox(height: 24),

                const Text(
                  'リモコン UI（画面設計）',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'API 連携なしで Free / Pro / 家電種別ごとの UI を確認できます。',
                        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF)),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const RemoteControlPreviewScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.tv_outlined, size: 18),
                        label: const Text('リモコン UI プレビューを開く'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- 推論モード切り替え ---
                const Text(
                  '推論モード',
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
                        'クラウド推論を使用',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Switch(
                      value: isRealApi,
                      onChanged: (v) => _handleCloudInferenceToggle(config, v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: _isSavingCloud || _isConnectionTesting
                          ? null
                          : () => _pasteCloudCredentialFromClipboard(config),
                      child: const Text('クリップボードから貼り付け'),
                    ),
                    TextButton(
                      onPressed: _isSavingCloud || _isConnectionTesting
                          ? null
                          : () => _openCloudCredentialDialog(config),
                      child: const Text('手入力で更新'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _isConnectionTesting || _isSavingCloud
                        ? null
                        : () => _runCloudConnectionTest(config),
                    child: Text(
                      _isSavingCloud
                          ? '保存中...'
                          : _isConnectionTesting
                              ? '接続テスト中...'
                              : '接続テスト実行',
                    ),
                  ),
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
                            isRealApi ? 'クラウド推論モード' : 'ローカルモード',
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
                        '推論接続',
                        isCloudReady ? '接続済み' : 'ローカル処理中',
                        isCloudReady,
                      ),
                      _buildStatusRow(
                        '接続情報',
                        config.hasGeminiApiKey
                            ? config.cloudSecretMaskedSummary
                            : '未登録',
                        config.hasGeminiApiKey,
                      ),
                      _buildStatusRow(
                        '利用可否',
                        config.cloudInferenceAvailabilityMessage,
                        config.canUseClientSideGemini,
                      ),
                      if (!isCloudReady) ...[
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Text(
                            '切替不可理由: ${config.cloudInferenceBlockedReason}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF9A3412),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                      _buildStatusRow(
                        'AI チャット',
                        isCloudReady
                            ? 'クラウド推論 (マルチターン)'
                            : 'ローカル応答 (テンプレート)',
                        isCloudReady,
                      ),
                      _buildStatusRow(
                        'スマートスキャン OCR',
                        isCloudReady ? 'クラウド抽出' : 'ダミーパーサー',
                        isCloudReady,
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

                // --- 実請求ベース自動調整 ---
                const Text(
                  '実請求ベース自動調整',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _actualCostController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: '当月実コスト (USD)',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _proUsersController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Pro会員数',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _fxController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: '為替 JPY/USD',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _isAutoTuning ? null : _runBillingAutoTune,
                        icon: _isAutoTuning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.tune, size: 18),
                        label: Text(_isAutoTuning ? '調整中...' : '上限を自動再計算'),
                      ),
                      const SizedBox(height: 8),
                      if (_effectivePolicy != null) ...[
                        _buildStatusRow(
                          '現行Pro月間Credits',
                          '${_effectivePolicy!.proMonthlyCredits}',
                          true,
                        ),
                        _buildStatusRow(
                          '現行Pro画像上限',
                          '${_effectivePolicy!.proRoomImagePerRoomMonthly}回/部屋/月',
                          true,
                        ),
                        _buildStatusRow(
                          '現行Hard Cap',
                          _effectivePolicy!.hardMonthlyCostCapUsd
                              .toStringAsFixed(2),
                          true,
                        ),
                      ],
                      if (_lastTuneResult != null) ...[
                        const SizedBox(height: 6),
                        _buildStatusRow(
                          '最終scale',
                          _lastTuneResult!.scale.toStringAsFixed(3),
                          true,
                        ),
                        _buildStatusRow(
                          '目標コスト(USD)',
                          _lastTuneResult!.targetCostUsd.toStringAsFixed(2),
                          true,
                        ),
                      ],
                    ],
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
