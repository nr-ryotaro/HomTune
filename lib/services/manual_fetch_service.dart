import 'dart:math';
import '../models/device.dart';

class ManualFetchService {
  static final ManualFetchService _instance = ManualFetchService._internal();
  factory ManualFetchService() => _instance;
  ManualFetchService._internal();

  /// 公式マニュアルを取得 (シミュレーション)
  ///
  /// [device]: 対象デバイス
  /// 戻り値: { 'state': ManualFetchState, 'url': String? }
  Future<Map<String, dynamic>> fetchOfficialManual(Device device) async {
    // 検索中状態 (UI側でstateをfetchingにする想定だが、ここでも遅延を入れる)
    await Future.delayed(const Duration(seconds: 3));

    final random = Random();
    // 70%の確率で成功
    final isSuccess = random.nextDouble() < 0.7;

    if (isSuccess) {
      // ダミーPDF URL
      return {
        'state': ManualFetchState.found,
        'url':
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf', // 一般的なダミーPDF
      };
    } else {
      return {
        'state': ManualFetchState.notFound,
        'url': null,
      };
    }
  }
}
