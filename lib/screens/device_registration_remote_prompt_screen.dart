import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_usage_policy.dart';
import '../models/device.dart';
import '../models/remote_compatibility_assessment.dart';
import '../services/analytics_service.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/remote_control/remote_control_service.dart';
import '../services/remote_control/remote_setup_reminder_prefs.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import 'remote_account_screen.dart';
import 'remote_link_wizard_screen.dart';

/// 家電登録直後: リモコン対応確認 → Pro 訴求 → 設定へ誘導
class DeviceRegistrationRemotePromptScreen extends StatefulWidget {
  final Device device;
  final RemoteCompatibilityAssessment assessment;

  const DeviceRegistrationRemotePromptScreen({
    super.key,
    required this.device,
    required this.assessment,
  });

  @override
  State<DeviceRegistrationRemotePromptScreen> createState() =>
      _DeviceRegistrationRemotePromptScreenState();
}

class _DeviceRegistrationRemotePromptScreenState
    extends State<DeviceRegistrationRemotePromptScreen> {
  bool _checkingIntegration = true;
  bool _hasRemo = false;
  bool _hasSwitchBot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logShown();
      _checkIntegrations();
    });
  }

  Future<void> _logShown() async {
    await AnalyticsService.logEvent(
      event: 'remote_registration_prompt_shown',
      properties: {
        'deviceId': widget.device.id,
        'profile': widget.assessment.profile?.name ?? '',
        'source': widget.assessment.source.name,
      },
    );
  }

  Future<void> _checkIntegrations() async {
    final config = Provider.of<ConfigService>(context, listen: false);
    final remote = Provider.of<RemoteControlService>(context, listen: false);
    try {
      await remote.refreshIntegrationStatus(config);
    } catch (_) {
      // オフライン等は未連携扱い
    }
    if (!mounted) return;
    setState(() {
      _hasRemo = remote.remoStatus?.linked == true;
      _hasSwitchBot = remote.switchbotStatus?.linked == true;
      _checkingIntegration = false;
    });
  }

  Device get _device {
    final svc = Provider.of<DeviceService>(context, listen: false);
    return svc.getDeviceById(widget.device.id) ?? widget.device;
  }

  Future<void> _onProUpgrade() async {
    await AnalyticsService.logEvent(
      event: 'remote_registration_pro_tap',
      properties: {'deviceId': widget.device.id},
    );
    if (!mounted) return;
    await showProUpgradeDialog(
      context,
      upsellContext: ProUpsellContext.remoteControl,
      deviceName: _device.name,
      deviceCategoryLabel: widget.assessment.label,
    );
  }

  Future<void> _openAccountLink() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RemoteAccountScreen()),
    );
    await _checkIntegrations();
  }

  Future<void> _openLinkWizard() async {
    final linked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RemoteLinkWizardScreen(device: _device),
      ),
    );
    if (linked == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _onLater() async {
    await RemoteSetupReminderPrefs.snoozeDevice(widget.device.id);
    await AnalyticsService.logEvent(
      event: 'remote_registration_later',
      properties: {'deviceId': widget.device.id},
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(onPressed: _onLater, child: const Text('あとで')),
        ],
      ),
      body: Consumer<ConfigService>(
        builder: (context, config, _) {
          final isPro = config.subscriptionTier == SubscriptionTier.pro;
          final hasIntegration = _hasRemo || _hasSwitchBot;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(
                          Icons.celebration_outlined,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '登録完了',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _device.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCompatibilityCard(),
                        const SizedBox(height: 20),
                        if (!isPro)
                          _buildProRecommendation()
                        else
                          _buildProSetupSteps(hasIntegration),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isPro) ...[
                        FilledButton(
                          onPressed: _onProUpgrade,
                          child: const Text('Pro でリモコン操作を有効にする'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _onLater,
                          child: const Text('今はスキップ'),
                        ),
                      ] else ...[
                        if (_checkingIntegration)
                          const Center(child: CircularProgressIndicator())
                        else if (!hasIntegration)
                          FilledButton(
                            onPressed: _openAccountLink,
                            child: const Text('Remo / SwitchBot を連携する'),
                          )
                        else
                          FilledButton(
                            onPressed: _openLinkWizard,
                            child: const Text('この家電にリモコンを紐付ける'),
                          ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _onLater,
                          child: const Text('あとで設定する'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompatibilityCard() {
    final a = widget.assessment;
    final profileLabel = a.label ?? 'IR 対応家電';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, size: 18, color: Color(0xFF2563EB)),
              const SizedBox(width: 8),
              Text(
                profileLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            a.userMessage ?? a.registrationHint,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF475569),
              height: 1.45,
            ),
          ),
          if (_device.modelNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '型番: ${_device.modelNumber}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProRecommendation() {
    final label = widget.assessment.label ?? _device.category;
    final deviceTitle = _device.name.isNotEmpty ? _device.name : label;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 18, color: Color(0xFFEA580C)),
              SizedBox(width: 8),
              Text(
                'この家電をスマホから操作',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF9A3412),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Pro なら $deviceTitle を Remo / SwitchBot と紐付けて、\n'
            'アプリやチャットから操作できます。',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C2D12),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            '• ワンタップで電源 ON/OFF・温度調整\n'
            '• 「リビングのエアコンつけて」とチャット操作\n'
            '• 月 300 回まで（Pro 限定）',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF7C2D12),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProSetupSteps(bool hasIntegration) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepRow(
          done: true,
          title: '家電を登録',
          subtitle: '型番 ${_device.modelNumber.isNotEmpty ? _device.modelNumber : "—"}',
        ),
        _stepRow(
          done: hasIntegration,
          title: 'Remo / SwitchBot を連携',
          subtitle: hasIntegration ? '連携済み' : 'アカウントトークンを登録',
        ),
        _stepRow(
          done: _device.remoteLink != null,
          title: '家電にリモコンを紐付け',
          subtitle: '登録した IR 家電を選択',
        ),
      ],
    );
  }

  Widget _stepRow({
    required bool done,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 20,
            color: done ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: done
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
