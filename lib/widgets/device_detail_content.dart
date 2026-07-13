import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/device_asset.dart';
import '../models/safety_info.dart';
import '../services/manual_fetch_service.dart';
import '../services/sell_advisor_service.dart';
import '../models/ai_usage_policy.dart';
import '../models/market_refresh_mode.dart';
import '../services/asset_valuation_refresh_service.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/market_price_gemini_service.dart';
import '../services/market_valuation_quota_service.dart';
import '../services/maintenance_calendar_service.dart';
import '../models/appliance_presentation.dart';
import 'asset_value_chart.dart';
import 'device_detail/device_recall_section.dart';
import 'device_detail/device_sell_advisor_section.dart';
import 'device_detail/remote_control_section.dart';
import 'registration/remote_setup_reminder_banner.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import '../screens/maintenance_detail_screen.dart';
import '../screens/maintenance_calendar_screen.dart';

class DeviceDetailContent extends StatefulWidget {
  final Device device;
  final AppliancePresentation? presentation;

  const DeviceDetailContent({
    super.key,
    required this.device,
    this.presentation,
  });

  @override
  State<DeviceDetailContent> createState() => _DeviceDetailContentState();
}

class _DeviceDetailContentState extends State<DeviceDetailContent> {
  late ManualFetchState _manualState;
  String? _manualPdfUrl;
  bool _refreshingAsset = false;

  @override
  void initState() {
    super.initState();
    _syncManualFromDevice(widget.device);
  }

