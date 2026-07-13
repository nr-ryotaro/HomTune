import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/remote_control/remote_compatibility_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    RemoteCompatibilityService.instance.resetForTest();
  });

  test('bundled remote-compatibility-catalog.json loads without error', () async {
    final result = await RemoteCompatibilityService.instance.assess(
      modelNumber: 'CS-ZX2811',
      category: 'エアコン',
      manufacturer: 'Panasonic',
    );

    expect(result.isEligible, isTrue);
  });

  test('seed TV model from catalog matches', () async {
    final result = await RemoteCompatibilityService.instance.assess(
      modelNumber: 'XRJ-65A95K',
      category: 'テレビ',
      manufacturer: 'SONY',
    );

    expect(result.isEligible, isTrue);
  });
}
