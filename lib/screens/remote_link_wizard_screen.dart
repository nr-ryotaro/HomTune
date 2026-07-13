import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../models/device_remote_link.dart';
import '../models/remote_appliance.dart';
import '../models/remote_compatibility_assessment.dart';
import '../services/analytics_service.dart';
import '../services/config_service.dart';
import '../services/device_service.dart';
import '../services/remote_control/remote_appliance_ranker.dart';
import '../services/remote_control/remote_compatibility_service.dart';
import '../services/remote_control/remote_control_service.dart';
import '../services/remote_control/remote_setup_reminder_prefs.dart';
import 'remote_account_screen.dart';

class RemoteLinkWizardScreen extends StatefulWidget {
  final Device device;

  const RemoteLinkWizardScreen({super.key, required this.device});

  @override
  State<RemoteLinkWizardScreen> createState() => _RemoteLinkWizardScreenState();
}

class _RemoteLinkWizardScreenState extends State<RemoteLinkWizardScreen> {
  RemoteProvider _provider = RemoteProvider.remo;
  List<RankedRemoteAppliance> _ranked = [];
  RemoteAppliance? _selected;
  RemoteCompatibilityAssessment? _assessment;
  bool _loading = false;
  bool _testing = false;
  bool _showAllAppliances = false;
  bool _canTestSelected = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAppliances();
  }

  Future<void> _loadAppliances() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final config = Provider.of<ConfigService>(context, listen: false);
    final remote = Provider.of<RemoteControlService>(context, listen: false);

    _assessment = await RemoteCompatibilityService.instance.assess(
      modelNumber: widget.device.modelNumber,
      category: widget.device.category,
      manufacturer: widget.device.manufacturer,
      archetypeId: widget.device.archetypeId,
    );

    try {
      final list = _provider == RemoteProvider.remo
          ? await remote.fetchRemoAppliances(config)
          : await remote.fetchSwitchBotAppliances(config);

      final ranked = RemoteApplianceRanker.rank(
        device: widget.device,
        appliances: list,
        assessment: _assessment,
      );

      RemoteAppliance? selected;
      for (final r in ranked) {
        if (r.isRecommended) {
          selected = r.appliance;
          break;
        }
      }
      selected ??= ranked.isNotEmpty ? ranked.first.appliance : null;

      if (!mounted) return;
      _updateSelection(selected, ranked);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _ranked = [];
        _selected = null;
        _canTestSelected = false;
      });
    }
  }

  void _updateSelection(RemoteAppliance? selected, List<RankedRemoteAppliance> ranked) {
    final remote = Provider.of<RemoteControlService>(context, listen: false);
    final canTest = selected != null &&
        remote.safeTestCommandType(selected.profile) != null;
    setState(() {
      _ranked = ranked;
      _selected = selected;
      _loading = false;
      _canTestSelected = canTest;
      _showAllAppliances = ranked.length <= 2 ||
          (ranked.isNotEmpty &&
              ranked.first.score < RemoteApplianceRanker.recommendThreshold);
    });
  }

  List<RankedRemoteAppliance> get _recommended {
    return _ranked.where((r) => r.isRecommended).toList();
  }

  List<RankedRemoteAppliance> get _others {
    if (_recommended.isEmpty) return _ranked;
    final recommendedIds = _recommended.map((r) => r.appliance.id).toSet();
    return _ranked.where((r) => !recommendedIds.contains(r.appliance.id)).toList();
  }

  Future<void> _sendTest() async {
    if (_selected == null || _testing) return;
    setState(() => _testing = true);
    final config = Provider.of<ConfigService>(context, listen: false);
    final remote = Provider.of<RemoteControlService>(context, listen: false);

    try {
      final result = await remote.sendTestCommandForAppliance(
        config,
        widget.device,
        _selected!,
      );
      final rank = _ranked.indexWhere((r) => r.appliance.id == _selected!.id);
      await AnalyticsService.logEvent(
        event: 'remote_link_test_success',
        properties: {
          'deviceId': widget.device.id,
          'provider': _selected!.provider.name,
          'success': result.success,
          'suggestionRank': rank >= 0 ? rank + 1 : 0,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? 'テスト信号を送信しました（電源 OFF）'
                : (result.message ?? 'テスト送信に失敗しました'),
          ),
        ),
      );
    } on RemoteControlException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _saveLink() async {
    if (_selected == null) return;
    final remote = Provider.of<RemoteControlService>(context, listen: false);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final link = remote.buildLinkFromAppliance(_selected!);
    final updated = widget.device.copyWith(remoteLink: link);
    await deviceService.updateDevice(updated);
    await RemoteSetupReminderPrefs.clearSnooze(widget.device.id);

    final rank = _ranked.indexWhere((r) => r.appliance.id == _selected!.id);
    await AnalyticsService.logEvent(
      event: 'remote_link_wizard_complete',
      properties: {
        'deviceId': widget.device.id,
        'provider': _selected!.provider.name,
        'suggestionRank': rank >= 0 ? rank + 1 : 0,
        'score': rank >= 0 ? _ranked[rank].score : 0,
      },
    );

    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('リモコン紐付け'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.device.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            if (widget.device.modelNumber.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                '型番: ${widget.device.modelNumber}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
            const SizedBox(height: 16),
            SegmentedButton<RemoteProvider>(
              segments: const [
                ButtonSegment(value: RemoteProvider.remo, label: Text('Remo')),
                ButtonSegment(
                  value: RemoteProvider.switchbot,
                  label: Text('SwitchBot'),
                ),
              ],
              selected: {_provider},
              onSelectionChanged: (s) {
                setState(() {
                  _provider = s.first;
                  _ranked = [];
                  _selected = null;
                  _showAllAppliances = false;
                });
                _loadAppliances();
              },
            ),
            const SizedBox(height: 16),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: Colors.red)),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const RemoteAccountScreen(),
                    ),
                  );
                },
                child: const Text('アカウント連携を開く'),
              ),
            ],
            if (!_loading && _error == null && _ranked.isEmpty)
              const Text('家電が見つかりません。先に Remo / SwitchBot 側で登録してください。'),
            Expanded(
              child: !_loading && _error == null && _ranked.isNotEmpty
                  ? ListView(
                      children: [
                        if (_recommended.isNotEmpty) ...[
                          const Text(
                            'おすすめ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ..._recommended.map(_buildRankedTile),
                        ],
                        if (_others.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => setState(
                              () => _showAllAppliances = !_showAllAppliances,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  Text(
                                    _showAllAppliances || _recommended.isEmpty
                                        ? 'すべての家電'
                                        : 'その他の家電を表示（${_others.length}件）',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Icon(
                                    _showAllAppliances || _recommended.isEmpty
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 18,
                                    color: const Color(0xFF64748B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showAllAppliances || _recommended.isEmpty)
                            ..._others.map(_buildRankedTile),
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            if (_canTestSelected) ...[
              OutlinedButton.icon(
                onPressed: _testing ? null : _sendTest,
                icon: _testing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow_outlined, size: 18),
                label: const Text('テスト送信（電源 OFF）'),
              ),
              const SizedBox(height: 8),
              const Text(
                '紐付け前に安全な信号だけ送信します',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: _selected == null ? null : _saveLink,
              child: const Text('この家電に紐付ける'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankedTile(RankedRemoteAppliance ranked) {
    final a = ranked.appliance;
    return RadioListTile<RemoteAppliance>(
      value: a,
      groupValue: _selected,
      onChanged: (v) {
        if (v == null) return;
        final remote = Provider.of<RemoteControlService>(context, listen: false);
        setState(() {
          _selected = v;
          _canTestSelected =
              remote.safeTestCommandType(v.profile) != null;
        });
      },
      title: Row(
        children: [
          Expanded(child: Text(a.nickname)),
          if (ranked.isRecommended)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'おすすめ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${a.provider.name} · ${a.profile.name}'
        '${ranked.score > 0 ? ' · 一致度 ${ranked.score}' : ''}',
      ),
    );
  }
}
