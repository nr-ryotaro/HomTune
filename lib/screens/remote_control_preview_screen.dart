import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../utils/platform_support.dart';
import '../data/remote_control_preview_data.dart';
import '../models/device.dart';
import '../models/device_remote_link.dart';
import '../models/remote_appliance.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import '../widgets/registration/remote_compatibility_hint.dart';
import '../widgets/remote_control/remote_control_panel.dart';
import 'device_registration_remote_prompt_screen.dart';
import 'remote_account_screen.dart';
import 'remote_link_wizard_screen.dart';

/// リモコン UI の画面設計プレビュー（開発者向け）
class RemoteControlPreviewScreen extends StatefulWidget {
  const RemoteControlPreviewScreen({super.key});

  @override
  State<RemoteControlPreviewScreen> createState() =>
      _RemoteControlPreviewScreenState();
}

class _RemoteControlPreviewScreenState extends State<RemoteControlPreviewScreen> {
  RemoteControlPreviewScenario _scenario =
      RemoteControlPreviewScenario.airconLinked;
  bool _showRegistrationHint = true;
  bool _showReminderMock = true;
  bool _simulateSending = false;
  String? _lastAction;

  void _onCommand(
    RemoteCommandType type, {
    String? signalId,
    Map<String, dynamic>? parameters,
  }) {
    setState(() {
      _simulateSending = true;
      final paramStr =
          parameters != null && parameters.isNotEmpty ? ' $parameters' : '';
      _lastAction = signalId != null
          ? '${type.name} ($signalId$paramStr)'
          : '${type.name}$paramStr';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _simulateSending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode && !PlatformSupport.isWebUiPreview) {
      return const Scaffold(
        body: Center(child: Text('プレビューは Web またはデバッグビルドでのみ利用できます')),
      );
    }

    final previewDevice = _scenario.previewDevice();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'リモコン UI プレビュー',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildInfoBanner(),
          const SizedBox(height: 20),
          _buildSectionTitle('家電詳細 — リモコン操作'),
          const SizedBox(height: 8),
          _buildScenarioPicker(),
          const SizedBox(height: 16),
          _buildDeviceDetailMock(previewDevice),
          const SizedBox(height: 24),
          _buildSectionTitle('登録フロー UI'),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('登録フォームのヒント'),
            value: _showRegistrationHint,
            onChanged: (v) => setState(() => _showRegistrationHint = v),
          ),
          if (_showRegistrationHint)
            RemoteCompatibilityHint(
              assessment: RemoteControlPreviewData.airconAssessment(),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('設定リマインダー（モック）'),
            value: _showReminderMock,
            onChanged: (v) => setState(() => _showReminderMock = v),
          ),
          if (_showReminderMock) _buildReminderMock(),
          const SizedBox(height: 12),
          _buildFlowButtons(previewDevice),
          if (_lastAction != null) ...[
            const SizedBox(height: 16),
            Text(
              '最後の操作（プレビュー）: $_lastAction',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Text(
        'API 連携なしでリモコン UI の見た目と遷移を確認できます。'
        'シナリオを切り替えて Free / Pro / 家電種別を比較してください。',
        style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), height: 1.45),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF666666),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildScenarioPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: RemoteControlPreviewScenario.values.map((scenario) {
        final selected = _scenario == scenario;
        return ChoiceChip(
          label: Text(scenario.label),
          selected: selected,
          onSelected: (_) => setState(() => _scenario = scenario),
          selectedColor: const Color(0xFFDBEAFE),
        );
      }).toList(),
    );
  }

  Widget _buildDeviceDetailMock(Device device) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _iconForDevice(device),
                size: 20,
                color: const Color(0xFF333333),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${device.manufacturer} · 型番 ${device.modelNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          RemoteControlPanel(
            isPro: _scenario.isPro,
            device: device,
            link: _scenario.link,
            remainingMonthlyQuota: _scenario.isPro ? 287 : null,
            sending: _simulateSending,
            onProTap: () => showProUpgradeDialog(
              context,
              upsellContext: ProUpsellContext.remoteControl,
              deviceName: device.name,
              deviceCategoryLabel: device.category,
            ),
            onLinkTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => RemoteLinkWizardScreen(device: device),
                ),
              );
            },
            onCommand: _onCommand,
          ),
        ],
      ),
    );
  }

  IconData _iconForDevice(Device device) {
    final profile = device.remoteLink?.profile;
    switch (profile) {
      case RemoteCapabilityProfile.tv:
        return Icons.tv;
      case RemoteCapabilityProfile.light:
        return Icons.lightbulb_outline;
      case RemoteCapabilityProfile.bot:
        return Icons.smart_toy_outlined;
      case RemoteCapabilityProfile.curtain:
        return Icons.curtains;
      default:
        return Icons.ac_unit;
    }
  }

  Widget _buildReminderMock() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sensors, size: 20, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'リモコン設定が未完了です',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${RemoteControlPreviewData.sampleAircon().name}（エアコン）ほか、スマートリモコン連携が可能です',
            style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(onPressed: () {}, child: const Text('あとで')),
              const Spacer(),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 36),
                ),
                child: const Text('今すぐ設定'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFlowButtons(Device device) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                fullscreenDialog: true,
                builder: (_) => DeviceRegistrationRemotePromptScreen(
                  device: device,
                  assessment: RemoteControlPreviewData.airconAssessment(),
                ),
              ),
            );
          },
          icon: const Icon(Icons.celebration_outlined, size: 18),
          label: const Text('登録後プロンプトを開く'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RemoteLinkWizardScreen(device: device),
              ),
            );
          },
          icon: const Icon(Icons.link, size: 18),
          label: const Text('紐付けウィザードを開く'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RemoteAccountScreen(),
              ),
            );
          },
          icon: const Icon(Icons.sensors, size: 18),
          label: const Text('アカウント連携画面を開く'),
        ),
      ],
    );
  }
}
