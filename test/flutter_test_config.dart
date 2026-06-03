import 'dart:async';

import 'package:homtune/services/ad_policy.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AdPolicy.setEnabledInTests(false);
  await testMain();
}
