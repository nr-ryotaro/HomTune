import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/device.dart';
import '../services/manual_fetch_service.dart';
import 'anthropomorphic_device_icon.dart';
import 'asset_value_chart.dart';

class DeviceDetailContent extends StatefulWidget {
  final Device device;

  const DeviceDetailContent({super.key, required this.device});

  @override
  State<DeviceDetailContent> createState() => _DeviceDetailContentState();
}

class _DeviceDetailContentState extends State<DeviceDetailContent> {
  late ManualFetchState _manualState;
  String? _manualPdfUrl;
  bool _isFetching = false;

  @override
  void initState() {
    super.initState();
    _manualState = widget.device.manualState;
    _manualPdfUrl = widget.device.manualPdfUrl;
  }

  Future<void> _fetchManual() async {
    setState(() {
      _manualState = ManualFetchState.fetching;
      _isFetching = true;
    });

    try {
      final result =
          await ManualFetchService().fetchOfficialManual(widget.device);
      if (mounted) {
        setState(() {
          _manualState = result['state'] as ManualFetchState;
          _manualPdfUrl = result['url'] as String?;
          _isFetching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualState = ManualFetchState.notFound;
          _isFetching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('マニュアル検索中にエラーが発生しました: $e')),
        );
      }
    }
  }

  Future<void> _launchPdf() async {
    if (_manualPdfUrl != null) {
      final Uri url = Uri.parse(_manualPdfUrl!);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDFを開けませんでした')),
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
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnthropomorphicDeviceIcon(
                      device: device,
                      size: 50,
                      showAnimation: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                  textAlign: TextAlign.center,
                ),
                if (device.modelNumber.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${device.manufacturer} ${device.modelNumber}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
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

          const SizedBox(height: 32),

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
        ],
      ),
    );
  }

  String _getManualStatusText() {
    switch (_manualState) {
      case ManualFetchState.notFetched:
        return '公式マニュアルは未取得です。';
      case ManualFetchState.fetching:
        return '公式マニュアルを検索中...';
      case ManualFetchState.found:
        return '公式マニュアルが見つかりました。';
      case ManualFetchState.notFound:
        return '公式マニュアルは見つかりませんでした。';
    }
  }

  Widget _buildManualActionButton() {
    switch (_manualState) {
      case ManualFetchState.notFetched:
        return OutlinedButton.icon(
          onPressed: _fetchManual,
          icon: const Icon(Icons.search),
          label: const Text('公式マニュアルを探す'),
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
          onPressed: _launchPdf,
          icon: const Icon(Icons.open_in_new),
          label: const Text('PDFを開く'),
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
          label: const Text('手動でリンク/ファイルを登録'),
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
}
