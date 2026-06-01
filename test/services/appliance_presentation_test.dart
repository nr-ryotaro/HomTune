import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/appliance_template_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolvePresentation uses archetype icon and displayName by category',
      () async {
    final device = Device(
      id: 'd1',
      name: '超音波式加湿器 クールグレー',
      modelNumber: 'HD-123',
      category: '加湿器',
      manufacturer: 'シャープ',
      purchaseDate: '2024-01-01',
      purchasePrice: 10000,
      yearsOwned: 1,
      room: 'living-room',
      location: '',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
    );

    final presentation =
        await ApplianceTemplateService.instance.resolvePresentation(device);

    expect(presentation.icon, '💧');
    expect(presentation.title, '加湿器');
    expect(presentation.subtitle, isNotNull);
  });

  test('resolvePresentation prefers stored archetypeId', () async {
    final device = Device(
      id: 'd2',
      name: 'My TV',
      modelNumber: '',
      category: 'テレビ',
      manufacturer: 'Sony',
      purchaseDate: '2024-01-01',
      purchasePrice: 50000,
      yearsOwned: 0.5,
      room: 'living-room',
      location: '',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
      archetypeId: 'living_tv',
    );

    final presentation =
        await ApplianceTemplateService.instance.resolvePresentation(device);

    expect(presentation.icon, '📺');
    expect(presentation.title, 'テレビ');
  });

  test('resolvePresentation applies custom display name and icon', () async {
    final device = Device(
      id: 'd3',
      name: '超音波式加湿器',
      modelNumber: 'ABC-100',
      category: '加湿器',
      manufacturer: 'シャープ',
      purchaseDate: '2024-01-01',
      purchasePrice: 10000,
      yearsOwned: 1,
      room: 'living-room',
      location: '',
      status: 'active',
      consumables: [],
      photos: [],
      documents: [],
      customDisplayName: 'リビングの加湿器',
      customIcon: '🌫️',
    );

    final presentation =
        await ApplianceTemplateService.instance.resolvePresentation(device);

    expect(presentation.icon, '🌫️');
    expect(presentation.title, 'リビングの加湿器');
    expect(presentation.subtitle, 'ABC-100');
  });
}
