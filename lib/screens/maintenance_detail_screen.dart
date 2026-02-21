import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../models/device.dart';
import '../models/maintenance_task.dart';
import '../services/maintenance_calendar_service.dart';
import '../services/config_service.dart';

/// お手入れ詳細画面
///
/// 通知タップ or カレンダー画面から遷移。
/// 手順を表示 → 「完了」ボタンで記録 → 3 タップで完結。
class MaintenanceDetailScreen extends StatefulWidget {
  final Device device;
  final MaintenanceTask task;
  final VoidCallback? onCompleted;

  const MaintenanceDetailScreen({
    super.key,
    required this.device,
    required this.task,
    this.onCompleted,
  });

  @override
  State<MaintenanceDetailScreen> createState() =>
      _MaintenanceDetailScreenState();
}

class _MaintenanceDetailScreenState extends State<MaintenanceDetailScreen> {
  bool _completed = false;
  Future<String>? _methodTextFuture;

  @override
  void initState() {
    super.initState();
    // initState ではまだ Provider にアクセスできないので
    // didChangeDependencies で初期化
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_methodTextFuture == null) {
      final configService = Provider.of<ConfigService>(context, listen: false);
      _methodTextFuture = MaintenanceCalendarService.getMethodText(
        widget.task,
        widget.device,
        configService,
      );
    }
  }

  void _markCompleted() {
    MaintenanceCalendarService.completeTask(widget.task);
    setState(() => _completed = true);
    widget.onCompleted?.call();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.task.name}を完了しました ✅'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    // 1.5秒後に戻る
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) Navigator.of(context).pop(true);
    });
  }

  void _openManual() async {
    final url = widget.device.manualPdfUrl;
    if (url != null && url.isNotEmpty) {
      try {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('説明書を開けませんでした')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasManual = MaintenanceCalendarService.hasManualLink(widget.device);
    final dateFormat = DateFormat('yyyy/MM/dd');

    // 優先度に応じたカラー
    Color priorityColor;
    switch (widget.task.priority) {
      case 'high':
        priorityColor = Colors.red.shade400;
        break;
      case 'medium':
        priorityColor = Colors.amber.shade600;
        break;
      default:
        priorityColor = Colors.blue.shade400;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('お手入れ'),
        backgroundColor: const Color(0xFFF8F6F0),
        foregroundColor: const Color(0xFF2C2C2C),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── デバイス名とタスク名 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: priorityColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    '🧹',
                    style: TextStyle(fontSize: 40),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.device.name,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.task.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 状態バッジ
                  if (widget.task.isOverdue)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(-widget.task.daysUntilDue)}日超過',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else if (widget.task.isDueSoon)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'あと${widget.task.daysUntilDue}日',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.amber.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── お手入れ方法 ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_fix_high, size: 18, color: priorityColor),
                      const SizedBox(width: 8),
                      const Text(
                        'お手入れ方法',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C2C2C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<String>(
                    future: _methodTextFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'お手入れ方法を生成中...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }
                      final text = snapshot.data ??
                          MaintenanceCalendarService.getMethodTextSync(
                              widget.task);
                      return Text(
                        text,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey.shade800,
                        ),
                      );
                    },
                  ),
                  if (hasManual) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: _openManual,
                      child: Row(
                        children: [
                          Icon(Icons.menu_book,
                              size: 16, color: Colors.blue.shade600),
                          const SizedBox(width: 6),
                          Text(
                            '取扱説明書を見る >>',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── スケジュール情報（タップで編集） ──
            InkWell(
              onTap: _showEditSheet,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune, size: 16, color: Colors.grey.shade400),
                        const SizedBox(width: 6),
                        Text(
                          'スケジュール設定',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '編集',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            size: 16, color: Colors.blue.shade400),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      '実施間隔',
                      _formatInterval(widget.task.intervalDays),
                      Icons.repeat,
                    ),
                    if (widget.task.lastCompleted != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        '前回実施',
                        dateFormat.format(widget.task.lastCompleted!),
                        Icons.history,
                      ),
                    ],
                    if (widget.task.nextDue != null) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        '次回予定',
                        dateFormat.format(widget.task.nextDue!),
                        Icons.event,
                      ),
                    ],
                    const Divider(height: 24),
                    _buildInfoRow(
                      '優先度',
                      _priorityLabel(widget.task.priority),
                      Icons.flag,
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Icon(Icons.notifications_outlined,
                            size: 18, color: Colors.grey.shade500),
                        const SizedBox(width: 10),
                        Text(
                          '通知',
                          style: TextStyle(
                              fontSize: 14, color: Colors.grey.shade600),
                        ),
                        const Spacer(),
                        Text(
                          widget.task.notifyEnabled ? 'オン' : 'オフ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: widget.task.notifyEnabled
                                ? Colors.green.shade600
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                    if (widget.task.history.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow(
                        '累計実施回数',
                        '${widget.task.history.length}回',
                        Icons.check_circle_outline,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── 完了ボタン ──
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _completed ? null : _markCompleted,
                icon: Icon(_completed ? Icons.check : Icons.done_all),
                label: Text(
                  _completed ? '完了しました ✅' : 'お手入れ完了',
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _completed ? Colors.grey.shade300 : Colors.green.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: _completed ? 0 : 2,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── 間隔の表示フォーマット ──
  String _formatInterval(int days) {
    if (days % 365 == 0) return '${days ~/ 365}年ごと';
    if (days % 30 == 0) return '${days ~/ 30}ヶ月ごと';
    if (days % 7 == 0) return '${days ~/ 7}週間ごと';
    return '$days日ごと';
  }

  // ── 優先度ラベル ──
  String _priorityLabel(String priority) {
    switch (priority) {
      case 'high':
        return '🔴 高';
      case 'medium':
        return '🟡 中';
      case 'low':
        return '🟢 低';
      default:
        return '⚪ 未設定';
    }
  }

  // ── 設定編集ボトムシート ──
  void _showEditSheet() {
    final task = widget.task;
    int tempInterval = task.intervalDays;
    String tempPriority = task.priority;
    bool tempNotify = task.notifyEnabled;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ハンドル
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'スケジュール設定',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C2C2C),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 実施間隔 ──
                  Text(
                    '実施間隔',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _intervalChip(7, '1週間', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(14, '2週間', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(30, '1ヶ月', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(60, '2ヶ月', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(90, '3ヶ月', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(180, '6ヶ月', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                      _intervalChip(365, '1年', tempInterval, (v) {
                        setSheetState(() => tempInterval = v);
                      }),
                    ],
                  ),

                  // カスタム入力 or 推奨間隔の警告
                  if (![7, 14, 30, 60, 90, 180, 365]
                      .contains(tempInterval)) ...[
                    const SizedBox(height: 8),
                    Text(
                      'カスタム: ${_formatInterval(tempInterval)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  // 推奨間隔との比較表示
                  if (tempInterval > task.recommendedIntervalDays) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 16, color: Colors.amber.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'メーカー推奨は${_formatInterval(task.recommendedIntervalDays)}です。間隔を長くすると資産価値に影響する可能性があります。',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (tempInterval == task.recommendedIntervalDays) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green.shade400),
                        const SizedBox(width: 4),
                        Text(
                          'メーカー推奨の間隔です',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── 優先度 ──
                  Text(
                    '優先度',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _priorityChip('high', '高', Colors.red, tempPriority, (v) {
                        setSheetState(() => tempPriority = v);
                      }),
                      const SizedBox(width: 8),
                      _priorityChip('medium', '中', Colors.amber, tempPriority,
                          (v) {
                        setSheetState(() => tempPriority = v);
                      }),
                      const SizedBox(width: 8),
                      _priorityChip('low', '低', Colors.green, tempPriority,
                          (v) {
                        setSheetState(() => tempPriority = v);
                      }),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 優先度の通知挙動説明
                  Text(
                    tempPriority == 'high'
                        ? '📢 3日前・当日・超過後毎日リマインド'
                        : tempPriority == 'medium'
                            ? '🔔 当日のみ・超過後3日おきリマインド'
                            : '🔕 通知なし（バッジ表示のみ）',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 通知 ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'リマインダー通知',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Switch(
                        value: tempNotify,
                        activeTrackColor: Colors.green.shade600,
                        onChanged: (v) {
                          setSheetState(() => tempNotify = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── 保存ボタン ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          task.updateInterval(tempInterval);
                          task.priority = tempPriority;
                          task.notifyEnabled = tempNotify;
                        });
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('設定を保存しました'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C2C2C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '保存する',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _intervalChip(
      int days, String label, int selected, ValueChanged<int> onTap) {
    final isSelected = selected == days;
    return GestureDetector(
      onTap: () => onTap(days),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2C2C2C) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF2C2C2C),
          ),
        ),
      ),
    );
  }

  Widget _priorityChip(String value, String label, MaterialColor color,
      String selected, ValueChanged<String> onTap) {
    final isSelected = selected == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color.shade400 : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color.shade700 : Colors.grey.shade500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2C2C2C),
          ),
        ),
      ],
    );
  }
}
