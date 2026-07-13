import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_remote_link.dart';
import 'package:homtune/models/remote_appliance.dart';
import 'package:homtune/services/remote_control/remote_command_intent_parser.dart';

void main() {
  Device _acWithLink() => Device(
        id: 'ac-1',
        name: 'リビングエアコン',
        modelNumber: 'AC-1',
        category: 'エアコン',
        manufacturer: 'Panasonic',
        purchaseDate: '2024-01-01',
        purchasePrice: 100000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'wall',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
        remoteLink: DeviceRemoteLink(
          provider: RemoteProvider.remo,
          externalApplianceId: 'remo-ac-1',
          profile: RemoteCapabilityProfile.aircon,
          linkedAt: '2024-01-01T00:00:00Z',
        ),
      );

  test('parses power on intent for linked AC', () {
    final intent = RemoteCommandIntentParser.parse(
      'リビングのエアコンをつけて',
      [_acWithLink()],
    );
    expect(intent, isNotNull);
    expect(intent!.commandType, RemoteCommandType.powerOn);
    expect(intent.device.id, 'ac-1');
  });

  test('returns null without remote link', () {
    final device = _acWithLink().copyWith(clearRemoteLink: true);
    final intent = RemoteCommandIntentParser.parse(
      'エアコンをつけて',
      [device],
    );
    expect(intent, isNull);
  });

  test('looksLikeRemoteCommand detects control verbs', () {
    expect(RemoteCommandIntentParser.looksLikeRemoteCommand('テレビの電源オフ'), isTrue);
    expect(RemoteCommandIntentParser.looksLikeRemoteCommand('型番は？'), isFalse);
  });
}
