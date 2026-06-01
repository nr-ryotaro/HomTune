import '../models/device.dart';
import 'config_service.dart';
import 'manual_search_service.dart';
import 'compliance_service.dart';

class ManualFetchService {
  static final ManualFetchService _instance = ManualFetchService._internal();
  factory ManualFetchService() => _instance;
  ManualFetchService._internal();

  /// 公式マニュアルURLを案内（PDF保存なし）
  ///
  /// [device]: 対象デバイス
  /// 戻り値: { 'state': ManualFetchState, 'url': String? }
  Future<Map<String, dynamic>> fetchOfficialManual(Device device) async {
    final searchService = ManualSearchService(ConfigService());
    final url = await searchService.searchManualUrl(
      device.manufacturer,
      device.modelNumber,
    );

    if (url != null && ComplianceService.isAllowedSourceUrl(url)) {
      await ComplianceService.logEvent(
        action: 'manual_link_resolved',
        targetId: device.id,
        result: 'ok',
      );
      return {
        'state': ManualFetchState.found,
        'url': url,
      };
    }

    await ComplianceService.logEvent(
      action: 'manual_link_resolved',
      targetId: device.id,
      result: 'not_found',
      reason: 'no_allowed_source',
    );
    return {
      'state': ManualFetchState.notFound,
      'url': null,
    };
  }
}
