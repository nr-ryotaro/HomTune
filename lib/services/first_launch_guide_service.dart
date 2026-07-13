import 'package:shared_preferences/shared_preferences.dart';

import '../models/appliance_archetype.dart';
import '../models/device.dart';
import 'appliance_template_service.dart';
import 'onboarding_prefs.dart';
import 'room_photo_service.dart';

/// 初回ホーム到達後のセットアップ進捗（家電登録 → 部屋写真 → Pro 案内）
class SetupProgress {
  final int selectedArchetypeCount;
  final int registeredArchetypeCount;
  final int userDeviceCount;
  final bool appliancePhaseDone;
  final bool roomPhotosConfigured;

  const SetupProgress({
    required this.selectedArchetypeCount,
    required this.registeredArchetypeCount,
    required this.userDeviceCount,
    required this.appliancePhaseDone,
    required this.roomPhotosConfigured,
  });

  bool get hasApplianceGoal => selectedArchetypeCount > 0;

  int get applianceProgressTarget =>
      hasApplianceGoal ? selectedArchetypeCount : 1;

  int get applianceProgressCurrent {
    if (hasApplianceGoal) {
      return registeredArchetypeCount.clamp(0, selectedArchetypeCount);
    }
    return userDeviceCount > 0 ? 1 : 0;
  }

  bool get applianceGoalMet =>
      appliancePhaseDone || applianceProgressCurrent >= applianceProgressTarget;

  bool get shouldPromptRoomPhotos => !roomPhotosConfigured;

  double get applianceProgressRatio {
    final target = applianceProgressTarget;
    if (target <= 0) return userDeviceCount > 0 ? 1.0 : 0.0;
    return (applianceProgressCurrent / target).clamp(0.0, 1.0);
  }
}

class FirstLaunchGuideService {
  FirstLaunchGuideService._();
  static final FirstLaunchGuideService instance = FirstLaunchGuideService._();

  static const _keyPendingWelcome = 'pending_first_home_welcome';
  static const _keyPendingHomeCoach = 'pending_home_usage_coach';
  static const _keyProIntroShown = 'pro_intro_shown_after_setup';

  Future<void> scheduleWelcomeAfterOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPendingWelcome, true);
    await prefs.setBool(_keyPendingHomeCoach, true);
  }

  Future<bool> consumePendingWelcome() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_keyPendingWelcome) ?? false;
    if (pending) {
      await prefs.setBool(_keyPendingWelcome, false);
    }
    return pending;
  }

  Future<bool> shouldShowProIntro() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyProIntroShown) == true) return false;
    final photos = await RoomPhotoService.isRoomPhotosConfigured();
    final applianceDone = await RoomPhotoService.isApplianceSetupDone();
    return applianceDone && photos;
  }

  Future<void> markProIntroShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyProIntroShown, true);
  }

  Future<bool> consumePendingHomeCoach() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getBool(_keyPendingHomeCoach) ?? false;
    if (pending) {
      await prefs.setBool(_keyPendingHomeCoach, false);
    }
    return pending;
  }

  Future<void> dismissHomeCoachPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPendingHomeCoach, false);
  }

  Future<SetupProgress> loadProgress({
    required List<Device> devices,
    bool excludeSeedDevices = true,
  }) async {
    final selected = await OnboardingPrefs.getSelectedArchetypes();
    final userDevices = excludeSeedDevices
        ? devices.where((d) => !_looksLikeSeedId(d.id)).toList()
        : devices;

    final registeredArchetypes = await _countRegisteredArchetypes(
      selected: selected,
      devices: userDevices,
    );

    return SetupProgress(
      selectedArchetypeCount: selected.length,
      registeredArchetypeCount: registeredArchetypes,
      userDeviceCount: userDevices.length,
      appliancePhaseDone: await RoomPhotoService.isApplianceSetupDone(),
      roomPhotosConfigured: await RoomPhotoService.isRoomPhotosConfigured(),
    );
  }

  bool _looksLikeSeedId(String id) {
    const seedIds = {
      'tv_001',
      'speaker_001',
      'record_player_001',
      'humidifier_001',
      'fridge_001',
      'rice_cooker_001',
    };
    return seedIds.contains(id);
  }

  Future<int> _countRegisteredArchetypes({
    required List<SelectedArchetypeRef> selected,
    required List<Device> devices,
  }) async {
    if (selected.isEmpty) return devices.isNotEmpty ? 1 : 0;
    var count = 0;
    for (final ref in selected) {
      final archetype = await ApplianceTemplateService.instance
          .getArchetypeById(ref.archetypeId);
      if (archetype == null) continue;
      final registered = devices.any((d) {
        if (d.archetypeId == ref.archetypeId) return true;
        if (d.category == archetype.category) return true;
        return d.name.contains(archetype.displayName);
      });
      if (registered) count++;
    }
    return count;
  }
}