  @override
  void didUpdateWidget(covariant DeviceDetailContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.device.id != widget.device.id ||
        oldWidget.device.manualState != widget.device.manualState ||
        oldWidget.device.manualPdfUrl != widget.device.manualPdfUrl ||
        oldWidget.device.manual?.url != widget.device.manual?.url) {
      _syncManualFromDevice(widget.device);
    }
  }

  Future<void> _refreshAssetValue(
    String deviceId, {
    MarketRefreshMode mode = MarketRefreshMode.local,
  }) async {
    setState(() => _refreshingAsset = true);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final config = Provider.of<ConfigService>(context, listen: false);
    try {
      final result = await deviceService.refreshDeviceAssetValue(
        deviceId,
        config: config,
        mode: mode,
      );
      if (mounted && result?.message != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result!.message!)),
        );
      }
    } on AssetRefreshPolicyException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshingAsset = false);
    }
  }

  String? _formatValuationUpdatedAt(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    final now = DateTime.now();
    if (now.difference(dt).inMinutes < 2) return 'たった今';
    if (now.difference(dt).inHours < 24) {
      return '${now.difference(dt).inHours}時間前';
    }
    return DateFormat('M/d HH:mm').format(dt);
  }

  void _syncManualFromDevice(Device device) {
    _manualState = device.manualState;
    _manualPdfUrl = device.manualPdfUrl ?? device.manual?.url;
  }

  Future<void> _fetchManual() async {
    setState(() {
      _manualState = ManualFetchState.fetching;
    });

    try {
      final result =
          await ManualFetchService().fetchOfficialManual(widget.device);
      if (mounted) {
        setState(() {
          _manualState = result['state'] as ManualFetchState;
          _manualPdfUrl = result['url'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualState = ManualFetchState.notFound;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('マニュアル検索中にエラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _launchManualLink() async {
    if (_manualPdfUrl != null) {
      final Uri url = Uri.parse(_manualPdfUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('リンクを開けませんでした')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'ja_JP', symbol: '¥', decimalDigits: 0);
    final device = widget.device;
    final p = widget.presentation;
    final displayIcon = p?.icon ?? '📦';
    final displayTitle = p?.title ??
        (device.category.isNotEmpty ? device.category : device.name);
    final modelLine = p?.subtitle?.trim().isNotEmpty == true
        ? p!.subtitle!
        : (device.modelNumber.trim().isNotEmpty
            ? '${device.manufacturer} ${device.modelNumber}'.trim()
            : null);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          Center(
            child: Column(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    displayIcon,
                    style: const TextStyle(fontSize: 40, height: 1),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (modelLine != null && modelLine.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    modelLine,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF888888),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          // 1.5. Recall Alert Banner
          if (device.safetyInfo?.isRecallActive == true) ...[
            const SizedBox(height: 24),
            DeviceRecallSection(device: device),
          ],

          const SizedBox(height: 32),

          RemoteSetupReminderBanner(
            device: device,
            placement: 'device_detail',
          ),
          RemoteControlSection(device: device),
          const SizedBox(height: 32),

          // 2. Asset Dashboard
          _buildSectionTitle('Asset Dashboard', '資産状況'),
          const SizedBox(height: 16),
          Consumer<DeviceService>(
            builder: (context, deviceService, _) {
              final assetDevice =
                  deviceService.getDeviceById(device.id) ?? device;
              final av = assetDevice.assetValue;
              final updatedLabel = _formatValuationUpdatedAt(av?.lastPriceCheck);
              final marketSourceLabel = av?.marketSourceParsed.label ?? '推定（数式）';

              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E5E5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '表示価値（帳簿と市場の高い方）',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                currencyFormatter
                                    .format(av?.currentUsedPrice ?? 0),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF333333),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: '資産価値を再計算（無料・端末内）',
                          onPressed: _refreshingAsset
                              ? null
                              : () => _refreshAssetValue(device.id),
                          icon: _refreshingAsset
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                      ],
                    ),
                    if (updatedLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '更新: $updatedLabel ・ 市場: $marketSourceLabel',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMiniStat(
                            '帳簿価値',
                            av?.bookValue != null
                                ? currencyFormatter.format(av!.bookValue!)
                                : '-',
                            Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildMiniStat(
                            '市場価値',
                            av?.marketValue != null
                                ? currencyFormatter.format(av!.marketValue!)
                                : '-',
                            Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildProMarketActions(context, assetDevice),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 230,
                      width: double.infinity,
                      child: AssetValueChart(device: assetDevice),
                    ),
                  ],
                ),
              );
            },
          ),

          // Financial Insight (If available)
          if (device.assetValue?.valuationInsight != null) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFB3E5FC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF0288D1)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      device.assetValue!.valuationInsight!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0277BD),
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 2.5. Sell Advisor Card — 売却チャンスが近い場合のみ表示
          if (shouldShowSellAdvisor(device)) ...[
            const SizedBox(height: 24),
            DeviceSellAdvisorSection(device: device),
          ],

          const SizedBox(height: 32),

          // 2.7. Maintenance Tasks Section
          if (device.maintenanceTasks.isNotEmpty) ...[
            _buildSectionTitle('Maintenance', 'お手入れスケジュール'),
            const SizedBox(height: 12),
            _buildMaintenanceSection(device),
            const SizedBox(height: 32),
          ],

          // 3. Manual Section (New)
          _buildSectionTitle('Manual', '取扱説明書'),
          const SizedBox(height: 12),
          _buildManualSection(),

          const SizedBox(height: 32),

          // 4. Valuation Details
          _buildSectionTitle('Valuation Details', '評価詳細'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              children: [
                _buildValueRow(
                  '購入価格 (Purchase Price)',
                  currencyFormatter.format(device.purchasePrice),
                  isFirst: true,
                ),
                _buildValueRow(
                  '減価償却率 (Depreciation)',
                  device.assetValue != null
                      ? '${(device.assetValue!.depreciationRate * 100).toStringAsFixed(1)}%'
                      : '-',
                ),
                _buildValueRow(
                  '状態 (Condition)',
                  device.condition == ItemCondition.newItem ? 'New' : 'Used',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // 5. Device Information
          _buildSectionTitle('Device Information', '基本情報'),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Column(
              children: [
                _buildValueRow(
                  '保管場所 (Location)',
                  '${device.room} / ${device.location}',
                  isFirst: true,
                ),
                _buildValueRow(
                  '購入日 (Date)',
                  device.purchaseDate,
                ),
                _buildValueRow(
                  '所有期間 (Owned)',
                  '${device.yearsOwned}年',
                  isLast: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String enTitle, String jpTitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          enTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          jpTitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildManualSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: Colors.grey, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getManualStatusText(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF333333),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildManualActionButton(),
          const SizedBox(height: 12),
          Text(
            '法務ポリシーにより、外部PDF本文の保存は行いません。公式ページへの参照リンクのみ扱います。',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getManualStatusText() {
    switch (_manualState) {
      case ManualFetchState.notFetched:
        return '公式マニュアルの参照リンクは未取得です。';
      case ManualFetchState.fetching:
        return '公式マニュアルの参照リンクを検索中...';
      case ManualFetchState.found:
        return '公式マニュアルの参照リンクが見つかりました。';
      case ManualFetchState.notFound:
        return '許可ソース内で公式マニュアル参照リンクが見つかりませんでした。';
    }
  }

  Widget _buildManualActionButton() {
    switch (_manualState) {
      case ManualFetchState.notFetched:
        return OutlinedButton.icon(
          onPressed: _fetchManual,
          icon: const Icon(Icons.search),
          label: const Text('公式マニュアル参照リンクを探す'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF333333),
            side: const BorderSide(color: Color(0xFFE5E5E5)),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
      case ManualFetchState.fetching:
        return const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case ManualFetchState.found:
        return ElevatedButton.icon(
          onPressed: _launchManualLink,
          icon: const Icon(Icons.open_in_new),
          label: const Text('公式ページを開く'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF333333),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            elevation: 0,
          ),
        );
      case ManualFetchState.notFound:
        return OutlinedButton.icon(
          onPressed: () {
            // 手動登録フローへのコールバック（仮実装）
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('手動登録機能は現在開発中です')),
            );
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('手動でリンクを登録'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.orange,
            side: const BorderSide(color: Colors.orange),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
    }
  }

  Widget _buildProMarketActions(BuildContext context, Device device) {
    final config = Provider.of<ConfigService>(context);
    final isPro = config.subscriptionTier == SubscriptionTier.pro;

    return FutureBuilder<MarketValuationQuotaSnapshot>(
      future: MarketValuationQuotaService.instance.getSnapshot(config),
      builder: (context, quotaSnap) {
        final quota = quotaSnap.data;
        final l1Remaining = quota?.remaining ?? 0;
        final l1Limit = quota?.monthlyLimit ?? 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              '市場価値の更新',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            if (!isPro) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '無料: 上の更新ボタンで端末内再計算（L0）\n市場価値は推定精度が低めです',
                  style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _refreshingAsset
                    ? null
                    : () => showProUpgradeDialog(
                          context,
                          upsellContext: ProUpsellContext.valuation,
                          deviceName: device.name,
                          deviceCategoryLabel: device.category,
                        ),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('相場DBを調べる（Pro）'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _refreshingAsset
                    ? null
                    : () => showProUpgradeDialog(
                          context,
                          upsellContext: ProUpsellContext.valuation,
                          deviceName: device.name,
                        ),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('AI相場推定（Pro）'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: _refreshingAsset
                    ? null
                    : () => _refreshAssetValue(
                          device.id,
                          mode: MarketRefreshMode.proReference,
                        ),
                icon: const Icon(Icons.inventory_2_outlined, size: 18),
                label: Text(
                  '相場DBを調べる（L1・残り $l1Remaining / $l1Limit 回/月）',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2E7D32),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _refreshingAsset
                    ? null
                    : () => _refreshAssetValue(
                          device.id,
                          mode: MarketRefreshMode.proAi,
                        ),
                icon: const Icon(Icons.auto_awesome, size: 18),
                label: Text(
                  config.isUsingRealApi
                      ? 'AI相場推定（L2・${MarketPriceGeminiService.creditCost} クレジット）'
                      : 'AI相場推定（L2・開発モード・モック）',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1565C0),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueRow(String label, String value,
      {bool isFirst = false, bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF5F5F5)),
              ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF333333),
            ),
          ),
        ],
      ),
    );
  }

  /// リコールアラートバナー
  Widget _buildMaintenanceSection(Device device) {
    // ScaffoldのContextからConfigServiceを取得可能
    final config = Provider.of<ConfigService>(context, listen: true);
    final tasks = device.maintenanceTasks;

    // ずぼらモード（シンプル）の場合
    if (!config.useDetailedMaintenance) {
      if (tasks.isEmpty) return const SizedBox.shrink();

      // デバイス全体としての一番悪い状態を判定
      bool isOverdue = tasks.any((t) => t.isOverdue);
      bool isDueSoon = tasks.any((t) => t.isDueSoon);

      // 次の対応が必要なタスク（最も近い・超過）
      final nextTasks = [...tasks];
      nextTasks.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
      final nextTask = nextTasks.first;

      Color bgColor;
      Color borderColor;
      Color textColor;
      String statusText;

      if (isOverdue) {
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade700;
        statusText = 'お手入れ時期を過ぎています';
      } else if (isDueSoon) {
        bgColor = Colors.amber.shade50;
        borderColor = Colors.amber.shade200;
        textColor = Colors.amber.shade800;
        statusText = 'まもなくお手入れ時期です';
      } else {
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade700;
        statusText = '次回: ${nextTask.daysUntilDue}日後';
      }

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // 全タスクをまとめて完了
                  for (final task in tasks) {
                    MaintenanceCalendarService.completeTask(task);
                  }
                  final provider =
                      Provider.of<DeviceService>(context, listen: false);
                  await provider.onMaintenanceTasksUpdated(device.id);

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('${device.name}のお手入れを記録しました！'),
                        ],
                      ),
                      backgroundColor: const Color(0xFF333333),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() {});
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text(
                  'お手入れした！',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF333333),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // --- 以下、詳細モード（既存ロジック） ---
    return Column(
      children: [
        ...tasks.map((task) {
          Color borderColor;
          String statusText;
          if (task.isOverdue) {
            borderColor = Colors.red.shade200;
            statusText = '${(-task.daysUntilDue)}日超過';
          } else if (task.isDueSoon) {
            borderColor = Colors.amber.shade200;
            statusText = 'あと${task.daysUntilDue}日';
          } else {
            borderColor = Colors.grey.shade200;
            statusText =
                task.nextDue != null ? '${task.daysUntilDue}日後' : '未設定';
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaintenanceDetailScreen(
                      device: device,
                      task: task,
                      onCompleted: () => setState(() {}),
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Text(task.priorityIcon,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2C2C2C),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${task.intervalDays}日ごと',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: task.isOverdue
                            ? Colors.red.shade50
                            : task.isDueSoon
                                ? Colors.amber.shade50
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: task.isOverdue
                              ? Colors.red.shade700
                              : task.isDueSoon
                                  ? Colors.amber.shade800
                                  : Colors.grey.shade600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right,
                        size: 18, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MaintenanceCalendarScreen(),
              ),
            );
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month, size: 16, color: Colors.blue.shade600),
              const SizedBox(width: 6),
              Text(
                'メンテナンスカレンダーを見る',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blue.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
