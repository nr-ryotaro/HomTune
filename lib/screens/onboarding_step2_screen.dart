import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_usage_policy.dart';
import '../services/config_service.dart';
import '../services/room_fair_use_service.dart';
import '../widgets/ads/pro_upgrade_dialog.dart';
import 'onboarding_screen.dart';

/// Step 2: 部屋確認・選択
class OnboardingStep2Screen extends StatefulWidget {
  final List<RoomOption> rooms;
  final Function(List<RoomOption>) onConfirmed;

  const OnboardingStep2Screen({
    super.key,
    required this.rooms,
    required this.onConfirmed,
  });

  @override
  State<OnboardingStep2Screen> createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  Future<void> _renameRoom(RoomOption room) async {
    final controller = TextEditingController(text: room.name);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('部屋の名称を変更'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '例: リビング、寝室、書斎',
                border: OutlineInputBorder(),
              ),
            ),
            if (room.suggestedLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                room.suggestedLabel!,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (next == null || next.isEmpty || !mounted) return;
    setState(() => room.name = next);
  }

  Future<void> _onToggleRoom(RoomOption room) async {
    if (room.selected) {
      setState(() => room.selected = false);
      return;
    }
    final config = Provider.of<ConfigService>(context, listen: false);
    final fair = RoomFairUseService.instance;
    final nextCount = widget.rooms.where((r) => r.selected).length + 1;
    if (!fair.canRegisterRoomCount(
      nextCount,
      tier: config.subscriptionTier,
    )) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fair.rejectionMessage(config.subscriptionTier))),
      );
      if (config.subscriptionTier == SubscriptionTier.free) {
        await showProUpgradeDialog(context);
      }
      return;
    }
    setState(() => room.selected = true);
  }

  Future<void> _onConfirm() async {
    final config = Provider.of<ConfigService>(context, listen: false);
    final fair = RoomFairUseService.instance;
    final count = widget.rooms.where((r) => r.selected).length;
    if (!fair.canRegisterRoomCount(count, tier: config.subscriptionTier)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(fair.rejectionMessage(config.subscriptionTier))),
      );
      if (config.subscriptionTier == SubscriptionTier.free) {
        await showProUpgradeDialog(context);
      }
      return;
    }
    widget.onConfirmed(widget.rooms);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigService>();
    final maxRooms =
        RoomFairUseService.instance.absoluteMaxRooms(config.subscriptionTier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            '使うお部屋を選びましょう',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w200,
              letterSpacing: -0.5,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '部屋名は「部屋1」のように仮の名前です。タップして変更できます。\n'
            'あとからホーム画面でも名称変更できます。\n'
            '使わない部屋はチェックを外してください。\n'
            '${config.subscriptionTier == SubscriptionTier.free ? "Freeプランは最大$maxRooms部屋までです。" : "Proプランは最大$maxRooms部屋までです。"}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              itemCount: widget.rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final room = widget.rooms[index];
                return _RoomToggleCard(
                  room: room,
                  onToggle: () => _onToggleRoom(room),
                  onRename: () => _renameRoom(room),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.rooms.any((r) => r.selected) ? _onConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF333333),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E5E5),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                '${widget.rooms.where((r) => r.selected).length}部屋で始める',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RoomToggleCard extends StatelessWidget {
  final RoomOption room;
  final VoidCallback onToggle;
  final VoidCallback onRename;

  const _RoomToggleCard({
    required this.room,
    required this.onToggle,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: room.selected ? Colors.white : const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(
              color: room.selected
                  ? const Color(0xFF333333)
                  : const Color(0xFFE5E5E5),
              width: room.selected ? 1.5 : 0.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                room.icon,
                style: TextStyle(
                  fontSize: 24,
                  color: room.selected ? null : Colors.grey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: room.selected
                            ? const Color(0xFF333333)
                            : const Color(0xFFBBBBBB),
                      ),
                    ),
                    if (room.suggestedLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        room.suggestedLabel!,
                        style: TextStyle(
                          fontSize: 11,
                          color: room.selected
                              ? const Color(0xFF999999)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: room.selected ? onRename : null,
                icon: Icon(
                  Icons.edit_outlined,
                  size: 18,
                  color: room.selected
                      ? const Color(0xFF666666)
                      : const Color(0xFFCCCCCC),
                ),
                tooltip: '名称を変更',
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: room.selected
                    ? const Icon(Icons.check_circle,
                        key: ValueKey('checked'),
                        color: Color(0xFF333333),
                        size: 22)
                    : const Icon(Icons.circle_outlined,
                        key: ValueKey('unchecked'),
                        color: Color(0xFFCCCCCC),
                        size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
