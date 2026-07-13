import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/remote_control/remote_setup_reminder_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await RemoteSetupReminderPrefs.clearAllForTest();
  });

  test('スヌーズ中は isSnoozed が true', () async {
    await RemoteSetupReminderPrefs.snoozeDevice('device-1', days: 7);
    expect(await RemoteSetupReminderPrefs.isSnoozed('device-1'), isTrue);
    expect(await RemoteSetupReminderPrefs.isSnoozed('device-2'), isFalse);
  });

  test('clearSnooze で再表示可能', () async {
    await RemoteSetupReminderPrefs.snoozeDevice('device-1');
    await RemoteSetupReminderPrefs.clearSnooze('device-1');
    expect(await RemoteSetupReminderPrefs.isSnoozed('device-1'), isFalse);
  });
}
