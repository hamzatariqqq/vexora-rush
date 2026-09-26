import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  final SharedPreferencesAsync _prefs =
  SharedPreferencesAsync();

  int coins = 0;
  double bestDistance = 0;

  String selectedBall = 'plasma';
  Set<String> unlockedBalls = {
    'plasma',
  };

  String selectedMap = 'neon_city';
  Set<String> unlockedMaps = {
    'neon_city',
  };

  bool soundOn = true;
  bool musicOn = true;
  bool vibrationOn = true;

  int dailyDistance = 0;
  int dailyDodges = 0;
  int dailyCoins = 0;

  Set<int> claimedMissions = {};

  int adRewardsToday = 0;
  int lastAdRewardMillis = 0;

  String _adRewardDay = '';

  // Daily missions:
  //
  // 1. Travel 2,500 metres
  // 2. Dodge 40 hazards
  // 3. Collect 20 gameplay coins
  //
  // Rewards remain useful without flooding
  // the player's economy.
  static const missionGoals = <int>[
    2500,
    40,
    20,
  ];

  static const missionRewards = <int>[
    50,
    60,
    75,
  ];

  // Rewarded ad economy.
  static const maxAdRewardsPerDay = 3;

  static const adCooldown =
  Duration(
    minutes: 20,
  );

  String get _today {
    final now =
    DateTime.now();

    final month =
    now.month
        .toString()
        .padLeft(
      2,
      '0',
    );

    final day =
    now.day
        .toString()
        .padLeft(
      2,
      '0',
    );

    return '${now.year}-$month-$day';
  }

  int get currentAdRewards {
    if (_adRewardDay != _today) {
      return 0;
    }

    return adRewardsToday;
  }

  Duration get adWaitRemaining {
    if (_adRewardDay != _today) {
      return Duration.zero;
    }

    if (lastAdRewardMillis <= 0) {
      return Duration.zero;
    }

    final elapsed =
        DateTime.now()
            .millisecondsSinceEpoch -
            lastAdRewardMillis;

    final remaining =
        adCooldown.inMilliseconds -
            elapsed;

    if (remaining <= 0) {
      return Duration.zero;
    }

    return Duration(
      milliseconds: remaining,
    );
  }

  bool get canWatchForCoins {
    return currentAdRewards <
        maxAdRewardsPerDay &&
        adWaitRemaining ==
            Duration.zero;
  }

  Future<void> load() async {
    coins =
        await _prefs.getInt(
          'coins',
        ) ??
            0;

    bestDistance =
        await _prefs.getDouble(
          'bestDistance',
        ) ??
            0;

    unlockedBalls = {
      'plasma',
      ...?await _prefs.getStringList(
        'unlockedBalls',
      ),
    };

    selectedBall =
        await _prefs.getString(
          'selectedBall',
        ) ??
            'plasma';

    if (!unlockedBalls.contains(
      selectedBall,
    )) {
      selectedBall =
      'plasma';
    }

    unlockedMaps = {
      'neon_city',
      ...?await _prefs.getStringList(
        'unlockedMaps',
      ),
    };

    selectedMap =
        await _prefs.getString(
          'selectedMap',
        ) ??
            'neon_city';

    if (!unlockedMaps.contains(
      selectedMap,
    )) {
      selectedMap =
      'neon_city';
    }

    soundOn =
        await _prefs.getBool(
          'soundOn',
        ) ??
            true;

    musicOn =
        await _prefs.getBool(
          'musicOn',
        ) ??
            true;

    vibrationOn =
        await _prefs.getBool(
          'vibrationOn',
        ) ??
            true;

    adRewardsToday =
        await _prefs.getInt(
          'adRewardsToday',
        ) ??
            0;

    lastAdRewardMillis =
        await _prefs.getInt(
          'lastAdRewardMillis',
        ) ??
            0;

    _adRewardDay =
        await _prefs.getString(
          'adRewardDay',
        ) ??
            '';

    await refreshDailyMissions();

    notifyListeners();
  }

  Future<void>
  refreshDailyMissions() async {
    final savedDay =
    await _prefs.getString(
      'missionDay',
    );

    if (savedDay == _today) {
      dailyDistance =
          await _prefs.getInt(
            'dailyDistance',
          ) ??
              0;

      dailyDodges =
          await _prefs.getInt(
            'dailyDodges',
          ) ??
              0;

      dailyCoins =
          await _prefs.getInt(
            'dailyCoins',
          ) ??
              0;

      claimedMissions =
          (await _prefs
              .getStringList(
            'claimedMissions',
          ) ??
              [])
              .map(
            int.tryParse,
          )
              .whereType<int>()
              .toSet();
    } else {
      dailyDistance = 0;
      dailyDodges = 0;
      dailyCoins = 0;

      claimedMissions = {};

      await _prefs.setString(
        'missionDay',
        _today,
      );

      await _saveMissionProgress();
    }

    notifyListeners();
  }

  int missionProgress(
      int index,
      ) {
    switch (index) {
      case 0:
        return dailyDistance;

      case 1:
        return dailyDodges;

      case 2:
        return dailyCoins;

      default:
        return 0;
    }
  }

  Future<void>
  _saveMissionProgress() async {
    await _prefs.setInt(
      'dailyDistance',
      dailyDistance,
    );

    await _prefs.setInt(
      'dailyDodges',
      dailyDodges,
    );

    await _prefs.setInt(
      'dailyCoins',
      dailyCoins,
    );

    await _prefs.setStringList(
      'claimedMissions',
      claimedMissions
          .map(
            (value) =>
        '$value',
      )
          .toList(),
    );
  }

  Future<void> recordRun(
      double distance,
      int earnedCoins,
      int dodges, {
        required double distanceGain,
      }) async {
    await refreshDailyMissions();

    final safeCoins =
    earnedCoins < 0
        ? 0
        : earnedCoins;

    final safeDodges =
    dodges < 0
        ? 0
        : dodges;

    final safeDistance =
    distanceGain < 0
        ? 0.0
        : distanceGain;

    coins += safeCoins;

    if (distance >
        bestDistance) {
      bestDistance =
          distance;
    }

    dailyDistance +=
        safeDistance.floor();

    dailyDodges +=
        safeDodges;

    dailyCoins +=
        safeCoins;

    notifyListeners();

    await _prefs.setInt(
      'coins',
      coins,
    );

    await _prefs.setDouble(
      'bestDistance',
      bestDistance,
    );

    await _saveMissionProgress();
  }

  Future<bool> claimMission(
      int index,
      ) async {
    await refreshDailyMissions();

    if (index < 0 ||
        index >=
            missionGoals.length) {
      return false;
    }

    if (claimedMissions.contains(
      index,
    )) {
      return false;
    }

    if (missionProgress(index) <
        missionGoals[index]) {
      return false;
    }

    claimedMissions.add(
      index,
    );

    coins +=
    missionRewards[index];

    notifyListeners();

    await _prefs.setInt(
      'coins',
      coins,
    );

    await _saveMissionProgress();

    return true;
  }

  Future<bool>
  creditRewardedCoins() async {
    if (!canWatchForCoins) {
      return false;
    }

    if (_adRewardDay !=
        _today) {
      _adRewardDay =
          _today;

      adRewardsToday = 0;
    }

    adRewardsToday++;

    lastAdRewardMillis =
        DateTime.now()
            .millisecondsSinceEpoch;

    coins += 100;

    notifyListeners();

    await _prefs.setString(
      'adRewardDay',
      _adRewardDay,
    );

    await _prefs.setInt(
      'adRewardsToday',
      adRewardsToday,
    );

    await _prefs.setInt(
      'lastAdRewardMillis',
      lastAdRewardMillis,
    );

    await _prefs.setInt(
      'coins',
      coins,
    );

    return true;
  }

  Future<bool> unlockBall(
      String id,
      int price,
      ) async {
    if (unlockedBalls.contains(
      id,
    )) {
      return false;
    }

    if (price < 0 ||
        coins < price) {
      return false;
    }

    coins -= price;

    unlockedBalls.add(
      id,
    );

    selectedBall = id;

    notifyListeners();

    await _prefs.setInt(
      'coins',
      coins,
    );

    await _prefs.setStringList(
      'unlockedBalls',
      unlockedBalls.toList(),
    );

    await _prefs.setString(
      'selectedBall',
      id,
    );

    return true;
  }

  Future<void> selectBall(
      String id,
      ) async {
    if (!unlockedBalls.contains(
      id,
    )) {
      return;
    }

    selectedBall = id;

    notifyListeners();

    await _prefs.setString(
      'selectedBall',
      id,
    );
  }

  Future<bool> unlockMap(
      String id,
      int price,
      ) async {
    if (unlockedMaps.contains(
      id,
    )) {
      return false;
    }

    if (price < 0 ||
        coins < price) {
      return false;
    }

    coins -= price;

    unlockedMaps.add(
      id,
    );

    selectedMap = id;

    notifyListeners();

    await _prefs.setInt(
      'coins',
      coins,
    );

    await _prefs.setStringList(
      'unlockedMaps',
      unlockedMaps.toList(),
    );

    await _prefs.setString(
      'selectedMap',
      id,
    );

    return true;
  }

  Future<void> selectMap(
      String id,
      ) async {
    if (!unlockedMaps.contains(
      id,
    )) {
      return;
    }

    selectedMap = id;

    notifyListeners();

    await _prefs.setString(
      'selectedMap',
      id,
    );
  }

  Future<void> setSound(
      bool value,
      ) async {
    soundOn = value;

    notifyListeners();

    await _prefs.setBool(
      'soundOn',
      value,
    );
  }

  Future<void> setMusic(
      bool value,
      ) async {
    musicOn = value;

    notifyListeners();

    await _prefs.setBool(
      'musicOn',
      value,
    );
  }

  Future<void> setVibration(
      bool value,
      ) async {
    vibrationOn =
        value;

    notifyListeners();

    await _prefs.setBool(
      'vibrationOn',
      value,
    );
  }
}