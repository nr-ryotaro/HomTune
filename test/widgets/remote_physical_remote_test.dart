import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device_remote_link.dart';
import 'package:homtune/models/remote_appliance.dart';
import 'package:homtune/models/remote_ui_skin.dart';
import 'package:homtune/models/remote_ui_template.dart';
import 'package:homtune/widgets/remote_control/remote_control_template_panel.dart';
import 'package:homtune/widgets/remote_control/skins/aircon_physical_remote.dart';

void main() {
  group('Physical remote skins', () {
    testWidgets('Panasonic aircon skin shows brand and LCD', (tester) async {
      final layout = RemoteUiResolvedLayout(
        templateId: 'aircon_panasonic',
        templateLabel: 'パナソニック エアコン',
        skin: RemoteUiSkinType.physicalAircon,
        themeKey: 'panasonic',
        groups: [
          RemoteUiGroupDef(
            id: 'mode',
            title: '運転モード',
            buttons: [
              const RemoteUiButtonDef(
                id: 'cool',
                label: '冷房',
                icon: Icons.ac_unit,
                commandType: RemoteCommandType.airconCool,
                variant: RemoteUiButtonVariant.cool,
              ),
              const RemoteUiButtonDef(
                id: 'power_off',
                label: 'オフ',
                icon: Icons.power_off,
                commandType: RemoteCommandType.powerOff,
                variant: RemoteUiButtonVariant.danger,
              ),
              const RemoteUiButtonDef(
                id: 'temp_up',
                label: '温度＋',
                icon: Icons.add,
                commandType: RemoteCommandType.tempUp,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteControlTemplatePanel(
              layout: layout,
              link: DeviceRemoteLink(
                provider: RemoteProvider.remo,
                externalApplianceId: 'ac-1',
                profile: RemoteCapabilityProfile.aircon,
                linkedAt: DateTime.now().toIso8601String(),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Panasonic'), findsOneWidget);
      expect(find.textContaining('26°C'), findsOneWidget);
      expect(find.text('冷房'), findsWidgets);
    });

    testWidgets('Panasonic aircon skin fits narrow width without overflow', (tester) async {
      final layout = RemoteUiResolvedLayout(
        templateId: 'aircon_panasonic',
        templateLabel: 'パナソニック エアコン',
        skin: RemoteUiSkinType.physicalAircon,
        themeKey: 'panasonic',
        groups: [
          RemoteUiGroupDef(
            id: 'mode',
            title: '運転モード',
            buttons: [
              const RemoteUiButtonDef(
                id: 'cool',
                label: '冷房',
                icon: Icons.ac_unit,
                commandType: RemoteCommandType.airconCool,
                variant: RemoteUiButtonVariant.cool,
              ),
              const RemoteUiButtonDef(
                id: 'warm',
                label: '暖房',
                icon: Icons.whatshot,
                commandType: RemoteCommandType.airconWarm,
                variant: RemoteUiButtonVariant.warm,
              ),
              const RemoteUiButtonDef(
                id: 'dry',
                label: '除湿',
                icon: Icons.water_drop,
                commandType: RemoteCommandType.airconDry,
              ),
              const RemoteUiButtonDef(
                id: 'fan',
                label: '送風',
                icon: Icons.air,
                commandType: RemoteCommandType.airconFan,
              ),
              const RemoteUiButtonDef(
                id: 'auto',
                label: '自動',
                icon: Icons.autorenew,
                commandType: RemoteCommandType.airconAuto,
              ),
              const RemoteUiButtonDef(
                id: 'power_off',
                label: 'オフ',
                icon: Icons.power_off,
                commandType: RemoteCommandType.powerOff,
                variant: RemoteUiButtonVariant.danger,
              ),
              const RemoteUiButtonDef(
                id: 'temp_up',
                label: '温度＋',
                icon: Icons.add,
                commandType: RemoteCommandType.tempUp,
              ),
              const RemoteUiButtonDef(
                id: 'temp_down',
                label: '温度−',
                icon: Icons.remove,
                commandType: RemoteCommandType.tempDown,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: RemoteControlTemplatePanel(
                layout: layout,
                link: DeviceRemoteLink(
                  provider: RemoteProvider.remo,
                  externalApplianceId: 'ac-1',
                  profile: RemoteCapabilityProfile.aircon,
                  linkedAt: DateTime.now().toIso8601String(),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Sony TV skin uses dark body and streaming colors', (tester) async {
      final layout = RemoteUiResolvedLayout(
        templateId: 'tv_sony_bravia',
        templateLabel: 'SONY BRAVIA',
        skin: RemoteUiSkinType.physicalTv,
        themeKey: 'sony',
        groups: [
          RemoteUiGroupDef(
            id: 'streaming',
            title: 'サブスク',
            buttons: [
              const RemoteUiButtonDef(
                id: 'netflix',
                label: 'Netflix',
                icon: Icons.play_circle_outline,
                commandType: RemoteCommandType.tvApp,
              ),
            ],
          ),
          RemoteUiGroupDef(
            id: 'volume',
            title: '音量',
            buttons: [
              const RemoteUiButtonDef(
                id: 'vol_up',
                label: '音量＋',
                icon: Icons.volume_up,
                commandType: RemoteCommandType.volumeUp,
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RemoteControlTemplatePanel(layout: layout),
          ),
        ),
      );

      expect(find.text('BRAVIA'), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget);
    });

    test('AirconPhysicalRemote resolves mode button tap', () {
      RemoteCommandType? sent;
      final layout = RemoteUiResolvedLayout(
        templateId: 'aircon_daikin',
        templateLabel: 'ダイキン',
        skin: RemoteUiSkinType.physicalAircon,
        themeKey: 'daikin',
        groups: [
          RemoteUiGroupDef(
            id: 'mode',
            title: 'mode',
            buttons: [
              const RemoteUiButtonDef(
                id: 'cool',
                label: '冷房',
                icon: Icons.ac_unit,
                commandType: RemoteCommandType.airconCool,
              ),
            ],
          ),
        ],
      );

      final widget = AirconPhysicalRemote(
        layout: layout,
        theme: RemoteSkinTheme.daikin,
        onCommand: (type, {signalId, parameters}) => sent = type,
      );

      expect(widget, isNotNull);
      expect(layout.skin, RemoteUiSkinType.physicalAircon);
      expect(sent, isNull);
    });
  });
}
