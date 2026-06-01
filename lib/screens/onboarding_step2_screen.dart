import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
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
          const Text(
            'いまはサンプルの部屋画像が表示されます。\n'
            '写真は、家電の登録が終わってから設定できます。\n'
            '使わない部屋はチェックを外してください。',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: Color(0xFF999999),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),

          // Room toggle list
          Expanded(
            child: ListView.separated(
              itemCount: widget.rooms.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final room = widget.rooms[index];
                return _RoomToggleCard(
                  room: room,
                  onToggle: () {
                    setState(() {
                      room.selected = !room.selected;
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.rooms.any((r) => r.selected)
                  ? () => widget.onConfirmed(widget.rooms)
                  : null,
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

  const _RoomToggleCard({required this.room, required this.onToggle});

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
                child: Text(
                  room.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: room.selected
                        ? const Color(0xFF333333)
                        : const Color(0xFFBBBBBB),
                  ),
                ),
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
