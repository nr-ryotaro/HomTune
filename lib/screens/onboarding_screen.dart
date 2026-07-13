import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/first_launch_guide_service.dart';
import '../services/onboarding_prefs.dart';
import '../services/room_name_service.dart';
import '../services/room_photo_service.dart';
import 'home_screen.dart';
import 'onboarding_step1_screen.dart';
import 'onboarding_step2_screen.dart';
import 'onboarding_step3_screen.dart';
import 'onboarding_step_appliances_screen.dart';
import '../models/appliance_archetype.dart';

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

  /// 住居タイプに応じたデフォルト部屋（内部IDはテンプレート用、表示名は部屋1,2…）
  List<RoomOption> get defaultRooms {
    switch (this) {
      case HousingType.studio:
        return _defaultRoomOptions(const [
          ('living-room', 'リビング・居室', '🛋️'),
          ('kitchen-01', 'キッチン', '🍳'),
        ]);
      case HousingType.oneLDK:
        return _defaultRoomOptions(const [
          ('living-room', 'リビング', '🛋️'),
          ('kitchen-01', 'キッチン', '🍳'),
          ('bedroom-01', '寝室', '🛏️'),
        ]);
      case HousingType.twoLDK:
        return _defaultRoomOptions(const [
          ('living-room', 'リビング', '🛋️'),
          ('kitchen-01', 'キッチン', '🍳'),
          ('bedroom-01', '寝室', '🛏️'),
          ('entrance', '玄関', '🚪'),
        ]);
      case HousingType.threeLDK:
      case HousingType.house:
        return _defaultRoomOptions(const [
          ('living-room', 'リビング', '🛋️'),
          ('kitchen-01', 'キッチン', '🍳'),
          ('bedroom-01', '寝室', '🛏️'),
          ('entrance', '玄関', '🚪'),
          ('study', '書斎', '📚'),
        ]);
    }
  }

  static List<RoomOption> _defaultRoomOptions(
    List<(String id, String suggestion, String icon)> specs,
  ) {
    return [
      for (var i = 0; i < specs.length; i++)
        RoomOption(
          id: specs[i].$1,
          name: RoomNameService.defaultNameForIndex(i),
          icon: specs[i].$3,
          suggestedLabel: '例: ${specs[i].$2}',
        ),
    ];
  }
}

class RoomOption {
  final String id;
  String name;
  final String icon;
  final String? suggestedLabel;
  bool selected;

  RoomOption({
    required this.id,
    required this.name,
    required this.icon,
    this.suggestedLabel,
    this.selected = true,
  });
}

/// オンボーディング全体を管理するスクリーン
class OnboardingScreen extends StatefulWidget {
  /// 設定画面などからのプレビュー（完了せずに閉じられる）
  final bool isPreview;

  const OnboardingScreen({super.key, this.isPreview = false});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  HousingType? _selectedHousingType;
  List<RoomOption> _rooms = [];
  List<SelectedArchetypeRef> _selectedArchetypes = [];
  bool _isFinishing = false;

  void _goToStep(int step) {
    if (step < 0 || step > 3) return;
    if (_currentStep == step) return;

    setState(() => _currentStep = step);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;
      try {
        _pageController.animateToPage(
          step,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } catch (e, stackTrace) {
        debugPrint('Onboarding page transition failed: $e');
        debugPrint('$stackTrace');
        if (!mounted || !_pageController.hasClients) return;
        _pageController.jumpToPage(step);
      }
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

  void _onAppliancesConfirmed(List<SelectedArchetypeRef> refs) {
    setState(() {
      _selectedArchetypes = refs;
    });
    _goToStep(3);
  }

  String? get _primaryRoomId {
    final selected = _rooms.where((r) => r.selected);
    if (selected.isNotEmpty) return selected.first.id;
    if (_rooms.isNotEmpty) return _rooms.first.id;
    return 'living-room';
  }

  Future<void> _persistOnboardingPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(OnboardingPrefs.keyCompleted, true);
    final selectedRoomIds =
        _rooms.where((r) => r.selected).map((r) => r.id).toList();
    await OnboardingPrefs.setSelectedRoomIds(selectedRoomIds);
    if (_selectedHousingType != null) {
      await prefs.setString(
          OnboardingPrefs.keyHousingType, _selectedHousingType!.name);
    }
    await OnboardingPrefs.setSelectedArchetypes(_selectedArchetypes);
    final selectedRooms = _rooms.where((r) => r.selected).toList();
    await RoomNameService.instance.saveFromRoomOptions(
      selectedRooms.map((r) => (id: r.id, name: r.name)),
    );
  }

  /// プレビュー時は保存せず前の画面へ戻る
  Future<void> _exitPreview() async {
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _onHeaderAction() async {
    if (widget.isPreview) {
      await _exitPreview();
    } else {
      await _finishOnboarding();
    }
  }

  /// プレビュー完了後は既存のホームへ戻す（Home を二重生成しない）
  void _leaveAfterPreviewComplete() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  /// オンボーディング完了。データ読み込みは HomeScreen に任せ、先に画面遷移する。
  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    _isFinishing = true;
    if (mounted) setState(() {});

    try {
      await _persistOnboardingPrefs();
      await RoomPhotoService.setApplianceSetupDone(false);
      await RoomPhotoService.setRoomPhotosConfigured(false);
      if (!widget.isPreview) {
        await FirstLaunchGuideService.instance.scheduleWelcomeAfterOnboarding();
      }
      if (!mounted) return;

      if (widget.isPreview) {
        _leaveAfterPreviewComplete();
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e, stackTrace) {
      debugPrint('Failed to finish onboarding: $e');
      debugPrint('$stackTrace');
      if (!mounted) return;
      setState(() => _isFinishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('画面の切り替えに失敗しました。もう一度お試しください。'),
          duration: Duration(seconds: 2),
        ),
      );
    }
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
            if (widget.isPreview)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(24, 4, 24, 0),
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: const Text(
                    'プレビューモード',
                    style: TextStyle(fontSize: 11, color: Color(0xFF1D4ED8)),
                  ),
                ),
              ),
            // Progress dots + Skip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.isPreview)
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF333333)),
                      onPressed: _isFinishing ? null : _exitPreview,
                      tooltip: '戻る',
                    )
                  else
                    const SizedBox(width: 48),
                  // Progress dots
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ...List.generate(4, (i) {
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
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _isFinishing ? null : _onHeaderAction,
                    child: Text(
                      widget.isPreview ? '閉じる' : 'セットアップをスキップ',
                      style: const TextStyle(
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
                onPageChanged: (i) {
                  if (_currentStep != i && mounted) {
                    setState(() => _currentStep = i);
                  }
                },
                children: [
                  OnboardingStep1Screen(
                    onTypeSelected: _onHousingTypeSelected,
                  ),
                  OnboardingStep2Screen(
                    rooms: _rooms,
                    onConfirmed: _onRoomsConfirmed,
                  ),
                  OnboardingStepAppliancesScreen(
                    rooms: _rooms,
                    onConfirmed: _onAppliancesConfirmed,
                  ),
                  OnboardingStep3Screen(
                    initialRoomId: _primaryRoomId,
                    isFinishing: _isFinishing,
                    onComplete: _finishOnboarding,
                    onSkip: _finishOnboarding,
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
          if (_isFinishing)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF333333)),
              ),
            ),
        ],
      ),
    );
  }
}
