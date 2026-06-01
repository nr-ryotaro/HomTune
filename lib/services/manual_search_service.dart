import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/platform_support.dart';
import 'config_service.dart';
import 'compliance_service.dart';

/// 公式マニュアル参照URLの解決（メーカー＋型番 → 許可HTTPS URLのみ、PDF保存なし）
/// 検索結果を SQLite にキャッシュし、API 呼び出しを最小限に抑える
class ManualSearchService {
  static const String _dbName = 'homtune_manual_cache.db';
  static const int _dbVersion = 1;
  static const String _table = 'manual_cache';

  final ConfigService _configService;
  Database? _db;

  /// Web プレビュー用インメモリキャッシュ（sqflite 非対応のため）
  static final Map<String, String> _memoryCache = {};

  ManualSearchService(this._configService);

  static String _cacheKey(String manufacturer, String modelNumber) =>
      '${manufacturer.trim().toLowerCase()}|${modelNumber.trim().toLowerCase()}';

  /// ダミーモード用: メーカー×型番 → URL（機能確認用）
  static final Map<String, String> _dummyManualUrls = {
    'ダイキン|CS-ZX2811': 'https://www.daikin.co.jp/support/manual/',
    'ダイキン|CS-': 'https://www.daikin.co.jp/support/manual/',
    'パナソニック|TH-': 'https://panasonic.jp/support/manual/',
    'パナソニック|KX-': 'https://panasonic.jp/support/manual/',
    '三菱|MSZ-': 'https://www.mitsubishi-electric.co.jp/home/products/support/manual/',
    'シャープ|AH-': 'https://k-tai.sharp.co.jp/support/manual/',
    'ソニー|KDL-': 'https://www.sony.com/electronics/support',
    'ソニー|XBR-': 'https://www.sony.com/electronics/support',
    'Apple|Mac': 'https://support.apple.com/manuals',
    'Apple|iPhone': 'https://support.apple.com/manuals',
    'LG|OLED': 'https://www.lg.com/jp/support/manual',
    'サムスン|QE': 'https://www.samsung.com/jp/support/manual/',
    '日立|RAS-': 'https://kadenfan.hitachi.co.jp/support/manual/',
    '東芝|REGZA': 'https://www.toshiba-consumer.co.jp/support/manual/',
  };

