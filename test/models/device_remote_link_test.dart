import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/models/device_remote_link.dart';

void main() {
  test('Device serializes remoteLink', () {
    final device = Device(
      id: 'd1',
      name: 'TV',
      modelNumber: 'TV-1',
      category: 'テレビ',
      manufacturer: 'Sony',
      purchaseDate: '2024-01-01',
      purchasePrice: 50000,
      yearsOwned: 1,
      room: 'living-room',
      location: 'tv',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
      remoteLink: DeviceRemoteLink(
        provider: RemoteProvider.remo,
        externalApplianceId: 'ap-1',
        profile: RemoteCapabilityProfile.tv,
        signalIds: {'powerOn': 'sig-on'},
        linkedAt: '2024-06-01T00:00:00Z',
      ),
    );

    final json = device.toJson();
    expect(json['remoteLink'], isNotNull);

    final restored = Device.fromJson(json);
    expect(restored.remoteLink?.externalApplianceId, 'ap-1');
    expect(restored.remoteLink?.profile, RemoteCapabilityProfile.tv);
    expect(restored.remoteLink?.signalIds['powerOn'], 'sig-on');
  });

  test('inferFromCategory maps aircon and tv', () {
    expect(
      DeviceRemoteLink.inferFromCategory('エアコン'),
      RemoteCapabilityProfile.aircon,
    );
    expect(
      DeviceRemoteLink.inferFromCategory('テレビ'),
      RemoteCapabilityProfile.tv,
    );
  });
}
