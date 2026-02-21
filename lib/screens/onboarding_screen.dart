import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_step1_screen.dart';
import 'onboarding_step2_screen.dart';
import 'onboarding_step3_screen.dart';

/// オンボーディングの住居タイプ定義
enum HousingType {
  studio, // ワンルーム / 1K
  oneLDK, // 1LDK
  twoLDK, // 2LDK
  threeLDK, // 3LDK以上
  house, // 一軒家
}

extension HousingTypeExtension on HousingType {
  String get label {
    switch (this) {
      case HousingType.studio:
        return 'ワンルーム / 1K';
      case HousingType.oneLDK:
        return '1LDK';
      case HousingType.twoLDK:
        return '2LDK';
      case HousingType.threeLDK:
        return '3LDK以上';
      case HousingType.house:
        return '一軒家';
    }
  }

  String get icon {
    switch (this) {
      case HousingType.studio:
        return '🏢';
      case HousingType.oneLDK:
        return '🏠';
      case HousingType.twoLDK:
        return '🏡';
      case HousingType.threeLDK:
        return '🏘️';
      case HousingType.house:
        return '🏠';
    }
  }

  /// 住居タイプに応じたデフォルト部屋
  List<RoomOption> get defaultRooms {
    switch (this) {
      case HousingType.studio:
        return [
          RoomOption(id: 'living-room', name: 'リビング', icon: '🛋️'),
          RoomOption(id: 'bathroom', name: 'バスルーム', icon: '🛁'),
        ];
      case HousingType.oneLDK:
        return [
          RoomOption(id: 'living-room', name: 'リビング', icon: '🛋️'),
          RoomOption(id: 'bedroom-01', name: '寝室', icon: '🛏️'),
          RoomOption(id: 'bathroom', name: 'バスルーム', icon: '🛁'),
        ];
      case HousingType.twoLDK:
        return [
          RoomOption(id: 'living-room', name: 'リビング', icon: '🛋️'),
          RoomOption(id: 'bedroom-01', name: '寝室', icon: '🛏️'),
          RoomOption(id: 'kitchen-01', name: 'キッチン', icon: '🍳'),
          RoomOption(id: 'bathroom', name: 'バスルーム', icon: '🛁'),
        ];
      case HousingType.threeLDK:
      case HousingType.house:
        return [
          RoomOption(id: 'living-room', name: 'リビング', icon: '🛋️'),
          RoomOption(id: 'bedroom-01', name: '寝室', icon: '🛏️'),
          RoomOption(id: 'kitchen-01', name: 'キッチン', icon: '🍳'),
          RoomOption(id: 'bathroom', name: 'バスルーム', icon: '🛁'),
          RoomOption(id: 'study', name: '書斎', icon: '📚'),
        ];
    }
  }
}

class RoomOption {
  final String id;
  final String name;
  final String icon;
  bool selected;

  RoomOption({
    required this.id,
    required this.name,
    required this.icon,
    this.selected = true,
  });
}

/// オンボーディング全体を管理するスクリーン
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  HousingType? _selectedHousingType;
  List<RoomOption> _rooms = [];

  void _goToStep(int step) {
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() {
      _currentStep = step;
    });
  }

  void _onHousingTypeSelected(HousingType type) {
    setState(() {
      _selectedHousingType = type;
      _rooms = type.defaultRooms;
    });
    _goToStep(1);
  }

  void _onRoomsConfirmed(List<RoomOption> rooms) {
    setState(() {
      _rooms = rooms;
    });
    _goToStep(2);
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // 選択された部屋のIDを保存
    final selectedRoomIds =
        _rooms.where((r) => r.selected).map((r) => r.id).toList();
    await prefs.setStringList('selected_rooms', selectedRoomIds);

    if (_selectedHousingType != null) {
      await prefs.setString('housing_type', _selectedHousingType!.name);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _skipOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/home');
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAF8),
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Progress dots
                  Row(
                    children: List.generate(3, (i) {
                      return Container(
                        width: i == _currentStep ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: i == _currentStep
                              ? const Color(0xFF333333)
                              : const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'スキップ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF999999),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  OnboardingStep1Screen(
                    onTypeSelected: _onHousingTypeSelected,
                  ),
                  OnboardingStep2Screen(
                    rooms: _rooms,
                    onConfirmed: _onRoomsConfirmed,
                  ),
                  OnboardingStep3Screen(
                    onComplete: _completeOnboarding,
                    onSkip: _completeOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
