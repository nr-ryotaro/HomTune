import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'config_service.dart';
import 'compliance_service.dart';

class WebSearchService {
  final ConfigService _configService;

  WebSearchService(this._configService);

  /// Perform a web search and return the HTML body or snippet.
  /// Uses a search engine that is friendly to scraping (e.g. DuckDuckGo html version).
  Future<String> search(String query) async {
    if (!_configService.isUsingRealApi) {
      return _mockSearch(query);
    }
    if (kReleaseMode) {
      await ComplianceService.logEvent(
        action: 'web_search_blocked',
        targetId: query,
        result: 'blocked',
        reason: 'scraping_disabled_in_release',
      );
      throw Exception('商用モードでは外部検索スクレイピングは無効化されています。');
    }

    try {
      // 開発用のみ: DuckDuckGo HTML 取得
      final uri = Uri.parse('https://html.duckduckgo.com/html/').replace(
        queryParameters: {'q': query},
      );

      final response = await http.get(uri, headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
      });

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw Exception('Failed to load search results: ${response.statusCode}');
      }
    } catch (e) {
      // 開発時のみモックフォールバック
      print('Search failed: $e, falling back to mock.');
      return _mockSearch(query);
    }
  }

  String _mockSearch(String query) {
    // Return some dummy HTML content based on query keywords
    if (query.contains('4901234567890')) {
      return '<html><title>Sample Product A - Manufacturer</title><body>Sample Product A Description</body></html>';
    }
    return '<html><title>$query - Search Results</title><body>Sample search results for $query</body></html>';
  }
}
