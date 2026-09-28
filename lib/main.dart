import 'dart:async';
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'game/vexora_rush_game.dart';
import 'models/ball_style.dart';
import 'models/map_style.dart';
import 'screens/progression_screens.dart';
import 'screens/reward_shop_screen.dart';
import 'screens/splash_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  } catch (e) {
    debugPrint('System UI startup error: $e');
  }

  final storage = StorageService();

  try {
    await storage.load();
  } catch (e) {
    debugPrint('Storage startup error: $e');
  }

  final ads = AdService();

  runApp(
    VexoraRushApp(
      storage: storage,
      ads: ads,
    ),
  );

  Future<void>(() async {
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('AdMob initialization error: $e');
    }
  });
}

class VexoraRushApp extends StatelessWidget {
  const VexoraRushApp({
    super.key,
    required this.storage,
    required this.ads,
  });

  final StorageService storage;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vexora Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF070B18),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF53EAFF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: VexoraSplashScreen(
        nextScreen: HomeScreen(
          storage: storage,
          ads: ads,
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.storage,
    required this.ads,
  });

  final StorageService storage;
  final AdService ads;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, child) {
        final selectedBall = ballStyles.firstWhere(
              (ball) => ball.id == storage.selectedBall,
          orElse: () => ballStyles.first,
        );

        final selectedMap = mapStyles.firstWhere(
              (map) => map.id == storage.selectedMap,
          orElse: () => mapStyles.first,
        );

        return Scaffold(
          body: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: -110,
                  left: -90,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF53EAFF).withValues(
                        alpha: 0.05,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF53EAFF).withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 100,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: -120,
                  bottom: 80,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selectedMap.edge.withValues(
                        alpha: 0.04,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: selectedMap.edge.withValues(
                            alpha: 0.08,
                          ),
                          blurRadius: 100,
                        ),
                      ],
                    ),
                  ),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    18,
                    18,
                    26,
                  ),
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VEXORA',
                                style: TextStyle(
                                  fontSize: 29,
                                  height: 0.95,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 3,
                                ),
                              ),
                              Text(
                                'RUSH',
                                style: TextStyle(
                                  fontSize: 29,
                                  height: 1,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 6,
                                  color: Color(
                                    0xFF53EAFF,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'DASH • DODGE • SURVIVE',
                                style: TextStyle(
                                  fontSize: 9,
                                  letterSpacing: 1.8,
                                  color: Color(
                                    0xFF8195B8,
                                  ),
                                  fontWeight:
                                  FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding:
                          const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 9,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF141E35,
                            ),
                            borderRadius:
                            BorderRadius.circular(
                              30,
                            ),
                            border: Border.all(
                              color: const Color(
                                0xFF2B3C5D,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .monetization_on_rounded,
                                color: Color(
                                  0xFFFFC64A,
                                ),
                                size: 19,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${storage.coins}',
                                style:
                                const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.w900,
                                  color: Color(
                                    0xFFFFD166,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    Container(
                      padding:
                      const EdgeInsets.fromLTRB(
                        18,
                        20,
                        18,
                        18,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end:
                          Alignment.bottomRight,
                          colors: [
                            selectedMap.edge
                                .withValues(
                              alpha: 0.12,
                            ),
                            const Color(
                              0xFF111A31,
                            ),
                            const Color(
                              0xFF0D1428,
                            ),
                          ],
                        ),
                        borderRadius:
                        BorderRadius.circular(
                          28,
                        ),
                        border: Border.all(
                          color:
                          selectedMap.edge
                              .withValues(
                            alpha: 0.32,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                            selectedBall.color
                                .withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 35,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration:
                                BoxDecoration(
                                  color:
                                  const Color(
                                    0xFF09101F,
                                  ).withValues(
                                    alpha: 0.7,
                                  ),
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    20,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.map_rounded,
                                      size: 14,
                                      color:
                                      selectedMap
                                          .edge,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      selectedMap.name
                                          .toUpperCase(),
                                      style:
                                      TextStyle(
                                        color:
                                        selectedMap
                                            .edge,
                                        fontSize: 10,
                                        fontWeight:
                                        FontWeight
                                            .w900,
                                        letterSpacing:
                                        0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.bolt_rounded,
                                color: Color(
                                  0xFF53EAFF,
                                ),
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'READY',
                                style: TextStyle(
                                  color: Color(
                                    0xFF7FDDBF,
                                  ),
                                  fontSize: 10,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 16,
                          ),

                          SizedBox(
                            height: 165,
                            child: Center(
                              child: _BallPreview(
                                ball:
                                selectedBall,
                                size: 118,
                                showGlow: true,
                              ),
                            ),
                          ),

                          Text(
                            selectedBall.name
                                .toUpperCase(),
                            style:
                            const TextStyle(
                              fontSize: 20,
                              fontWeight:
                              FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 4),

                          const Text(
                            'CURRENT BALL',
                            style: TextStyle(
                              fontSize: 9,
                              color: Color(
                                0xFF7E91B4,
                              ),
                              fontWeight:
                              FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          SizedBox(
                            width:
                            double.infinity,
                            height: 58,
                            child:
                            FilledButton.icon(
                              onPressed: () {
                                Navigator.of(
                                  context,
                                ).push(
                                  MaterialPageRoute<
                                      void>(
                                    builder: (_) =>
                                        GameScreen(
                                          storage:
                                          storage,
                                          ads: ads,
                                          ballStyleId:
                                          selectedBall
                                              .id,
                                          ballColor:
                                          selectedBall
                                              .color,
                                          mapStyle:
                                          selectedMap,
                                        ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons
                                    .play_arrow_rounded,
                                size: 29,
                              ),
                              label: const Text(
                                'START RUN',
                                style:
                                TextStyle(
                                  fontSize: 17,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                  letterSpacing:
                                  1.7,
                                ),
                              ),
                              style: FilledButton
                                  .styleFrom(
                                backgroundColor:
                                const Color(
                                  0xFF53EAFF,
                                ),
                                foregroundColor:
                                const Color(
                                  0xFF06111C,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    17,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child:
                          _HomeStatCard(
                            label: 'BEST RUN',
                            value:
                            '${storage.bestDistance.floor()} m',
                            icon:
                            Icons.speed_rounded,
                            color:
                            const Color(
                              0xFF53EAFF,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                          _HomeStatCard(
                            label: 'BALLS',
                            value:
                            '${storage.unlockedBalls.length}/${ballStyles.length}',
                            icon: Icons
                                .sports_baseball_rounded,
                            color:
                            const Color(
                              0xFFFF6C91,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child:
                          _HomeStatCard(
                            label: 'MAPS',
                            value:
                            '${storage.unlockedMaps.length}/${mapStyles.length}',
                            icon:
                            Icons.public_rounded,
                            color:
                            const Color(
                              0xFF9A7BFF,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'GAME HUB',
                      style: TextStyle(
                        color: Color(
                          0xFF91A6C9,
                        ),
                        fontSize: 11,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: 1.8,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _HubButton(
                            title: 'BALLS',
                            subtitle:
                            'Unlock styles',
                            icon: Icons.circle,
                            color:
                            const Color(
                              0xFF53EAFF,
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute<
                                    void>(
                                  builder: (_) =>
                                      BallsScreen(
                                        storage:
                                        storage,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HubButton(
                            title: 'MAPS',
                            subtitle:
                            'Change world',
                            icon:
                            Icons.map_rounded,
                            color:
                            const Color(
                              0xFF9A7BFF,
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute<
                                    void>(
                                  builder: (_) =>
                                      MapsScreen(
                                        storage:
                                        storage,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _HubButton(
                            title: 'MISSIONS',
                            subtitle:
                            'Earn rewards',
                            icon:
                            Icons.flag_rounded,
                            color:
                            const Color(
                              0xFFFFC64A,
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute<
                                    void>(
                                  builder: (_) =>
                                      MissionsScreen(
                                        storage:
                                        storage,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _HubButton(
                            title: 'REWARDS',
                            subtitle:
                            'Watch & earn',
                            icon: Icons
                                .play_circle_fill_rounded,
                            color:
                            const Color(
                              0xFF65E3A7,
                            ),
                            onTap: () {
                              Navigator.of(
                                context,
                              ).push(
                                MaterialPageRoute<
                                    void>(
                                  builder: (_) =>
                                      RewardShopScreen(
                                        storage:
                                        storage,
                                        ads: ads,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    _HubButton(
                      title: 'SETTINGS',
                      subtitle:
                      'Sound, music and vibration',
                      icon:
                      Icons.settings_rounded,
                      color: const Color(
                        0xFF8EA4C8,
                      ),
                      wide: true,
                      onTap: () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                SettingsScreen(
                                  storage: storage,
                                ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HomeStatCard extends StatelessWidget {
  const _HomeStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 13,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF11192E,
        ),
        borderRadius:
        BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(
            0xFF263755,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            maxLines: 1,
            style:
            const TextStyle(
              fontSize: 14,
              fontWeight:
              FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            style:
            const TextStyle(
              color: Color(
                0xFF778BAE,
              ),
              fontSize: 8,
              fontWeight:
              FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubButton extends StatelessWidget {
  const _HubButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.wide = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(
        0xFF11192E,
      ),
      borderRadius:
      BorderRadius.circular(
        18,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
        BorderRadius.circular(
          18,
        ),
        child: Container(
          padding:
          const EdgeInsets.all(
            14,
          ),
          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              18,
            ),
            border: Border.all(
              color: const Color(
                0xFF273755,
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,
                  color:
                  color.withValues(
                    alpha: 0.11,
                  ),
                  border:
                  Border.all(
                    color:
                    color.withValues(
                      alpha: 0.32,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        fontSize: 12,
                        fontWeight:
                        FontWeight
                            .w900,
                        letterSpacing:
                        0.7,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow:
                      TextOverflow
                          .ellipsis,
                      style:
                      const TextStyle(
                        fontSize: 9,
                        color: Color(
                          0xFF7E91B4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (wide)
                const Icon(
                  Icons
                      .chevron_right_rounded,
                  color: Color(
                    0xFF647A9F,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
class BallsScreen extends StatefulWidget {
  const BallsScreen({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  State<BallsScreen> createState() => _BallsScreenState();
}

class _BallsScreenState extends State<BallsScreen> {
  String? _bannerMessage;

  Color _bannerColor = const Color(0xFFFFC64A);

  IconData _bannerIcon = Icons.lock_rounded;

  Timer? _bannerTimer;

  void _showBanner(
      String message, {
        Color color = const Color(0xFFFFC64A),
        IconData icon = Icons.lock_rounded,
      }) {
    _bannerTimer?.cancel();

    setState(() {
      _bannerMessage = message;
      _bannerColor = color;
      _bannerIcon = icon;
    });

    _bannerTimer = Timer(
      const Duration(milliseconds: 1900),
          () {
        if (!mounted) {
          return;
        }

        setState(() {
          _bannerMessage = null;
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = widget.storage;

    return ListenableBuilder(
      listenable: storage,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'BALLS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  110,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 17,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF131D35),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF2B3D5E),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.monetization_on_rounded,
                          color: Color(0xFFFFC64A),
                          size: 29,
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR BALANCE',
                                style: TextStyle(
                                  color: Color(0xFF8195B8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Unlock new ball styles',
                                style: TextStyle(
                                  color: Color(0xFF697D9F),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${storage.coins}',
                          style: const TextStyle(
                            color: Color(0xFFFFD166),
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 19),
                  const Text(
                    'BALL COLLECTION',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${storage.unlockedBalls.length} of ${ballStyles.length} unlocked',
                    style: const TextStyle(
                      color: Color(0xFF8296B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 17),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ballStyles.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      childAspectRatio: 0.73,
                    ),
                    itemBuilder: (context, index) {
                      final ball = ballStyles[index];

                      final unlocked =
                      storage.unlockedBalls.contains(ball.id);

                      final selected =
                          storage.selectedBall == ball.id;

                      return _AnimatedBallCard(
                        ball: ball,
                        unlocked: unlocked,
                        selected: selected,
                        storage: storage,
                        onBanner: _showBanner,
                      );
                    },
                  ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: IgnorePointer(
                  ignoring: _bannerMessage == null,
                  child: _BallAnimatedBanner(
                    message: _bannerMessage,
                    color: _bannerColor,
                    icon: _bannerIcon,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AnimatedBallCard extends StatefulWidget {
  const _AnimatedBallCard({
    required this.ball,
    required this.unlocked,
    required this.selected,
    required this.storage,
    required this.onBanner,
  });

  final BallStyle ball;
  final bool unlocked;
  final bool selected;
  final StorageService storage;

  final void Function(
      String message, {
      Color color,
      IconData icon,
      }) onBanner;

  @override
  State<_AnimatedBallCard> createState() =>
      _AnimatedBallCardState();
}

class _AnimatedBallCardState extends State<_AnimatedBallCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(
      reverse: true,
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 470),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _showLockedFeedback(int neededCoins) {
    _shakeController.forward(
      from: 0,
    );

    widget.onBanner(
      'You need $neededCoins more coins.',
      color: const Color(0xFFFFC64A),
      icon: Icons.lock_rounded,
    );
  }

  Future<void> _handleTap() async {
    if (widget.selected) {
      return;
    }

    if (widget.unlocked) {
      await widget.storage.selectBall(
        widget.ball.id,
      );

      if (!mounted) {
        return;
      }

      widget.onBanner(
        '${widget.ball.name} selected.',
        color: widget.ball.color,
        icon: Icons.check_circle_rounded,
      );

      return;
    }

    final success = await widget.storage.unlockBall(
      widget.ball.id,
      widget.ball.price,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      widget.onBanner(
        '${widget.ball.name} unlocked!',
        color: const Color(0xFF65E3A7),
        icon: Icons.auto_awesome_rounded,
      );

      return;
    }

    final needed =
        widget.ball.price - widget.storage.coins;

    _showLockedFeedback(needed);
  }

  @override
  Widget build(BuildContext context) {
    final ball = widget.ball;
    final unlocked = widget.unlocked;
    final selected = widget.selected;

    return AnimatedBuilder(
      animation: Listenable.merge(
        [
          _pulseController,
          _shimmerController,
          _shakeController,
        ],
      ),
      builder: (context, child) {
        final pulse =
            0.55 + (_pulseController.value * 0.45);

        final shake =
            math.sin(
              _shakeController.value *
                  math.pi *
                  7,
            ) *
                (1 - _shakeController.value) *
                10;

        final borderColor = selected
            ? ball.color
            : unlocked
            ? const Color(0xFF283A59)
            : ball.color.withValues(
          alpha: 0.22 + pulse * 0.25,
        );

        final glowColor = selected
            ? ball.color.withValues(
          alpha: 0.10 + pulse * 0.10,
        )
            : ball.color.withValues(
          alpha: 0.03 + pulse * 0.08,
        );

        return Transform.translate(
          offset: Offset(
            shake,
            0,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              color: const Color(0xFF111A30),
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                color: borderColor,
                width: selected ? 1.8 : 1.1,
              ),
              boxShadow: [
                if (selected || !unlocked)
                  BoxShadow(
                    color: glowColor,
                    blurRadius: 22,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      14,
                      12,
                      12,
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? ball.color.withValues(
                                  alpha: 0.12,
                                )
                                    : const Color(
                                  0xFF1A2641,
                                ),
                                borderRadius:
                                BorderRadius.circular(20),
                                border: !unlocked
                                    ? Border.all(
                                  color:
                                  ball.color.withValues(
                                    alpha:
                                    0.20 +
                                        pulse *
                                            0.20,
                                  ),
                                )
                                    : null,
                              ),
                              child: Text(
                                selected
                                    ? 'ACTIVE'
                                    : unlocked
                                    ? 'OWNED'
                                    : 'LOCKED',
                                style: TextStyle(
                                  color: selected
                                      ? ball.color
                                      : const Color(
                                    0xFFB8C7DF,
                                  ),
                                  fontSize: 8,
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (!unlocked)
                              Transform.rotate(
                                angle: math.sin(
                                  _shakeController.value *
                                      math.pi *
                                      6,
                                ) *
                                    0.10,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(
                                      0xFF1A2641,
                                    ),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFFFC64A,
                                      ).withValues(
                                        alpha:
                                        0.18 +
                                            pulse *
                                                0.30,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFFC64A,
                                        ).withValues(
                                          alpha:
                                          0.05 +
                                              pulse *
                                                  0.08,
                                        ),
                                        blurRadius: 12,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lock_rounded,
                                    color: Color(
                                      0xFFD2DCF0,
                                    ),
                                    size: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(
                                milliseconds: 350,
                              ),
                              curve: Curves.easeOutBack,
                              scale: selected ? 1.05 : 1,
                              child: Opacity(
                                opacity: unlocked
                                    ? 1
                                    : 0.55 +
                                    pulse *
                                        0.10,
                                child: _BallPreview(
                                  ball: ball,
                                  size: 76,
                                  showGlow:
                                  unlocked || selected,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Text(
                          ball.name.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (!unlocked)
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.monetization_on_rounded,
                                size: 14,
                                color: Color(
                                  0xFFFFC64A,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${ball.price}',
                                style: const TextStyle(
                                  color: Color(
                                    0xFFFFD166,
                                  ),
                                  fontSize: 11,
                                  fontWeight:
                                  FontWeight.w900,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            selected
                                ? 'Equipped for next run'
                                : 'Ready to equip',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(
                                0xFF7489AA,
                              ),
                              fontSize: 9,
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                            selected ? null : _handleTap,
                            style: FilledButton.styleFrom(
                              visualDensity:
                              VisualDensity.compact,
                              backgroundColor: unlocked
                                  ? ball.color
                                  : const Color(
                                0xFF263651,
                              ),
                              foregroundColor: unlocked
                                  ? const Color(
                                0xFF07111E,
                              )
                                  : const Color(
                                0xFFD7E0EF,
                              ),
                              side: !unlocked
                                  ? BorderSide(
                                color: const Color(
                                  0xFFFFC64A,
                                ).withValues(
                                  alpha:
                                  0.15 +
                                      pulse *
                                          0.18,
                                ),
                              )
                                  : BorderSide.none,
                            ),
                            child: Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                if (!unlocked) ...[
                                  const Icon(
                                    Icons.lock_open_rounded,
                                    size: 13,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Text(
                                  selected
                                      ? 'SELECTED'
                                      : unlocked
                                      ? 'SELECT'
                                      : 'UNLOCK',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                    FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!unlocked)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _BallLockedShimmer(
                          progress:
                          _shimmerController.value,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BallLockedShimmer extends StatelessWidget {
  const _BallLockedShimmer({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel =
              constraints.maxWidth + 130;

          return Stack(
            children: [
              Positioned(
                left: -65 + travel * progress,
                top: -50,
                bottom: -50,
                child: Transform.rotate(
                  angle: -0.28,
                  child: Container(
                    width: 42,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(
                            alpha: 0,
                          ),
                          Colors.white.withValues(
                            alpha: 0.03,
                          ),
                          Colors.white.withValues(
                            alpha: 0.13,
                          ),
                          Colors.white.withValues(
                            alpha: 0.03,
                          ),
                          Colors.white.withValues(
                            alpha: 0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BallAnimatedBanner extends StatelessWidget {
  const _BallAnimatedBanner({
    required this.message,
    required this.color,
    required this.icon,
  });

  final String? message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final visible = message != null;

    return AnimatedSlide(
      duration: const Duration(
        milliseconds: 260,
      ),
      curve: Curves.easeOutCubic,
      offset: visible
          ? Offset.zero
          : const Offset(
        0,
        1.5,
      ),
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds: 220,
        ),
        opacity: visible ? 1 : 0,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: const Color(
              0xFF111A30,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(
                alpha: 0.45,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(
                  alpha: 0.14,
                ),
                blurRadius: 18,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: 0.28,
                ),
                blurRadius: 20,
                offset: const Offset(
                  0,
                  8,
                ),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(
                    alpha: 0.13,
                  ),
                  border: Border.all(
                    color: color.withValues(
                      alpha: 0.35,
                    ),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  message ?? '',
                  style: const TextStyle(
                    color: Color(
                      0xFFEAF2FF,
                    ),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BallPreview extends StatelessWidget {
  const _BallPreview({
    required this.ball,
    required this.size,
    required this.showGlow,
  });

  final BallStyle ball;
  final double size;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: CustomPaint(
        painter: _BallPreviewPainter(
          ball: ball,
          showGlow: showGlow,
        ),
      ),
    );
  }
}

class _BallPreviewPainter extends CustomPainter {
  const _BallPreviewPainter({
    required this.ball,
    required this.showGlow,
  });

  final BallStyle ball;
  final bool showGlow;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        size.shortestSide * 0.24;

    final paint = Paint();

    if (showGlow) {
      paint
        ..color = ball.color.withValues(
          alpha: 0.22,
        )
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          radius * 0.7,
        );

      canvas.drawCircle(
        center,
        radius * 1.35,
        paint,
      );

      paint.maskFilter = null;
    }

    switch (ball.id) {
      case 'inferno':
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint.color =
        const Color(0xFFFFBE45);

        canvas.drawCircle(
          center.translate(
            0,
            radius * 0.12,
          ),
          radius * 0.53,
          paint,
        );

        paint.color =
        const Color(0xFFFFF0A0);

        canvas.drawCircle(
          center.translate(
            -radius * 0.18,
            -radius * 0.17,
          ),
          radius * 0.22,
          paint,
        );

        break;

      case 'volt':
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.15
          ..color = Colors.white;

        final bolt = Path()
          ..moveTo(
            center.dx - radius * 0.2,
            center.dy - radius * 0.65,
          )
          ..lineTo(
            center.dx + radius * 0.1,
            center.dy - radius * 0.1,
          )
          ..lineTo(
            center.dx - radius * 0.05,
            center.dy - radius * 0.1,
          )
          ..lineTo(
            center.dx + radius * 0.25,
            center.dy + radius * 0.65,
          );

        canvas.drawPath(
          bolt,
          paint,
        );

        break;

      case 'crystal':
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        final path = Path();

        for (var i = 0; i < 6; i++) {
          final angle =
              -math.pi / 2 +
                  i * math.pi / 3;

          final point = center +
              Offset(
                math.cos(angle),
                math.sin(angle),
              ) *
                  radius;

          if (i == 0) {
            path.moveTo(
              point.dx,
              point.dy,
            );
          } else {
            path.lineTo(
              point.dx,
              point.dy,
            );
          }
        }

        path.close();

        canvas.drawPath(
          path,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.09
          ..color =
          Colors.white.withValues(
            alpha: 0.6,
          );

        canvas.drawLine(
          center.translate(
            0,
            -radius * 0.7,
          ),
          center.translate(
            -radius * 0.35,
            radius * 0.3,
          ),
          paint,
        );

        canvas.drawLine(
          center.translate(
            0,
            -radius * 0.7,
          ),
          center.translate(
            radius * 0.4,
            radius * 0.25,
          ),
          paint,
        );

        break;

      case 'galaxy':
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFF35104E,
          );

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.14
          ..color = ball.color;

        canvas.drawArc(
          Rect.fromCircle(
            center: center,
            radius: radius * 0.68,
          ),
          -0.5,
          4.7,
          false,
          paint,
        );

        paint
          ..style = PaintingStyle.fill
          ..color = Colors.white;

        canvas.drawCircle(
          center.translate(
            radius * 0.35,
            -radius * 0.35,
          ),
          radius * 0.1,
          paint,
        );

        break;

      case 'shadow':
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFF202638,
          );

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.12
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius * 0.88,
          paint,
        );

        paint
          ..style = PaintingStyle.fill
          ..color =
          Colors.white.withValues(
            alpha: 0.75,
          );

        canvas.drawCircle(
          center.translate(
            -radius * 0.26,
            -radius * 0.26,
          ),
          radius * 0.13,
          paint,
        );

        break;

      case 'neon':
        paint
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFF06281A,
          );

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.16
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius * 0.78,
          paint,
        );

        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius * 0.25,
          paint,
        );

        break;

      case 'ice':
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.08
          ..color =
          Colors.white.withValues(
            alpha: 0.88,
          );

        for (var i = 0; i < 3; i++) {
          final angle =
              i * math.pi / 3;

          final direction = Offset(
            math.cos(angle),
            math.sin(angle),
          );

          canvas.drawLine(
            center -
                direction *
                    radius *
                    0.65,
            center +
                direction *
                    radius *
                    0.65,
            paint,
          );
        }

        break;

      case 'gold':
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.13
          ..color = const Color(
            0xFFFFF0A3,
          );

        canvas.drawCircle(
          center,
          radius * 0.76,
          paint,
        );

        paint
          ..style = PaintingStyle.fill
          ..color = const Color(
            0xFFFFF8CE,
          );

        canvas.drawCircle(
          center.translate(
            -radius * 0.27,
            -radius * 0.27,
          ),
          radius * 0.18,
          paint,
        );

        break;

      case 'plasma':
      default:
        paint
          ..style = PaintingStyle.fill
          ..color = ball.color;

        canvas.drawCircle(
          center,
          radius,
          paint,
        );

        paint.color = Colors.white;

        canvas.drawCircle(
          center,
          radius * 0.30,
          paint,
        );

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.08
          ..color =
          Colors.white.withValues(
            alpha: 0.55,
          );

        canvas.drawCircle(
          center,
          radius * 0.55,
          paint,
        );

        break;
    }
  }

  @override
  bool shouldRepaint(
      covariant _BallPreviewPainter oldDelegate,
      ) {
    return oldDelegate.ball.id != ball.id ||
        oldDelegate.showGlow != showGlow;
  }
}
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'SETTINGS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SettingTile(
                icon: Icons.volume_up_rounded,
                color: const Color(0xFF53EAFF),
                title: 'Sound effects',
                subtitle:
                'Dash, coins, collisions and game feedback',
                value: storage.soundOn,
                onChanged: storage.setSound,
              ),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.music_note_rounded,
                color: const Color(0xFF9A7BFF),
                title: 'Music',
                subtitle:
                'Background soundtrack during your runs',
                value: storage.musicOn,
                onChanged: storage.setMusic,
              ),
              const SizedBox(height: 10),
              _SettingTile(
                icon: Icons.vibration_rounded,
                color: const Color(0xFFFFC64A),
                title: 'Vibration',
                subtitle:
                'Haptic feedback for important actions',
                value: storage.vibrationOn,
                onChanged: storage.setVibration,
              ),
              const SizedBox(height: 18),
              const Text(
                'Your settings are saved automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF7184A6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF111A30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF283A59),
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.11),
          ),
          child: Icon(
            icon,
            color: color,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF7F92B2),
            fontSize: 11,
          ),
        ),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.storage,
    required this.ads,
    required this.ballStyleId,
    required this.ballColor,
    required this.mapStyle,
  });

  final StorageService storage;
  final AdService ads;
  final String ballStyleId;
  final Color ballColor;
  final MapStyle mapStyle;

  @override
  State<GameScreen> createState() =>
      _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver {
  late final VexoraRushGame _game;
  late final AudioService _audio;

  bool _deathRecorded = false;
  bool _revived = false;
  bool _loadingRevive = false;
  bool _impactPlayed = false;

  int _lastSoundCoinCount = 0;

  double _recordedDistance = 0;
  int _recordedCoins = 0;
  int _recordedDodges = 0;

  @override
  void initState() {
    super.initState();

    _audio = AudioService(widget.storage);

    _game = VexoraRushGame(
      ballStyleId: widget.ballStyleId,
      ballColor: widget.ballColor,
      mapStyle: widget.mapStyle,
    )
      ..bestDistance = widget.storage.bestDistance
      ..wallet = widget.storage.coins;

    _game.changes.addListener(
      _handleGameChange,
    );

    WidgetsBinding.instance.addObserver(this);

    unawaited(
      _audio.startMusic(),
    );
  }

  void _handleGameChange() {
    if (_game.runCoins >
        _lastSoundCoinCount) {
      _lastSoundCoinCount =
          _game.runCoins;

      _audio.coin();
    }

    if (_game.state ==
        RunState.impact &&
        !_impactPlayed) {
      _impactPlayed = true;

      _audio.hit();
      _audio.pauseMusic();
    }

    _recordDeath();
  }

  void _recordDeath() {
    if (_game.state !=
        RunState.gameOver ||
        _deathRecorded) {
      return;
    }

    _deathRecorded = true;

    final newCoins =
        _game.runCoins -
            _recordedCoins;

    final newDodges =
        _game.dodgedObstacles -
            _recordedDodges;

    final newDistance =
        _game.distance -
            _recordedDistance;

    _recordedCoins =
        _game.runCoins;

    _recordedDodges =
        _game.dodgedObstacles;

    _recordedDistance =
        _game.distance;

    unawaited(
      widget.storage.recordRun(
        _game.distance,
        newCoins,
        newDodges,
        distanceGain: newDistance,
      ),
    );
  }

  Future<void> _revive() async {
    if (_revived ||
        _loadingRevive ||
        _game.state != RunState.gameOver) {
      return;
    }

    setState(
          () => _loadingRevive = true,
    );

    final earned =
    await widget.ads.showReviveRewarded();

    if (!mounted) {
      return;
    }

    setState(
          () => _loadingRevive = false,
    );

    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Ad unavailable or not completed.',
          ),
        ),
      );

      return;
    }

    final distance = _game.distance;
    final runCoins = _game.runCoins;
    final dodges = _game.dodgedObstacles;
    final score = _game.score;
    final bestCombo = _game.bestCombo;
    final nearMisses = _game.nearMisses;

    _revived = true;
    _deathRecorded = false;
    _impactPlayed = false;
    _lastSoundCoinCount = runCoins;

    _game.restart();

    _game.distance = distance;
    _game.runCoins = runCoins;
    _game.dodgedObstacles = dodges;
    _game.score = score;
    _game.bestCombo = bestCombo;
    _game.nearMisses = nearMisses;

    // A crash breaks the live combo, but keeps the run score/history.
    _game.combo = 0;

    _audio.resumeMusic();
  }

  void _restart() {
    _deathRecorded = false;
    _revived = false;
    _loadingRevive = false;
    _impactPlayed = false;

    _lastSoundCoinCount = 0;

    _recordedDistance = 0;
    _recordedCoins = 0;
    _recordedDodges = 0;

    _game.restart();

    _audio.resumeMusic();
  }

  void _pauseGame() {
    _game.pause();
    _audio.pauseMusic();
  }

  void _resumeGame() {
    _game.resume();
    _audio.resumeMusic();
  }

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (state !=
        AppLifecycleState.resumed) {
      _pauseGame();
    }
  }

  @override
  void dispose() {
    _game.changes.removeListener(
      _handleGameChange,
    );

    WidgetsBinding.instance
        .removeObserver(this);

    unawaited(
      _audio.dispose(),
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (
          didPop,
          result,
          ) {
        if (!didPop) {
          _pauseGame();
        }
      },
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              behavior:
              HitTestBehavior.opaque,
              onTapDown: (_) {
                if (_game.state ==
                    RunState.playing) {
                  _game.dash();
                  _audio.dash();
                }
              },
              child: GameWidget(
                game: _game,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable:
              _game.changes,
              builder:
                  (context, value, child) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildHud(),

                    if (_game.state ==
                        RunState.paused)
                      _buildPausePanel(),

                    if (_game.state ==
                        RunState.gameOver)
                      _buildGameOverPanel(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goHome() {
    _audio.stopMusic();

    Navigator.of(context).pop();
  }
  Widget _buildHud() {
    final stageColor = _game.difficultyColor;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _hudPill(
                  icon: Icons.bolt_rounded,
                  label: _game.difficultyLabel,
                  color: stageColor,
                ),
                const SizedBox(width: 8),
                _hudPill(
                  icon: Icons.stars_rounded,
                  label: 'SCORE ${_game.score}',
                  color: const Color(0xFFFFD45A),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xCC111A30),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF33486D),
                    ),
                  ),
                  child: IconButton(
                    tooltip: 'Pause',
                    onPressed: _game.state == RunState.playing
                        ? _pauseGame
                        : null,
                    icon: const Icon(
                      Icons.pause_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _hudStatCard(
                    title: 'DISTANCE',
                    value: '${_game.distance.floor()} m',
                    icon: Icons.speed_rounded,
                    color: const Color(0xFF53EAFF),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _hudStatCard(
                    title: 'COINS',
                    value: '${_game.runCoins}',
                    icon: Icons.monetization_on_rounded,
                    color: const Color(0xFFFFC64A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _hudStatCard(
                    title: 'COMBO',
                    value:
                    '${_game.combo} • x${_game.comboMultiplier}',
                    icon: Icons.local_fire_department_rounded,
                    color: _game.combo >= 10
                        ? const Color(0xFFFF5A6D)
                        : const Color(0xFFB46CFF),
                  ),
                ),
              ],
            ),


            //GAME OKK

            if (_game.shieldActive ||
                _game.magnetActive ||
                _game.slowMotionActive ||
                _game.rushZoneActive) ...[


              const SizedBox(height: 9),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [

                  if (_game.rushZoneActive)
                    _powerUpStatus(
                      icon: Icons.flash_on_rounded,
                      label:
                      'RUSH ${_game.rushZoneTime.ceil()}s • x2',
                      color: const Color(0xFFFFA640),
                    ),
                  if (_game.shieldActive)
                    _powerUpStatus(
                      icon: Icons.shield_rounded,
                      label:
                      'SHIELD ${_game.shieldTime.ceil()}s',
                      color: const Color(0xFF53EAFF),
                    ),

                  if (_game.magnetActive)
                    _powerUpStatus(
                      icon: Icons.all_inclusive_rounded,
                      label:
                      'MAGNET ${_game.magnetTime.ceil()}s',
                      color: const Color(0xFF65F2B5),
                    ),

                  if (_game.slowMotionActive)
                    _powerUpStatus(
                      icon: Icons.timer_rounded,
                      label:
                      'SLOW ${_game.slowMotionTime.ceil()}s',
                      color: const Color(0xFFB76CFF),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hudPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xD9111A30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hudStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xD9111A30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Color(0xFF8198BD),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _powerUpStatus({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xE6111A30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPausePanel() {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(
          dismissible: false,
          color: Color(
            0xD6070B18,
          ),
        ),
        Center(
          child: Container(
            margin:
            const EdgeInsets.all(24),
            constraints:
            const BoxConstraints(
              maxWidth: 340,
            ),
            padding:
            const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: const Color(
                0xFF121B34,
              ),
              borderRadius:
              BorderRadius.circular(
                25,
              ),
              border: Border.all(
                color:
                widget.mapStyle.edge
                    .withValues(
                  alpha: 0.35,
                ),
              ),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                    widget.mapStyle.edge
                        .withValues(
                      alpha: 0.11,
                    ),
                  ),
                  child: Icon(
                    Icons.pause_rounded,
                    color:
                    widget.mapStyle.edge,
                    size: 35,
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'PAUSED',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  '${_game.distance.floor()} m • ${_game.runCoins} coins',
                  style: const TextStyle(
                    color: Color(
                      0xFF91A5C6,
                    ),
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  _game.difficultyLabel,
                  style: TextStyle(
                    color:
                    _difficultyColor(
                      _game.difficultyTier,
                    ),
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed:
                    _resumeGame,
                    icon: const Icon(
                      Icons
                          .play_arrow_rounded,
                    ),
                    label: const Text(
                      'CONTINUE',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                TextButton(
                  onPressed: _goHome,
                  child: const Text(
                    'EXIT TO HOME',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOverPanel() {
    final previousBest = widget.storage.bestDistance;
    final newBest = _game.distance > previousBest;

    final bestDistance = math.max(
      _game.bestDistance,
      _game.distance,
    ).floor();

    return Stack(
      fit: StackFit.expand,
      children: [
        const ModalBarrier(
          dismissible: false,
          color: Color(0xEA050817),
        ),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(18),
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 360,
              ),
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                16,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF17213D),
                    Color(0xFF0D152A),
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: newBest
                      ? const Color(0xFFFFC64A)
                      : widget.mapStyle.edge.withValues(
                    alpha: 0.45,
                  ),
                  width: newBest ? 1.8 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (newBest
                        ? const Color(0xFFFFC64A)
                        : widget.ballColor)
                        .withValues(
                      alpha: 0.14,
                    ),
                    blurRadius: 35,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          widget.ballColor.withValues(
                            alpha: 0.35,
                          ),
                          widget.ballColor.withValues(
                            alpha: 0.07,
                          ),
                        ],
                      ),
                      border: Border.all(
                        color: widget.ballColor.withValues(
                          alpha: 0.55,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.ballColor.withValues(
                            alpha: 0.20,
                          ),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bolt_rounded,
                      color: widget.ballColor,
                      size: 39,
                    ),
                  ),
                  const SizedBox(height: 13),
                  if (newBest) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC64A).withValues(
                          alpha: 0.13,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: const Color(0xFFFFC64A).withValues(
                            alpha: 0.40,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_rounded,
                            size: 14,
                            color: Color(0xFFFFD166),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'NEW BEST RUN',
                            style: TextStyle(
                              color: Color(0xFFFFD166),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                  ],
                  const Text(
                    'RUN OVER',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'STAGE ${_game.difficultyTier} • ${_game.difficultyLabel}',
                    style: TextStyle(
                      color: _game.difficultyColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 17),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A1327),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFFFD45A).withValues(
                          alpha: 0.30,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'FINAL SCORE',
                          style: TextStyle(
                            color: Color(0xFF8EA2C4),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_game.score}',
                          style: const TextStyle(
                            color: Color(0xFFFFD45A),
                            fontSize: 33,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.speed_rounded,
                          label: 'DISTANCE',
                          value: '${_game.distance.floor()} m',
                          color: const Color(0xFF53EAFF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.monetization_on_rounded,
                          label: 'COINS',
                          value: '${_game.runCoins}',
                          color: const Color(0xFFFFC64A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.shield_outlined,
                          label: 'DODGES',
                          value: '${_game.dodgedObstacles}',
                          color: const Color(0xFF65E3A7),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.local_fire_department_rounded,
                          label: 'BEST COMBO',
                          value: '${_game.bestCombo}',
                          color: const Color(0xFFFF6C91),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.flash_on_rounded,
                          label: 'NEAR MISS',
                          value: '${_game.nearMisses}',
                          color: const Color(0xFFB76CFF),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _RunStatCard(
                          icon: Icons.emoji_events_outlined,
                          label: 'BEST DISTANCE',
                          value: '$bestDistance m',
                          color: const Color(0xFFFF8F6B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (!_revived) ...[
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1628),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF65E3A7).withValues(
                            alpha: 0.24,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: Color(0xFF65E3A7),
                            size: 25,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Revive once and continue your current distance, score and rewards.',
                              style: TextStyle(
                                color: Color(0xFFA8B8D3),
                                fontSize: 11,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _loadingRevive ? null : _revive,
                        icon: _loadingRevive
                            ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons.play_arrow_rounded,
                        ),
                        label: Text(
                          _loadingRevive
                              ? 'LOADING AD...'
                              : 'REVIVE • WATCH AD',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF65E3A7),
                          foregroundColor: const Color(0xFF06140D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: _restart,
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text(
                        'TRY AGAIN',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.7,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: widget.ballColor,
                        foregroundColor: const Color(0xFF06111C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: _goHome,
                    icon: const Icon(
                      Icons.home_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'BACK TO HOME',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _difficultyColor(
      int tier,
      ) {
    switch (tier) {
      case 1:
        return const Color(
          0xFF65E3A7,
        );

      case 2:
        return const Color(
          0xFF53EAFF,
        );

      case 3:
        return const Color(
          0xFFFFC64A,
        );

      case 4:
        return const Color(
          0xFFFF8B5D,
        );

      default:
        return const Color(
          0xFFFF5F84,
        );
    }
  }
}

class _RunStatCard extends StatelessWidget {
  const _RunStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        vertical: 12,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(
          0xFF0D162A,
        ),
        borderRadius:
        BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
          color.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 19,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            value,
            maxLines: 1,
            style:
            const TextStyle(
              fontSize: 15,
              fontWeight:
              FontWeight.w900,
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          Text(
            label,
            style:
            const TextStyle(
              color: Color(
                0xFF798CAC,
              ),
              fontSize: 8,
              fontWeight:
              FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
