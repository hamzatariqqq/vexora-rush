import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Google's official rewarded test ad.
  // Used automatically in debug builds.
  static const String _rewardedTestAdUnit =
      'ca-app-pub-3940256099942544/5224354917';

  // Vexora Rush production rewarded ads.
  static const String _coinsRewardedAdUnit =
      'ca-app-pub-9973042638438490/1930452275';

  static const String _reviveRewardedAdUnit =
      'ca-app-pub-9973042638438490/3051962250';

  Future<InitializationStatus>? _initialization;

  bool _busy = false;

  Future<void> initialize() async {
    _initialization ??=
        MobileAds.instance.initialize();

    await _initialization;
  }

  String get _coinsAdUnitId {
    if (kReleaseMode) {
      return _coinsRewardedAdUnit;
    }

    return _rewardedTestAdUnit;
  }

  String get _reviveAdUnitId {
    if (kReleaseMode) {
      return _reviveRewardedAdUnit;
    }

    return _rewardedTestAdUnit;
  }

  /// Used by the Reward Shop.
  Future<bool> showRewarded() {
    return _showRewarded(
      _coinsAdUnitId,
    );
  }

  /// Used when the player dies and chooses Revive.
  Future<bool> showReviveRewarded() {
    return _showRewarded(
      _reviveAdUnitId,
    );
  }

  Future<bool> _showRewarded(
      String adUnitId,
      ) async {
    if (_busy) {
      return false;
    }

    _busy = true;

    try {
      await initialize();
    } catch (_) {
      _busy = false;
      return false;
    }

    final result =
    Completer<bool>();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback:
      RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earned = false;
          var completed = false;

          void finish(
              bool success,
              ) {
            if (completed) {
              return;
            }

            completed = true;
            _busy = false;

            ad.dispose();

            if (!result.isCompleted) {
              result.complete(
                success,
              );
            }
          }

          ad.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent:
                    (_) {
                  finish(
                    earned,
                  );
                },
                onAdFailedToShowFullScreenContent:
                    (
                    _,
                    error,
                    ) {
                  finish(
                    false,
                  );
                },
              );

          try {
            ad.show(
              onUserEarnedReward:
                  (
                  ad,
                  reward,
                  ) {
                earned = true;
              },
            );
          } catch (_) {
            finish(
              false,
            );
          }
        },
        onAdFailedToLoad: (
            error,
            ) {
          _busy = false;

          if (!result.isCompleted) {
            result.complete(
              false,
            );
          }
        },
      ),
    );

    return result.future;
  }
}