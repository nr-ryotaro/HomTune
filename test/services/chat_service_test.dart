import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/models/device.dart';
import 'package:homtune/services/chat_service.dart';
import 'package:homtune/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ChatService', () {
    late ConfigService configService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      configService = ConfigService();
      await configService.load();
      // ユニットテストではプロキシ通信を避け、ローカル応答を検証する
      await configService.setPreferAiProxy(false);
    });

    test('local mode returns helpful message when no devices', () async {
      final chat = ChatService(configService);
      await chat.initializeWithDevices([]);

      final response = await chat.sendMessage('電源がつかない');
      expect(response, contains('登録'));
      chat.dispose();
    });

    test('local mode answers power question with device context', () async {
      final chat = ChatService(configService);
      final device = Device(
        id: 'user-pc',
        name: 'Test PC',
        modelNumber: 'X1',
        category: 'PC',
        manufacturer: 'TestCo',
        purchaseDate: '2024-01-01',
        purchasePrice: 100000,
        yearsOwned: 1,
        room: 'living-room',
        location: 'desk',
        status: 'active',
        consumables: [],
        photos: [],
        documents: [],
      );
      await chat.initializeWithDevices([device]);

      final response = await chat.sendMessage('電源がつかない');
      expect(response, contains('Test PC'));
      chat.dispose();
    });
  });
}
