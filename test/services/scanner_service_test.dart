import 'package:flutter_test/flutter_test.dart';
import 'package:homtune/services/config_service.dart';
import 'package:homtune/services/scanner_service.dart';
import 'package:homtune/services/web_search_service.dart';

// Manual mocks
class MockConfigService extends ConfigService {
  @override
  bool get isUsingRealApi => false;
}

class MockWebSearchService implements WebSearchService {
  String searchCallArg = '';

  @override
  Future<String> search(String query) async {
    searchCallArg = query;
    return '<html>Mock Result</html>';
  }
}

void main() {
  group('ScannerService Integration', () {
    late MockConfigService mockConfig;
    late MockWebSearchService mockWebSearch;
    late ScannerService scannerService;

    setUp(() {
      mockConfig = MockConfigService();
      mockWebSearch = MockWebSearchService();
      scannerService = ScannerService(mockConfig, webSearchService: mockWebSearch);
    });

    test('getProductInfoFromJan calls webSearch with correct query', () async {
      await scannerService.getProductInfoFromJan('123456');
      
      expect(mockWebSearch.searchCallArg, contains('123456'));
      expect(mockWebSearch.searchCallArg, contains('JANコード'));
    });

    test('refineProductInfo calls webSearch with manufacturer and model', () async {
      final initial = ExtractedProductInfo(
        manufacturer: 'TestMaker',
        modelNumber: 'TM-001',
        category: 'TestCat'
      );
      
      await scannerService.refineProductInfo(initial);
      
      expect(mockWebSearch.searchCallArg, contains('TestMaker'));
      expect(mockWebSearch.searchCallArg, contains('TM-001'));
    });

    test('refineProductInfo does nothing if modelNumber is empty', () async {
      final initial = ExtractedProductInfo(
        manufacturer: 'TestMaker',
        modelNumber: '',
        category: 'TestCat'
      );
      
      mockWebSearch.searchCallArg = '';
      await scannerService.refineProductInfo(initial);
      
      expect(mockWebSearch.searchCallArg, isEmpty);
    });

    test('Free tier extractProductInfo uses local OCR parse only', () async {
      final info = await scannerService.extractProductInfo(
        'メーカー ダイキン\nModel No. CS-ZX2811',
      );
      expect(info.manufacturer, 'ダイキン');
      expect(info.modelNumber, 'CS-ZX2811');
      expect(info.category, 'エアコン');
    });
  });
}
