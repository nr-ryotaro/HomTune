import 'package:flutter/material.dart';
import 'dart:io';
import '../models/device.dart';
import '../services/manual_service.dart';
import '../services/valuation_service.dart';
import '../screens/manual_viewer_screen.dart';
import '../screens/manual_registration_screen.dart';
import 'asset_value_chart.dart';

class DeviceDetailCard extends StatelessWidget {
  final Device device;

  const DeviceDetailCard({
    super.key,
    required this.device,
  });

  Future<void> _openManual(BuildContext context) async {
    // マニュアルが未登録の場合は登録画面へ
    if (device.manual == null || device.manual!.url.isEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ManualRegistrationScreen(
            device: device,
          ),
        ),
      );
      return;
    }

    if (device.modelNumber.isEmpty || device.manufacturer.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('型番またはメーカー情報が不足しています'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // ローディング表示
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final manualService = ManualService();
      File? pdfFile;

      // ローカルファイルの場合
      if (device.manual!.isLocalFile) {
        pdfFile = await manualService.getManualFile(device.manual!.url);
      } else {
        // 外部URLまたは型番から検索
        pdfFile = await manualService.getManual(
          device.modelNumber,
          device.manufacturer,
          manualUrl: device.manual!.url,
        );
      }

      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる

      if (pdfFile != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManualViewerScreen(
              pdfFile: pdfFile!,
              deviceName: device.name,
              modelNumber: device.modelNumber,
            ),
          ),
        );
      } else {
        // マニュアルが見つからない場合は登録画面へ
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ManualRegistrationScreen(
              device: device,
            ),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ローディングを閉じる
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('エラー: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showMoreDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // ハンドル
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ヘッダー
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          device.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (device.modelNumber.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            device.modelNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 詳細情報
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailSection(
                      'メーカー',
                      device.manufacturer.isNotEmpty
                          ? device.manufacturer
                          : '未登録',
                    ),
                    _buildDetailSection(
                      'カテゴリー',
                      device.category.isNotEmpty ? device.category : '未登録',
                    ),
                    if (device.purchaseDate.isNotEmpty)
                      _buildDetailSection(
                        '購入日',
                        device.purchaseDate,
                      ),
                    if (device.purchasePrice > 0)
                      _buildDetailSection(
                        '購入価格',
                        '¥${device.purchasePrice.toStringAsFixed(0)}',
                      ),
                    if (device.yearsOwned > 0)
                      _buildDetailSection(
                        '所有年数',
                        '${device.yearsOwned}年',
                      ),
                    if (device.location.isNotEmpty)
                      _buildDetailSection(
                        '設置場所',
                        device.location,
                      ),
                    if (device.status.isNotEmpty)
                      _buildDetailSection(
                        'ステータス',
                        device.status,
                      ),
                    if (device.maintenance != null) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'メンテナンス情報',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (device.maintenance!.alerts.isNotEmpty) ...[
                        ...device.maintenance!.alerts.map(
                          (alert) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: alert.priority == 'high'
                                  ? Colors.red[50]
                                  : Colors.amber[50],
                              border: Border.all(
                                color: alert.priority == 'high'
                                    ? Colors.red[200]!
                                    : Colors.amber[200]!,
                                width: 0.5,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  size: 20,
                                  color: alert.priority == 'high'
                                      ? Colors.red[700]
                                      : Colors.amber[700],
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        alert.message,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: alert.priority == 'high'
                                              ? Colors.red[900]
                                              : Colors.amber[900],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                    // 安全診断ステータスセクション（safetyInfoがnullでない場合のみ表示）
                    if (device.safetyInfo != null) ...[
                      const SizedBox(height: 24),
                      _buildSafetySection(device),
                    ],
                    // 資産価値セクション
                    const SizedBox(height: 24),
                    _buildAssetValueSection(device),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 安全診断セクションを構築
  Widget _buildSafetySection(Device device) {
    final safetyInfo = device.safetyInfo!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '安全診断ステータス',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),

        // リコール情報
        if (safetyInfo.isRecallActive && safetyInfo.recallDetails != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(
                color: Colors.red[200]!,
                width: 0.5,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 24,
                      color: Color(0xFFef4444),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'リコール対象',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFef4444),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'この子が危ないかもしれないので、一度メーカーの窓口に相談してあげましょう',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[900],
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  safetyInfo.recallDetails!.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[800],
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (safetyInfo.recallDetails!.manufacturerContactUrl !=
                    null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () {
                      // URL起動（url_launcherを使用）
                    },
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('メーカー連絡先を開く'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFef4444),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 安全性スコア
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '安全性スコア',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // 円形プログレスバー
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 背景円
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey[200]!,
                            ),
                          ),
                        ),
                        // プログレス円
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: safetyInfo.safetyScore / 100,
                            strokeWidth: 8,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getSafetyScoreColor(safetyInfo.safetyScore),
                            ),
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        // スコアテキスト
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              safetyInfo.safetyScore.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: _getSafetyScoreColor(
                                    safetyInfo.safetyScore),
                              ),
                            ),
                            Text(
                              '/100',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSafetyScoreLabel(safetyInfo.safetyScore),
                        const SizedBox(height: 8),
                        Text(
                          _getSafetyScoreDescription(safetyInfo.safetyScore),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // パーツ交換アラート
        if (safetyInfo.safetyAdvice.isNotEmpty) ...[
          const SizedBox(height: 16),
          ...safetyInfo.safetyAdvice.map(
            (advice) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                border: Border.all(
                  color: Colors.amber[200]!,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      advice,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.amber[900],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 安全性スコアの色を取得
  Color _getSafetyScoreColor(double score) {
    if (score >= 80) {
      return const Color(0xFF3b82f6); // 青
    } else if (score >= 60) {
      return const Color(0xFFf59e0b); // オレンジ
    } else {
      return const Color(0xFFef4444); // 赤
    }
  }

  /// 安全性スコアのラベルを取得
  Widget _buildSafetyScoreLabel(double score) {
    String label;
    Color color;
    if (score >= 80) {
      label = '良好';
      color = const Color(0xFF3b82f6);
    } else if (score >= 60) {
      label = '注意';
      color = const Color(0xFFf59e0b);
    } else {
      label = '要確認';
      color = const Color(0xFFef4444);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: color,
          width: 0.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  /// 安全性スコアの説明を取得
  String _getSafetyScoreDescription(double score) {
    if (score >= 80) {
      return '安全性に問題はありません';
    } else if (score >= 60) {
      return '定期的な点検を推奨します';
    } else {
      return '早急な点検または交換を検討してください';
    }
  }

  /// 資産価値セクションを構築
  Widget _buildAssetValueSection(Device device) {
    // Note: Use a StatefulWidget or Parent to manage state if we want to rebuild on refresh.
    // Since DeviceDetailCard is stateless, we rely on the FutureBuilder re-executing if the future changes?
    // No, FutureBuilder doesn't re-execute if the future is created *inside* the builder logic unless parameters change.
    // However, here we are calling valuationService.calculateAssetValue everytime build happens because we construct a new Future.
    // To support Manual Refresh properly, we might need a Stateful wrapper or just navigation/modal refresh.
    // For this implementation, we'll try to rely on state update via a simple localized Stateful widget or just standard approach.
    // Given the constraints, let's inject a specialized widget for this section that handles its own state.

    return _AssetValueSection(device: device);
  }

  Widget _buildDetailSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: const Color(0xFFE5E5E5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // デバイス名
                Text(
                  device.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                // 型名
                if (device.modelNumber.isNotEmpty)
                  Text(
                    device.modelNumber,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
          // クイックアクセス（右側配置）
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // 説明書（丸型アイコン）
                _buildManualButton(context),
                const SizedBox(width: 12),
                // More
                _buildMoreButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualButton(BuildContext context) {
    final hasManual = device.manual != null && device.manual!.url.isNotEmpty;
    final hasModelNumber =
        device.modelNumber.isNotEmpty && device.manufacturer.isNotEmpty;

    return InkWell(
      onTap: hasModelNumber || hasManual ? () => _openManual(context) : null,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (hasModelNumber || hasManual)
              ? const Color(0xFF3b82f6).withValues(alpha: 0.1)
              : Colors.grey[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: (hasModelNumber || hasManual)
                ? const Color(0xFF3b82f6)
                : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          hasManual ? Icons.menu_book_outlined : Icons.add,
          size: 20,
          color: (hasModelNumber || hasManual)
              ? const Color(0xFF3b82f6)
              : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return InkWell(
      onTap: () => _showMoreDetails(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFE5E5E5),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.more_horiz,
          size: 20,
          color: Color(0xFF3b82f6),
        ),
      ),
    );
  }
}

class _AssetValueSection extends StatefulWidget {
  final Device device;

  const _AssetValueSection({required this.device});

  @override
  State<_AssetValueSection> createState() => _AssetValueSectionState();
}

class _AssetValueSectionState extends State<_AssetValueSection> {
  late Future<AssetValue> _assetValueFuture;
  final ValuationService _valuationService = ValuationService();
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData({bool forceUpdate = false}) {
    if (widget.device.assetValue != null && !forceUpdate) {
      _assetValueFuture = Future.value(widget.device.assetValue);
    } else {
      _assetValueFuture = _valuationService.calculateAssetValue(widget.device,
          forceUpdate: forceUpdate);
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    // 少し待機してUXを向上（モックでも処理感が出る）
    await Future.delayed(const Duration(milliseconds: 800));
    setState(() {
      _loadData(forceUpdate: true);
      _isRefreshing = false;
    });
  }

  void _showHelpDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content:
            Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AssetValue>(
      future: _assetValueFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }

        // データロード中は既存データがあればそれを表示しつつローディングインジケータ、なければローディング
        if (snapshot.connectionState == ConnectionState.waiting &&
            !_isRefreshing) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final calculatedAssetValue = snapshot.data!;
        final bookValue = calculatedAssetValue.bookValue ?? 0;
        final marketValue = calculatedAssetValue.marketValue ?? 0;
        final currentValue = calculatedAssetValue.currentUsedPrice;
        final hasSellOpp = calculatedAssetValue.hasSellOpportunity ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '資産価値',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_isRefreshing)
                  const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else
                  InkWell(
                    onTap: _handleRefresh,
                    borderRadius: BorderRadius.circular(16),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.refresh, size: 20, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // 売却チャンス通知
            if (hasSellOpp) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  border: Border.all(
                    color: Colors.amber[200]!,
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 24,
                      color: Colors.amber[700],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '今が売り時です：市場価値が帳簿価値を上回っています',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber[900],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 資産価値の二段構え表示
            Row(
              children: [
                Expanded(
                  child: _buildValueCard(
                    '帳簿上の価値',
                    '減価償却残高',
                    bookValue,
                    Colors.blue[50]!,
                    Colors.blue[200]!,
                    () => _showHelpDialog(
                      '帳簿上の価値（減価償却）',
                      '購入価格から、法定耐用年数に基づいて計算された価値です。\n\n時間が経つにつれて一定の割合で減少します。会計上の価値を表しており、実際の市場価格とは異なる場合があります。',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildValueCard(
                    '市場価値',
                    '中古相場',
                    marketValue,
                    Colors.green[50]!,
                    Colors.green[200]!,
                    () => _showHelpDialog(
                      '市場価値（中古相場）',
                      '現在の市場データに基づいた推定価格です。\n\n同じモデルの中古品がいくらで取引されているかを参考にしています。人気モデルや状態が良い場合は、帳簿上の価値より高くなることがあります。',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 現在の資産価値
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(
                  color: const Color(0xFFE5E5E5),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '現在の資産価値',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (calculatedAssetValue.lastPriceCheck.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            '更新: ${_formatDate(calculatedAssetValue.lastPriceCheck)}',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500]),
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '¥${_formatCurrency(currentValue)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 資産推移グラフ
            LayoutBuilder(
              builder: (context, constraints) {
                return _buildAssetChart(widget.device);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildAssetChart(Device device) {
    try {
      return AssetValueChart(device: device);
    } catch (e) {
      print('Error building asset chart: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildValueCard(
    String title,
    String subtitle,
    int value,
    Color backgroundColor,
    Color borderColor,
    VoidCallback onHelpTap,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w300,
                ),
              ),
              InkWell(
                onTap: onHelpTap,
                child:
                    Icon(Icons.help_outline, size: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¥${_formatCurrency(value)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[900],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int value) {
    final formatter = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return value
        .toString()
        .replaceAllMapped(formatter, (Match m) => '${m[1]},');
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return '${date.year}/${date.month}/${date.day}';
    } catch (e) {
      return '';
    }
  }
}
