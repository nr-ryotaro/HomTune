import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/ai_usage_policy.dart';
import '../services/config_service.dart';
import '../services/remote_control/remote_control_policy.dart';
import '../services/remote_control/remote_control_service.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';

/// スマートリモコン連携（Remo / SwitchBot アカウント）
class RemoteAccountScreen extends StatefulWidget {
  const RemoteAccountScreen({super.key});

  @override
  State<RemoteAccountScreen> createState() => _RemoteAccountScreenState();
}

class _RemoteAccountScreenState extends State<RemoteAccountScreen> {
  final _remoTokenController = TextEditingController();
  final _sbTokenController = TextEditingController();
  final _sbSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _remoTokenController.dispose();
    _sbTokenController.dispose();
    _sbSecretController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final config = Provider.of<ConfigService>(context, listen: false);
    final remote = Provider.of<RemoteControlService>(context, listen: false);
    await remote.refreshIntegrationStatus(config);
  }

  @override
  Widget build(BuildContext context) {
    if (!RemoteControlPolicy.supportsRemoteControlUi) {
      return Scaffold(
        appBar: AppBar(title: const Text('スマートリモコン')),
        body: const Center(child: Text('この環境では利用できません')),
      );
    }

    if (RemoteControlPolicy.simulatesCommands) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'スマートリモコン連携',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_remote, size: 48, color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                const Text(
                  'Web プレビューではアカウント連携はできません。\n'
                  'リモコン UI の見た目は「リモコン UI」画面または家電詳細で確認できます。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'スマートリモコン連携',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer2<ConfigService, RemoteControlService>(
        builder: (context, config, remote, _) {
          final isPro = config.subscriptionTier == SubscriptionTier.pro;
          if (!isPro) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 48),
                    const SizedBox(height: 16),
                    const Text(
                      'リモコン連携は Pro プラン限定です',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => showProUpgradeDialog(context),
                      child: const Text('Pro の詳細'),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'API トークンは HomTune サーバーにのみ保存されます（開発時はローカルプロキシ）。',
                  style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                ),
                const SizedBox(height: 24),
                _sectionTitle('Nature Remo'),
                if (remote.remoStatus?.linked == true)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('連携済み'),
                    subtitle: Text(
                      '残り操作 ${remote.remoStatus?.remainingMonthlyQuota ?? 0} 回/月',
                    ),
                    trailing: TextButton(
                      onPressed: remote.isLoading
                          ? null
                          : () async {
                              await remote.unlinkRemo(config);
                              if (mounted) setState(() {});
                            },
                      child: const Text('解除'),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _remoTokenController,
                    decoration: const InputDecoration(
                      labelText: 'Remo アクセストークン',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: remote.isLoading
                        ? null
                        : () async {
                            await remote.linkRemo(
                              config,
                              _remoTokenController.text.trim(),
                            );
                            if (mounted) setState(() {});
                          },
                    child: const Text('Remo を連携'),
                  ),
                ],
                const SizedBox(height: 32),
                _sectionTitle('SwitchBot'),
                if (remote.switchbotStatus?.linked == true)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('連携済み'),
                    trailing: TextButton(
                      onPressed: remote.isLoading
                          ? null
                          : () async {
                              await remote.unlinkSwitchBot(config);
                              if (mounted) setState(() {});
                            },
                      child: const Text('解除'),
                    ),
                  )
                else ...[
                  TextField(
                    controller: _sbTokenController,
                    decoration: const InputDecoration(
                      labelText: 'SwitchBot Token',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _sbSecretController,
                    decoration: const InputDecoration(
                      labelText: 'SwitchBot Secret',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: remote.isLoading
                        ? null
                        : () async {
                            await remote.linkSwitchBot(
                              config,
                              token: _sbTokenController.text.trim(),
                              secret: _sbSecretController.text.trim(),
                            );
                            if (mounted) setState(() {});
                          },
                    child: const Text('SwitchBot を連携'),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
