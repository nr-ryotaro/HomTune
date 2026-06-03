import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/ad_policy.dart';
import '../../services/config_service.dart';
import 'homtune_banner_ad.dart';
import 'pro_upsell_strip.dart';

/// ホーム・一覧など「信頼ゾーン外」画面用: 下部バナー + Pro 訴求
class FreePlanAdBody extends StatelessWidget {
  final String placement;
  final Widget child;

  const FreePlanAdBody({
    super.key,
    required this.placement,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConfigService>(
      builder: (context, config, _) {
        final showAds = AdPolicy.shouldShowFor(config) &&
            AdPolicy.isPlacementAllowed(placement);
        if (!showAds) return child;

        return Column(
          children: [
            Expanded(child: child),
            ProUpsellStrip(placement: placement),
            HomTuneBannerAd(placement: placement),
          ],
        );
      },
    );
  }
}
