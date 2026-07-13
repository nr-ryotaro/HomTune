import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_remote_link.dart';
import 'package:homtune/models/remote_appliance.dart';
import 'package:homtune/models/remote_ui_template.dart';
import 'package:homtune/models/remote_ui_skin.dart';
import 'package:homtune/services/remote_control/remote_ui_preferences_service.dart';
import 'package:homtune/services/remote_control/remote_ui_template_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = RemoteUiTemplateService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service.resetForTest();
    await RemoteUiPreferencesService.instance.clearForTest('preview-ac');
  });

  group('RemoteUiTemplateService', () {
    test('loads templates from asset and resolves Panasonic aircon', () async {
      final template = await service.resolveTemplate(
        profile: RemoteCapabilityProfile.aircon,
        manufacturer: 'Panasonic',
        modelNumber: 'CS-ZX2811',
      );
      expect(template.id, 'aircon_panasonic');
      expect(template.skin, RemoteUiSkinType.physicalAircon);
      expect(template.themeKey, 'panasonic');
      expect(
        template.allButtons.any((b) => b.label == 'ナノイー'),
        isTrue,
      );
    });

    test('resolves Sony TV template by model pattern', () async {
      final template = await service.resolveTemplate(
        profile: RemoteCapabilityProfile.tv,
        manufacturer: 'SONY',
        modelNumber: 'XRJ-65A95K',
      );
      expect(template.id, 'tv_sony_bravia');
      expect(template.skin, RemoteUiSkinType.physicalTv);
      expect(
        template.allButtons.any((b) => b.label == 'Netflix'),
        isTrue,
      );
    });

    test('falls back to default when manufacturer unknown', () async {
      final template = await service.resolveTemplate(
        profile: RemoteCapabilityProfile.aircon,
        manufacturer: 'Unknown',
        modelNumber: 'XYZ-999',
      );
      expect(template.id, 'aircon_default');
      expect(template.skin, RemoteUiSkinType.physicalAircon);
    });

    test('resolves Hitachi aircon by manufacturer', () async {
      final template = await service.resolveTemplate(
        profile: RemoteCapabilityProfile.aircon,
        manufacturer: '日立',
        modelNumber: 'RAS-AJ25L',
      );
      expect(template.id, 'aircon_hitachi');
      expect(template.themeKey, 'hitachi');
    });

    test('resolveLayoutForDevice applies pinned defaults', () async {
      final device = Device(
        id: 'preview-ac',
        name: 'テストAC',
        modelNumber: 'CS-ZX2811',
        category: 'エアコン',
        manufacturer: 'Panasonic',
        purchaseDate: '2024-01-01',
        purchasePrice: 100000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'リビング',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        remoteLink: DeviceRemoteLink(
          provider: RemoteProvider.remo,
          externalApplianceId: 'ac-1',
          profile: RemoteCapabilityProfile.aircon,
          linkedAt: DateTime.now().toIso8601String(),
        ),
      );

      final layout = await service.resolveLayoutForDevice(device);
      expect(layout.templateId, 'aircon_panasonic');
      expect(layout.pinnedButtons.isNotEmpty, isTrue);
      expect(
        layout.pinnedButtons.any((b) => b.label == '冷房'),
        isTrue,
      );
    });

    test('in-memory templates for unit test', () async {
      service.loadTemplatesForTest([
        RemoteUiTemplate(
          id: 'test_tv',
          label: 'Test TV',
          profile: RemoteCapabilityProfile.tv,
          groups: [
            RemoteUiGroupDef(
              id: 'vol',
              title: '音量',
              buttons: [
                const RemoteUiButtonDef(
                  id: 'mute',
                  label: '消音',
                  icon: Icons.volume_off,
                  commandType: RemoteCommandType.tvMute,
                ),
              ],
            ),
          ],
        ),
      ]);

      final template = await service.resolveTemplate(
        profile: RemoteCapabilityProfile.tv,
      );
      expect(template.id, 'test_tv');
    });
  });
}
