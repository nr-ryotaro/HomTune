import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/safety_info.dart';
import '../services/manual_fetch_service.dart';
import '../services/sell_advisor_service.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/maintenance_calendar_service.dart';
import '../models/appliance_presentation.dart';
import 'asset_value_chart.dart';
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
            _buildRecallAlertBanner(device),
          ],

          const SizedBox(height: 32),

          // 2. Asset Dashboard
          _buildSectionTitle('Asset Dashboard', '資産状況'),
          const SizedBox(height: 16),
          Container(
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
                const Text(
                  '現在の資産価値',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormatter
                      .format(device.assetValue?.currentUsedPrice ?? 0),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniStat(
                        '帳簿上の価値',
                        device.assetValue?.bookValue != null
                            ? currencyFormatter
                                .format(device.assetValue!.bookValue)
                            : '-',
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMiniStat(
                        '市場価値',
                        currencyFormatter
                            .format(device.assetValue?.currentUsedPrice ?? 0),
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Chart
                SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: AssetValueChart(device: device),
                ),
              ],
            ),
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
          if (_shouldShowSellAdvisor(device)) ...[
            const SizedBox(height: 24),
            _buildSellAdvisorCard(device),
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

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(0.8),
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
  Widget _buildRecallAlertBanner(Device device) {
    final recall = device.safetyInfo?.recallDetails;
    if (recall == null) return const SizedBox.shrink();

    // 深刻度に応じた色設定
    Color bgColor;
    Color borderColor;
    Color textColor;
    Color iconColor;
    IconData icon;

    switch (recall.severity) {
      case RecallSeverity.critical:
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFF991B1B);
        iconColor = const Color(0xFFDC2626);
        icon = Icons.warning_amber_rounded;
        break;
      case RecallSeverity.warning:
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFCD34D);
        textColor = const Color(0xFF92400E);
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.error_outline_rounded;
        break;
      case RecallSeverity.info:
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        textColor = const Color(0xFF1E40AF);
        iconColor = const Color(0xFF3B82F6);
        icon = Icons.info_outline_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 8),
              Text(
                'リコール情報 — ${recall.severityLabel}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            recall.description,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          // Details
          Text(
            '原因: ${recall.reason}',
            style: TextStyle(
              fontSize: 12,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),
          if (recall.date.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '発表日: ${_formatRecallDate(recall.date)}',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          if (recall.affectedUnits != null) ...[
            const SizedBox(height: 4),
            Text(
              '対象台数: 約${NumberFormat('#,###').format(recall.affectedUnits)}台',
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.8),
              ),
            ),
          ],
          // Action button
          if (recall.manufacturerContactUrl != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(recall.manufacturerContactUrl!);
                  if (!await launchUrl(url,
                      mode: LaunchMode.externalApplication)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URLを開けませんでした')),
                      );
                    }
                  }
                },
                icon: Icon(Icons.open_in_new, size: 16, color: iconColor),
                label: Text(
                  'メーカーに問い合わせる',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: iconColor,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatRecallDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy年MM月dd日').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  /// --- 売却アドバイザー表示判定 ---
  /// sell_now / sell_soon のみ表示（hold / keep_using は非表示）
  bool _shouldShowSellAdvisor(Device device) {
    final advisor = SellAdvisorService();
    final advice = advisor.analyze(device);
    return advice.type == 'sell_now' || advice.type == 'sell_soon';
  }

  /// --- 売却アドバイザーカード ---
  Widget _buildSellAdvisorCard(Device device) {
    final advisor = SellAdvisorService();
    final advice = advisor.analyze(device);

    // タイプ別カラー
    final Color primaryColor;
    final Color bgColor;
    final Color borderColor;
    final IconData iconData;
    switch (advice.type) {
      case 'sell_now':
        primaryColor = const Color(0xFF16A34A);
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        iconData = Icons.trending_up_rounded;
        break;
      case 'sell_soon':
        primaryColor = const Color(0xFFD97706);
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFCD34D);
        iconData = Icons.schedule_rounded;
        break;
      case 'hold':
        primaryColor = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        iconData = Icons.swap_horiz_rounded;
        break;
      default:
        primaryColor = const Color(0xFF6B7280);
        bgColor = const Color(0xFFF9FAFB);
        borderColor = const Color(0xFFE5E7EB);
        iconData = Icons.hourglass_empty_rounded;
    }

    final currencyFormatter = NumberFormat('#,##0', 'ja_JP');

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(iconData, color: primaryColor, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    advice.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                // スコアバッジ
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Score ${advice.score}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 本文
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  advice.reason,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),

                // 数値指標
                Row(
                  children: [
                    Expanded(
                      child: _buildAdvisorStat(
                        '推定売却価格',
                        '¥${currencyFormatter.format(advice.estimatedSellPrice)}',
                        primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildAdvisorStat(
                        '帳簿価値との差額',
                        '${advice.profitOrLoss >= 0 ? "+" : ""}¥${currencyFormatter.format(advice.profitOrLoss)}',
                        advice.profitOrLoss >= 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),

                if (advice.monthsUntilCrossover != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 14, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        '交差点まで約${advice.monthsUntilCrossover}ヶ月',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),
                // アクション推奨
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          size: 16, color: primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          advice.action,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvisorStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// メンテナンスタスクセクション
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
