import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/first_launch_guide_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('SetupProgress computes appliance goal from archetypes', () async {
    const progress = SetupProgress(
      selectedArchetypeCount: 5,
      registeredArchetypeCount: 2,
      userDeviceCount: 2,
      appliancePhaseDone: false,
      roomPhotosConfigured: false,
    );

    expect(progress.applianceProgressTarget, 5);
    expect(progress.applianceProgressCurrent, 2);
    expect(progress.applianceGoalMet, isFalse);
    expect(progress.shouldPromptRoomPhotos, isTrue);
  });

  test('SetupProgress prompts room photos without appliance prerequisite', () {
    const progress = SetupProgress(
      selectedArchetypeCount: 3,
      registeredArchetypeCount: 0,
      userDeviceCount: 0,
      appliancePhaseDone: false,
      roomPhotosConfigured: false,
    );

    expect(progress.shouldPromptRoomPhotos, isTrue);
  });

  test('welcome flag is consumed once', () async {
    final guide = FirstLaunchGuideService.instance;
    await guide.scheduleWelcomeAfterOnboarding();
    expect(await guide.consumePendingWelcome(), isTrue);
    expect(await guide.consumePendingWelcome(), isFalse);
  });
}
