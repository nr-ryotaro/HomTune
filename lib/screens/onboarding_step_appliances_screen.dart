import 'package:flutter/material.dart';
import '../models/appliance_archetype.dart';
import '../services/appliance_template_service.dart';
import 'onboarding_screen.dart';

/// Step 3: 部屋ごとの想定家電を選択
class OnboardingStepAppliancesScreen extends StatefulWidget {
  final List<RoomOption> rooms;
  final void Function(List<SelectedArchetypeRef> selected) onConfirmed;

  const OnboardingStepAppliancesScreen({
    super.key,
    required this.rooms,
    required this.onConfirmed,
  });

  @override
  State<OnboardingStepAppliancesScreen> createState() =>
      _OnboardingStepAppliancesScreenState();
}

class _OnboardingStepAppliancesScreenState
    extends State<OnboardingStepAppliancesScreen> {
  final Set<String> _selectedIds = {};
  bool _loading = true;
  List<ApplianceArchetype> _archetypes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final roomIds =
        widget.rooms.where((r) => r.selected).map((r) => r.id).toList();
    final list =
        await ApplianceTemplateService.instance.getArchetypesForRooms(roomIds);
    if (!mounted) return;
    setState(() {
      _archetypes = list;
      _selectedIds.addAll(list.map((a) => a.id));
      _loading = false;
    });
  }

  void _toggle(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _confirm() {
    final refs = _archetypes
        .where((a) => _selectedIds.contains(a.id))
        .map((a) => SelectedArchetypeRef(archetypeId: a.id, roomId: a.roomId))
        .toList();
    widget.onConfirmed(refs);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final byRoom = <String, List<ApplianceArchetype>>{};
    for (final a in _archetypes) {
      byRoom.putIfAbsent(a.roomId, () => []).add(a);
    }

    final roomNameById = {
      for (final r in widget.rooms) r.id: r.name,
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          const Text(
            '管理したい家電',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '各部屋で管理したい家電のテンプレートを表示しています。\n'
            '不要なものはチェックを外してください。\n'
            '家電はいつでも登録できます。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),
          for (final roomId in byRoom.keys) ...[
            Text(
              roomNameById[roomId] ?? roomId,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF666666),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in byRoom[roomId]!)
                  FilterChip(
                    label: Text('${a.icon} ${a.displayName}'),
                    selected: _selectedIds.contains(a.id),
                    onSelected: (_) => _toggle(a.id),
                    selectedColor: const Color(0xFFE8F4EA),
                    checkmarkColor: const Color(0xFF2D6A4F),
                  ),
              ],
            ),
            const SizedBox(height: 20),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('次へ'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
