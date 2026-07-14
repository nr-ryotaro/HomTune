import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_usage_policy.dart';
import '../models/cloud_connection_test_result.dart';
import 'ai_api_client.dart';

/// 機能確認用の API / ダミーデータ切り替え設定
/// リリース前に削除予定（RELEASE_CHECKLIST.md 参照）
class ConfigService extends ChangeNotifier {
  static const String _keyUseRealApi = 'use_real_api';
  static const String _keyUseDetailedMaintenance = 'use_detailed_maintenance';
  static const String _keySubscriptionTier = 'subscription_tier';
  static const String _keyGeminiApiKey = 'gemini_api_key';
  static const String _keyGeminiModel = 'gemini_model';
  static const String _keyPreferAiProxy = 'prefer_ai_proxy';
  // 本番ビルドではデフォルト禁止。必要時のみ dart-define で明示許可:
  // --dart-define=ALLOW_CLIENT_SIDE_GEMINI_IN_RELEASE=true
  static const bool _allowClientSideGeminiInRelease = bool.fromEnvironment(
    'ALLOW_CLIENT_SIDE_GEMINI_IN_RELEASE',
    defaultValue: false,
  );

  bool _useRealApi = false;
  bool _useDetailedMaintenance = false; // デフォルトは「ずぼら」モード（シンプル）
  SubscriptionTier _subscriptionTier = SubscriptionTier.free;
  String _geminiApiKey = '';
  String _geminiModel = 'gemini-2.5-flash-lite';
  /// サーバー `/v1/ai/generate` を優先（Phase 1 移行中の切替）
  bool _preferAiProxy = true;
  bool _loaded = false;

  bool get canUseClientSideGemini =>
      !kReleaseMode || _allowClientSideGeminiInRelease;
  bool get isUsingRealApi => _useRealApi && canUseClientSideGemini;
  bool get preferAiProxy => _preferAiProxy;
  /// プロキシ優先、またはクライアント直呼びの実APIモード
  bool get isCloudAiEnabled => preferAiProxy || isUsingRealApi;
  /// プロキシ経由ならクライアント鍵不要でクラウド推論可能とみなす
  bool get canUseCloudInference =>
      preferAiProxy || (isUsingRealApi && hasGeminiApiKey);
  bool get useDetailedMaintenance => _useDetailedMaintenance;
  SubscriptionTier get subscriptionTier => _subscriptionTier;
  String get geminiApiKey => _geminiApiKey;
  String get geminiModel => _geminiModel;

  /// リリース断面のコスパ最適モデル（全テキスト系 AI 機能で共通）
  static const String releaseCostOptimizedModel = 'gemini-2.5-flash-lite';

  /// 機能ごとの推論モデル（現状は同一モデル。将来 feature 別に切替可能）
  String geminiModelFor(AiFeature feature) {
    if (_geminiModel.isNotEmpty) return _geminiModel;
    return releaseCostOptimizedModel;
  }
  bool get hasGeminiApiKey =>
      canUseClientSideGemini && _geminiApiKey.trim().isNotEmpty;

  /// 画面表示用（生キーは出さない）
  String get cloudSecretMaskedSummary {
    if (!hasGeminiApiKey) return '';
    final key = _geminiApiKey.trim();
    if (key.length <= 8) return '••••••••（登録済み）';
    final head = key.substring(0, key.length < 12 ? 3 : 6);
    final tail = key.substring(key.length - 4);
    return '$head••••$tail（登録済み）';
  }

  bool get isLoaded => _loaded;
  String get cloudInferenceAvailabilityMessage {
    if (preferAiProxy) return 'AIプロキシ経由で利用可能';
    if (canUseClientSideGemini) return '利用可能（クライアント直）';
    return 'このビルドではクラウド推論は無効です';
  }
  String get cloudInferenceBlockedReason {
    if (preferAiProxy) return '';
    if (!canUseClientSideGemini) {
      return 'このビルド種別ではクラウド推論が禁止されています。';
    }
    if (!hasGeminiApiKey) {
      return '接続情報（シークレット）が未設定です。';
    }
    return '';
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _useRealApi = prefs.getBool(_keyUseRealApi) ?? false;
    _useDetailedMaintenance =
        prefs.getBool(_keyUseDetailedMaintenance) ?? false;
    final tierRaw = prefs.getString(_keySubscriptionTier) ?? 'free';
    _subscriptionTier =
        tierRaw == 'pro' ? SubscriptionTier.pro : SubscriptionTier.free;
    _geminiApiKey = canUseClientSideGemini
        ? (prefs.getString(_keyGeminiApiKey) ?? '')
        : '';
    _geminiModel =
        prefs.getString(_keyGeminiModel) ?? 'gemini-2.5-flash-lite';
    // リリースビルドではプロキシ固定（クライアント直呼びを塞ぐ）
    if (kReleaseMode) {
      _preferAiProxy = true;
      if (prefs.getBool(_keyPreferAiProxy) != true) {
        await prefs.setBool(_keyPreferAiProxy, true);
      }
    } else {
      _preferAiProxy = prefs.getBool(_keyPreferAiProxy) ?? true;
    }
    if (canUseClientSideGemini && _geminiApiKey.isEmpty) {
      const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (envKey.isNotEmpty) {
        _geminiApiKey = envKey.trim();
        await prefs.setString(_keyGeminiApiKey, _geminiApiKey);
      }
    }
    if (!canUseClientSideGemini) {
      _useRealApi = false;
    }
    if (_geminiModel.isEmpty) {
      _geminiModel = 'gemini-2.5-flash-lite';
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setUseRealApi(bool value) async {
    final normalized = canUseClientSideGemini ? value : false;
    if (_useRealApi == normalized) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseRealApi, normalized);
    _useRealApi = normalized;
    notifyListeners();
  }

  Future<void> setUseDetailedMaintenance(bool value) async {
    if (_useDetailedMaintenance == value) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseDetailedMaintenance, value);
    _useDetailedMaintenance = value;
    notifyListeners();
  }

