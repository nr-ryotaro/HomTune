import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appliance_archetype.dart';
import '../services/appliance_template_service.dart';
import '../services/device_service.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_photo_service.dart';
import '../utils/platform_support.dart';
import '../widgets/appliance_compact_card.dart';
import '../widgets/appliance_registration_option.dart';
import 'add_device_screen.dart';
import 'scan_screen.dart';
import 'web_unsupported_feature_screen.dart';

/// 「家電を追加」から開く登録ハブ（スキャン / 手入力 / テンプレ家電）
class AddApplianceScreen extends StatefulWidget {
  final String? initialRoomId;

  const AddApplianceScreen({super.key, this.initialRoomId});

  @override
  State<AddApplianceScreen> createState() => _AddApplianceScreenState();
}

class _AddApplianceScreenState extends State<AddApplianceScreen> {
  List<({ApplianceArchetype archetype, SelectedArchetypeRef ref})>
      _suggestions = [];
  bool _loading = true;
  bool _applianceSetupDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _applianceSetupDone = await RoomPhotoService.isApplianceSetupDone();
    await _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    setState(() => _loading = true);
    final selected = await OnboardingPrefs.getSelectedArchetypes();
    if (!mounted) return;
    if (selected.isEmpty) {
      setState(() {
        _suggestions = [];
        _loading = false;
      });
      return;
    }
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final unregistered = await ApplianceTemplateService.instance
        .getUnregisteredSuggestions(
      selected: selected,
      registeredCategories:
          deviceService.devices.map((d) => d.category).toList(),
      registeredNames: deviceService.devices.map((d) => d.name).toList(),
    );
    if (!mounted) return;
    setState(() {
      _suggestions = unregistered;
      _loading = false;
    });
  }

  Future<void> _afterRegistration() async {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    await deviceService.loadData();
    await _loadSuggestions();
  }

  Future<void> _openScan() async {
    if (!PlatformSupport.supportsSmartIngester) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => WebUnsupportedFeatureScreen(
            featureName: 'Smart Ingester',
            initialRoomId: widget.initialRoomId,
          ),
        ),
      );
      return;
    }
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ScanScreen(initialRoomId: widget.initialRoomId),
      ),
    );
    if (registered == true && mounted) {
      await _afterRegistration();
    }
  }

  Future<void> _openManualEntry({String? roomId, ApplianceArchetype? archetype}) async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddDeviceScreen(
          initialRoomId: roomId ?? widget.initialRoomId,
          initialArchetypeId: archetype?.id,
          initialCategory: archetype?.category,
          initialName: archetype?.displayName,
        ),
      ),
    );
    if (registered == true && mounted) {
      await _afterRegistration();
    }
  }

  Future<void> _finishRegistrationPhase() async {
    await RoomPhotoService.setApplianceSetupDone(true);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(
          '家電を追加',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(color: const Color(0xFFE5E5E5), height: 0.5),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '登録方法を選ぶ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'バーコードを読み取るか、型番を手入力して登録できます。',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF999999),
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (PlatformSupport.supportsSmartIngester) ...[
                    ApplianceRegistrationOption(
                      icon: Icons.qr_code_scanner,
                      title: 'バーコードスキャン',
                      subtitle: 'おすすめ — 撮るだけで自動登録',
                      isRecommended: true,
                      onTap: _openScan,
                    ),
                    const SizedBox(height: 12),
                  ],
                  ApplianceRegistrationOption(
                    icon: Icons.keyboard_alt_outlined,
                    title: '型番を入力',
                    subtitle: PlatformSupport.supportsSmartIngester
                        ? '手動で家電情報を入力'
                        : 'Web プレビューではこちらから登録',
                    isRecommended: !PlatformSupport.supportsSmartIngester,
                    onTap: () => _openManualEntry(),
                  ),
                  if (_suggestions.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      '登録したい家電',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'オンボーディングで選んだ家電です。タップして型番を登録できます。',
                      style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: ApplianceCompactCard.cardHeight,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final item = _suggestions[index];
                          final a = item.archetype;
                          return ApplianceCompactCard(
                            icon: a.icon,
                            title: a.displayName,
                            onTap: () => _openManualEntry(
                              roomId: item.ref.roomId,
                              archetype: a,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (!_applianceSetupDone) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: _finishRegistrationPhase,
                        child: const Text('登録はいったん完了 →'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
