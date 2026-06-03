import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../config/admob_config.dart';
import '../../services/ad_policy.dart';
import '../../services/ad_service.dart';

/// Free 向けアダプティブバナー（下部固定）
class HomTuneBannerAd extends StatefulWidget {
  final String placement;

  const HomTuneBannerAd({super.key, required this.placement});

  @override
  State<HomTuneBannerAd> createState() => _HomTuneBannerAdState();
}

class _HomTuneBannerAdState extends State<HomTuneBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _loadStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tryLoad();
  }

  Future<void> _tryLoad() async {
    if (_loadStarted || _isLoaded) return;
    if (!AdPolicy.isPlacementAllowed(widget.placement)) return;
    _loadStarted = true;

    await AdService.instance.ensureInitialized();
    if (!mounted || !AdService.instance.isReady) return;

    final width = MediaQuery.sizeOf(context).width.truncate();
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;

    final adUnitId = AdMobConfig.bannerAdUnitId(defaultTargetPlatform);
    if (adUnitId == null) {
      _loadStarted = false;
      return;
    }
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
          AdService.instance.logBannerLoaded(widget.placement);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          AdService.instance.logBannerFailed(
            widget.placement,
            '${error.code}',
          );
          if (mounted) setState(() => _loadStarted = false);
        },
      ),
    );
    await banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    final ad = _bannerAd!;
    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        color: const Color(0xFFF5F5F5),
        alignment: Alignment.center,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}
