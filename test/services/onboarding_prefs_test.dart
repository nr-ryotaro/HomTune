import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/services/onboarding_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('完了済みかつ起動時表示OFFならLP非表示', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingPrefs.keyCompleted: true,
      OnboardingPrefs.keyShowOnLaunch: false,
    });
    expect(await OnboardingPrefs.shouldShowOnLaunch(), isFalse);
  });

  test('起動時表示ONなら完了済みでもLP表示', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingPrefs.keyCompleted: true,
      OnboardingPrefs.keyShowOnLaunch: true,
    });
    expect(await OnboardingPrefs.shouldShowOnLaunch(), isTrue);
  });

  test('未完了なら起動時表示OFFでもLP表示', () async {
    SharedPreferences.setMockInitialValues({
      OnboardingPrefs.keyCompleted: false,
    });
    expect(await OnboardingPrefs.shouldShowOnLaunch(), isTrue);
  });
}
