import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:homtune/models/source_attribution.dart';
import 'package:homtune/services/compliance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('allows approved official source domain', () {
    final attribution = SourceAttribution(
      sourceType: SourceType.officialApi,
      sourceUrl: 'https://www.daikin.co.jp/support/manual/',
      publisher: 'Daikin',
      licenseType: 'official',
      capturedAt: DateTime.parse('2026-06-01T00:00:00.000Z'),
      confidence: 0.95,
      reviewState: ReviewState.approved,
    );

    expect(ComplianceService.canDistribute(attribution), isTrue);
  });

  test('blocks pending review even with valid domain', () {
    final attribution = SourceAttribution(
      sourceType: SourceType.officialApi,
      sourceUrl: 'https://support.apple.com/manuals',
      publisher: 'Apple',
      licenseType: 'official',
      capturedAt: DateTime.parse('2026-06-01T00:00:00.000Z'),
      confidence: 0.9,
      reviewState: ReviewState.pending,
    );

    expect(ComplianceService.canDistribute(attribution), isFalse);
  });

  test('rejects non-https URL', () {
    expect(
      ComplianceService.isAllowedSourceUrl('http://www.daikin.co.jp/manual'),
      isFalse,
    );
  });
}