  Future<void> setSubscriptionTier(SubscriptionTier tier) async {
    if (_subscriptionTier == tier) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySubscriptionTier, tier.name);
    _subscriptionTier = tier;
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String value) async {
    if (!canUseClientSideGemini) return;
    final normalized = value.trim();
    if (_geminiApiKey == normalized) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiApiKey, normalized);
    _geminiApiKey = normalized;
    notifyListeners();
  }

  Future<void> setGeminiModel(String value) async {
    if (!canUseClientSideGemini) return;
    final normalized = value.trim();
    if (normalized.isEmpty || _geminiModel == normalized) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGeminiModel, normalized);
    _geminiModel = normalized;
    notifyListeners();
  }

  Future<void> setPreferAiProxy(bool value) async {
    // リリースでは OFF 不可
    final normalized = kReleaseMode ? true : value;
    if (_preferAiProxy == normalized) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPreferAiProxy, normalized);
    _preferAiProxy = normalized;
    notifyListeners();
  }

  /// 入力欄の値を保存用シークレットに解決（空欄・マスク表示は既存キーを維持）
  String resolveCloudSecretInput(String rawInput) {
    final input = rawInput.trim();
    if (!hasGeminiApiKey) return input;
    if (input.isEmpty) return _geminiApiKey.trim();
    if (input == cloudSecretMaskedSummary || input.contains('登録済み')) {
      return _geminiApiKey.trim();
    }
    return input;
  }

  Future<bool> setCloudConnection({
    required String secret,
    required String profile,
  }) async {
    final trimmedSecret = secret.trim();
    final trimmedProfile = profile.trim();
    if (trimmedSecret.isEmpty || trimmedProfile.isEmpty) {
      return false;
    }
    await setGeminiApiKey(trimmedSecret);
    await setGeminiModel(trimmedProfile);
    return hasGeminiApiKey;
  }

  static const List<String> cloudModelCandidates = [
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash-lite',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  Future<CloudConnectionTestResult> testCloudConnection({
    String? secret,
    String? profile,
    int maxModelsToTry = 3,
    Duration perModelTimeout = const Duration(seconds: 8),
  }) async {
    if (preferAiProxy) {
      final client = AiApiClient();
      try {
        final modelId = (profile ?? geminiModel).trim().isEmpty
            ? releaseCostOptimizedModel
            : (profile ?? geminiModel).trim();
        final result = await client
            .generateRaw(
              config: this,
              feature: 'connectionTest',
              model: modelId,
              contents: const [AiContentMessage(role: 'user', text: 'ok')],
            )
            .timeout(perModelTimeout);
        final ok = result.text.trim().isNotEmpty;
        return CloudConnectionTestResult(
          success: ok,
          modelId: result.modelId,
          message: ok
              ? 'AIプロキシ接続成功（${result.modelId}${result.mocked ? ' / mock' : ''}）'
              : 'AIプロキシ応答が空です',
        );
      } on AiApiException catch (e) {
        return CloudConnectionTestResult(
          success: false,
          modelId: '',
          message: 'AIプロキシ接続失敗: ${e.message}',
        );
      } catch (e) {
        return CloudConnectionTestResult(
          success: false,
          modelId: '',
          message: 'AIプロキシ接続テスト中に例外: $e',
        );
      } finally {
        client.dispose();
      }
    }

    try {
      final apiKey = (secret ?? geminiApiKey).trim();
      if (apiKey.isEmpty) {
        return const CloudConnectionTestResult(
          success: false,
          modelId: '',
          message: '接続シークレットが空です。preferAiProxy を有効にするかキーを設定してください。',
        );
      }

      // Legacy path kept only when preferAiProxy=false.
      // Prefer enabling the proxy instead of embedding keys in the client.
      return CloudConnectionTestResult(
        success: false,
        modelId: '',
        message:
            'クライアント直呼びの接続テストは廃止予定です。AIプロキシ（preferAiProxy）を有効にして再試行してください。',
      );
    } catch (e) {
      return CloudConnectionTestResult(
        success: false,
        modelId: '',
        message: '接続テスト中に例外が発生しました: $e',
      );
    }
  }
}