  Future<Database> _getDb() async {
    if (PlatformSupport.supportsManualSqliteCache == false) {
      throw UnsupportedError('SQLite cache is not available on Web preview');
    }
    if (_db != null && _db!.isOpen) return _db!;
    final base = await getDatabasesPath();
    final dbPath = path.join(base, _dbName);
    _db = await openDatabase(
      dbPath,
      version: _dbVersion,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE $_table (
            manufacturer TEXT NOT NULL,
            model_number TEXT NOT NULL,
            url TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (manufacturer, model_number)
          )
        ''');
      },
    );
    return _db!;
  }

  /// キャッシュから URL 取得
  Future<String?> getCachedUrl(String manufacturer, String modelNumber) async {
    if (!PlatformSupport.supportsManualSqliteCache) {
      return _memoryCache[_cacheKey(manufacturer, modelNumber)];
    }
    try {
      final db = await _getDb();
      final rows = await db.query(
        _table,
        columns: ['url'],
        where: 'manufacturer = ? AND model_number = ?',
        whereArgs: [manufacturer.trim(), modelNumber.trim()],
      );
      if (rows.isEmpty) return null;
      return rows.first['url'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// キャッシュに保存
  Future<void> _cacheUrl(
    String manufacturer,
    String modelNumber,
    String url,
  ) async {
    if (!PlatformSupport.supportsManualSqliteCache) {
      _memoryCache[_cacheKey(manufacturer, modelNumber)] = url;
      return;
    }
    try {
      final db = await _getDb();
      await db.insert(
        _table,
        {
          'manufacturer': manufacturer.trim(),
          'model_number': modelNumber.trim(),
          'url': url,
          'created_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // キャッシュ失敗は無視（検索は成功している）
    }
  }

  /// メーカー＋型番で公式マニュアル参照URLを検索
  /// まずキャッシュを確認し、未ヒット時のみネット検索（モック／実API）
  Future<String?> searchManualUrl(String manufacturer, String modelNumber) async {
    if (manufacturer.trim().isEmpty && modelNumber.trim().isEmpty) {
      return null;
    }

    final cached = await getCachedUrl(manufacturer, modelNumber);
    if (cached != null && cached.isNotEmpty) return cached;

    String? url;
    try {
      url = await _searchManualUrlImpl(manufacturer, modelNumber);
    } catch (e) {
      return null;
    }

    if (url != null &&
        url.isNotEmpty &&
        ComplianceService.isAllowedSourceUrl(url)) {
      await _cacheUrl(manufacturer, modelNumber, url);
      await ComplianceService.logEvent(
        action: 'manual_url_lookup',
        targetId: '$manufacturer:$modelNumber',
        result: 'ok',
      );
      return url;
    }
    await ComplianceService.logEvent(
      action: 'manual_url_lookup',
      targetId: '$manufacturer:$modelNumber',
      result: 'blocked',
      reason: 'unapproved_or_empty_source',
    );
    return null;
  }

  /// ダミーモード: Map から URL を返す（機能確認用）
  String? _searchManualUrlDummy(String manufacturer, String modelNumber) {
    final m = manufacturer.trim();
    final model = modelNumber.trim();
    if (m.isEmpty && model.isEmpty) return null;
    final key1 = '$m|$model';
    if (_dummyManualUrls.containsKey(key1)) return _dummyManualUrls[key1];
    for (final e in _dummyManualUrls.entries) {
      final parts = e.key.split('|');
      if (parts.length != 2) continue;
      final brand = parts[0];
      final prefix = parts[1];
      if (m.contains(brand) || manufacturer.toLowerCase().contains(brand.toLowerCase())) {
        if (model.startsWith(prefix) || modelNumber.startsWith(prefix)) return e.value;
      }
    }
    return null;
  }

  /// 実際の検索ロジック（モック＋一部メーカー固有ルール）
  /// 本番では Google Custom Search API 等でPDFを特定する想定
  Future<String?> _searchManualUrlImpl(String manufacturer, String modelNumber) async {
    if (!_configService.isUsingRealApi) {
      return _searchManualUrlDummy(manufacturer, modelNumber);
    }

    final m = manufacturer.trim().toLowerCase();
    final model = modelNumber.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\-_]'), '-');
    if (model.isEmpty) return null;

    // 既知メーカー向けのモックPDF URL（実際の型番別URLは公式サイトで要確認）
    if (m.contains('ダイキン') || m.contains('daikin')) {
      return 'https://www.daikin.co.jp/support/manual/';
    }
    if (m.contains('パナソニック') || m.contains('panasonic')) {
      return 'https://panasonic.jp/support/manual/';
    }
    if (m.contains('三菱') || m.contains('mitsubishi')) {
      return 'https://www.mitsubishi-electric.co.jp/home/products/support/manual/';
    }
    if (m.contains('シャープ') || m.contains('sharp')) {
      return 'https://k-tai.sharp.co.jp/support/manual/';
    }
    if (m.contains('ソニー') || m.contains('sony')) {
      return 'https://www.sony.com/electronics/support';
    }
    if (m.contains('apple')) {
      if (kReleaseMode) return 'https://support.apple.com/manuals';
      return 'https://support.apple.com/manuals/$model';
    }
    if (m.contains('lg')) {
      return 'https://www.lg.com/jp/support/manual';
    }
    if (m.contains('サムスン') || m.contains('samsung')) {
      return 'https://www.samsung.com/jp/support/manual/';
    }
    if (m.contains('日立') || m.contains('hitachi')) {
      return 'https://kadenfan.hitachi.co.jp/support/manual/';
    }
    if (m.contains('東芝') || m.contains('toshiba')) {
      return 'https://www.toshiba-consumer.co.jp/support/manual/';
    }

    // 汎用: キャッシュ未ヒット・未知メーカーは null（手動登録を促す）
    return null;
  }

  /// URL が有効か簡易チェック（HEAD で 200）
  Future<bool> checkUrlReachable(String url) async {
    try {
      final res = await http.head(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('timeout'),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 説明書アーカイブ完了通知用の文言（UIで使用）
  static String get archiveCompleteMessage =>
      '公式マニュアルの参照リンクを更新しました。';

  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
