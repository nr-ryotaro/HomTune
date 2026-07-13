import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/device.dart';
import '../models/manufacturer_bundle.dart';
import '../services/device_service.dart';
import '../services/manufacturer_bundle_service.dart';
import '../services/room_photo_service.dart';
import '../utils/registration_remote_flow.dart';
import '../widgets/appliance_compact_card.dart';

/// メーカーセット一括登録の確認・実行画面
class ManufacturerBundlePickerScreen extends StatefulWidget {
  final String? initialRoomTemplateId;

  const ManufacturerBundlePickerScreen({
    super.key,
    this.initialRoomTemplateId,
  });

  @override
  State<ManufacturerBundlePickerScreen> createState() =>
      _ManufacturerBundlePickerScreenState();
}

class _ManufacturerBundlePickerScreenState
    extends State<ManufacturerBundlePickerScreen> {
  List<ManufacturerBundle> _bundles = [];
  bool _loading = true;
  bool _registering = false;
  String? _filterRoomId;

  @override
  void initState() {
    super.initState();
    _filterRoomId = widget.initialRoomTemplateId;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final roomIds = deviceService.rooms.map((r) => r.id).toList();
    final templateRoomIds = _templateRoomIdsFromUserRooms(roomIds);
    final bundles = await ManufacturerBundleService.instance.availableBundles(
      registeredDevices: deviceService.devices,
      roomTemplateIds: templateRoomIds,
    );
    if (!mounted) return;
    setState(() {
      _bundles = _filterRoomId == null
          ? bundles
          : bundles
              .where((b) =>
                  b.primaryRoomId == _filterRoomId ||
                  b.devices.any((d) => d.roomId == _filterRoomId))
              .toList();
      _loading = false;
    });
  }

  List<String> _templateRoomIdsFromUserRooms(List<String> userRoomIds) {
    final templates = <String>{};
    for (final id in userRoomIds) {
      final lower = id.toLowerCase();
      if (lower.contains('living')) templates.add('living-room');
      if (lower.contains('kitchen')) templates.add('kitchen-01');
      if (lower.contains('bedroom')) templates.add('bedroom-01');
    }
    if (templates.isEmpty) {
      return ['living-room', 'kitchen-01', 'bedroom-01'];
    }
    return templates.toList();
  }

  Color _parseColor(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length == 6) {
      return Color(int.parse('FF$cleaned', radix: 16));
    }
    return const Color(0xFF333333);
  }

  Future<void> _confirmAndRegister(ManufacturerBundle bundle) async {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final pending = ManufacturerBundleService.instance
        .pendingDevicesInBundle(bundle, deviceService.devices);
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('このセットはすべて登録済みです')),
      );
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => _BundleConfirmSheet(
        bundle: bundle,
        pendingDevices: pending,
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _registering = true);
    try {
      final items = ManufacturerBundleService.instance.buildRegistrationItems(
        bundle: bundle,
        userRooms: deviceService.rooms,
        registeredDevices: deviceService.devices,
      );
      final added = await deviceService.addDevices(items);
      if (mounted) {
        await RoomPhotoService.setApplianceSetupDone(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${added.length}台を「${bundle.label}」として登録しました'),
            action: SnackBarAction(
              label: '部屋の写真へ',
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop(true);
                }
              },
            ),
          ),
        );
      }

      final firstRemoteCandidate =
          added.isNotEmpty ? added.first : null;
      if (firstRemoteCandidate != null && mounted) {
        await maybeShowRemoteRegistrationPrompt(
          context,
          device: firstRemoteCandidate,
        );
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('登録に失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      appBar: AppBar(
        title: const Text(
          'メーカーセットで追加',
          style: TextStyle(fontWeight: FontWeight.w300, letterSpacing: -0.5),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: const Text(
                    '主要メーカーの代表機種をまとめて登録できます。型番・購入価格は参考値です。あとから編集できます。',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF888888),
                      height: 1.5,
                    ),
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _RoomFilterChip(
                        label: 'すべて',
                        selected: _filterRoomId == null,
                        onTap: () {
                          setState(() => _filterRoomId = null);
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoomFilterChip(
                        label: 'リビング',
                        selected: _filterRoomId == 'living-room',
                        onTap: () {
                          setState(() => _filterRoomId = 'living-room');
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoomFilterChip(
                        label: 'キッチン',
                        selected: _filterRoomId == 'kitchen-01',
                        onTap: () {
                          setState(() => _filterRoomId = 'kitchen-01');
                          _load();
                        },
                      ),
                      const SizedBox(width: 8),
                      _RoomFilterChip(
                        label: '寝室',
                        selected: _filterRoomId == 'bedroom-01',
                        onTap: () {
                          setState(() => _filterRoomId = 'bedroom-01');
                          _load();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _bundles.isEmpty
                      ? const Center(
                          child: Text(
                            '登録できるセットがありません',
                            style: TextStyle(color: Color(0xFF999999)),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                          itemCount: _bundles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final bundle = _bundles[index];
                            return _BundleCard(
                              bundle: bundle,
                              accent: _parseColor(bundle.accentColor),
                              registering: _registering,
                              onTap: () => _confirmAndRegister(bundle),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _RoomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RoomFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: const Color(0xFFE8F0FE),
      checkmarkColor: const Color(0xFF1565C0),
    );
  }
}

class _BundleCard extends StatelessWidget {
  final ManufacturerBundle bundle;
  final Color accent;
  final bool registering;
  final VoidCallback onTap;

  const _BundleCard({
    required this.bundle,
    required this.accent,
    required this.registering,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final pending = ManufacturerBundleService.instance
        .pendingDevicesInBundle(bundle, deviceService.devices);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: registering ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(bundle.icon, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bundle.tagline,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${pending.length}台を登録（全${bundle.deviceCount}台中）',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _BundleConfirmSheet extends StatelessWidget {
  final ManufacturerBundle bundle;
  final List<ManufacturerBundleDevice> pendingDevices;

  const _BundleConfirmSheet({
    required this.bundle,
    required this.pendingDevices,
  });

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            bundle.label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            '以下の${pendingDevices.length}台を登録します',
            style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pendingDevices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final d = pendingDevices[i];
                return Row(
                  children: [
                    Text(d.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${d.manufacturer} ${d.modelNumber}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF888888),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '¥${(d.purchasePrice / 10000).toStringAsFixed(0)}万',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1a1a1a),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('${pendingDevices.length}台をまとめて登録'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }
}

/// AddApplianceScreen 用の横スクロールバンドルチップ行
class ManufacturerBundleQuickRow extends StatefulWidget {
  final VoidCallback? onRegistered;

  const ManufacturerBundleQuickRow({super.key, this.onRegistered});

  @override
  State<ManufacturerBundleQuickRow> createState() =>
      _ManufacturerBundleQuickRowState();
}

class _ManufacturerBundleQuickRowState extends State<ManufacturerBundleQuickRow> {
  List<ManufacturerBundle> _bundles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    final bundles = await ManufacturerBundleService.instance.availableBundles(
      registeredDevices: deviceService.devices,
    );
    if (!mounted) return;
    setState(() {
      _bundles = bundles.take(6).toList();
      _loading = false;
    });
  }

  Future<void> _openPicker() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ManufacturerBundlePickerScreen(),
      ),
    );
    if (registered == true) {
      await _load();
      widget.onRegistered?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: ApplianceCompactCard.cardHeight,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (_bundles.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: ApplianceCompactCard.cardHeight + 8,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _bundles.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == _bundles.length) {
            return ApplianceCompactCard(
              icon: '➕',
              title: 'すべて見る',
              onTap: _openPicker,
            );
          }
          final b = _bundles[index];
          return ApplianceCompactCard(
            icon: b.icon,
            title: b.label,
            subtitle: '${b.deviceCount}台',
            onTap: _openPicker,
          );
        },
      ),
    );
  }
}
