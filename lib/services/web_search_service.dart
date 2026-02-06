import 'package:http/http.dart' as http;
import 'config_service.dart';

class WebSearchService {
  final ConfigService _configService;

  WebSearchService(this._configService);

  /// Perform a web search and return the HTML body or snippet.
  /// Uses a search engine that is friendly to scraping (e.g. DuckDuckGo html version).
  Future<String> search(String query) async {
    if (!_configService.isUsingRealApi) {
      return _mockSearch(query);
    }

    try {
      // Using DuckDuckGo HTML version which is easier to scrape and doesn't require JS
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
      // Fallback to mock if network fails just to keep app alive
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
