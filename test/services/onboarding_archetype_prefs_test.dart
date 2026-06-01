import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/appliance_archetype.dart';
import 'package:homtune/services/onboarding_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('selected archetypes persist and restore', () async {
    await OnboardingPrefs.setSelectedArchetypes([
      const SelectedArchetypeRef(
        archetypeId: 'kitchen_fridge',
        roomId: 'kitchen-01',
      ),
      const SelectedArchetypeRef(
        archetypeId: 'living_tv',
        roomId: 'living-room',
      ),
    ]);

    final restored = await OnboardingPrefs.getSelectedArchetypes();
    expect(restored.length, 2);
    expect(restored.map((r) => r.archetypeId),
        containsAll(['kitchen_fridge', 'living_tv']));
  });
}
