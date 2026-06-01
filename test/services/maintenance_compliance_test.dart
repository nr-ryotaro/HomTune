import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/maintenance_task.dart';
import 'package:homtune/models/source_attribution.dart';
import 'package:homtune/services/maintenance_calendar_service.dart';

void main() {
  test('builds compliance template from fact fields', () {
    final task = MaintenanceTask(
      taskId: 'ac_filter',
      deviceId: 'dev-1',
      name: 'フィルター掃除',
      intervalDays: 14,
      requiredTools: ['掃除機', '中性洗剤'],
      methodTags: ['power_off', 'water_wash'],
      safetyNote: '濡れたまま装着しないでください。',
      sourceAttribution: SourceAttribution(
        sourceType: SourceType.internal,
        sourceUrl: '',
        publisher: 'HomTune Editorial',
        licenseType: 'internal-curated',
        capturedAt: DateTime.parse('2026-06-01T00:00:00.000Z'),
        confidence: 0.9,
        reviewState: ReviewState.approved,
      ),
    );

    final text = MaintenanceCalendarService.getMethodTextSync(task);
    expect(text, contains('必要な道具'));
    expect(text, contains('推奨頻度: 14日ごと'));
    expect(text, contains('注意: 濡れたまま装着しないでください。'));
  });

  test('falls back when attribution is blocked', () {
    final task = MaintenanceTask(
      taskId: 'ac_filter',
      deviceId: 'dev-1',
      name: 'フィルター掃除',
      intervalDays: 14,
      shortMethod: '旧来手順',
      sourceAttribution: SourceAttribution(
        sourceType: SourceType.officialApi,
        sourceUrl: 'https://unknown.example.com/manual',
        publisher: 'Unknown',
        licenseType: 'unknown',
        capturedAt: DateTime.parse('2026-06-01T00:00:00.000Z'),
        confidence: 0.5,
        reviewState: ReviewState.pending,
      ),
    );

    final text = MaintenanceCalendarService.getMethodTextSync(task);
    expect(text, equals('旧来手順'));
  });
}
