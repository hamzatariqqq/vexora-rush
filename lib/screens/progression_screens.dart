import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/map_style.dart';
import '../services/storage_service.dart';

class MapsScreen extends StatefulWidget {
  const MapsScreen({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen> {
  String? _bannerMessage;
  Color _bannerColor = const Color(0xFF53EAFF);
  IconData _bannerIcon = Icons.info_outline_rounded;
  Timer? _bannerTimer;

  void _showBanner(
      String message, {
        Color color = const Color(0xFF53EAFF),
        IconData icon = Icons.info_outline_rounded,
      }) {
    _bannerTimer?.cancel();

    setState(() {
      _bannerMessage = message;
      _bannerColor = color;
      _bannerIcon = icon;
    });

    _bannerTimer = Timer(
      const Duration(milliseconds: 1800),
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
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'MAPS',
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
                  _Balance(coins: widget.storage.coins),
                  const SizedBox(height: 18),
                  const Text(
                    'CHOOSE YOUR WORLD',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Each unlocked map has its own visual atmosphere.',
                    style: TextStyle(
                      color: Color(0xFF91A6C9),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),
                  for (final map in mapStyles)
                    _MapCard(
                      map: map,
                      storage: widget.storage,
                      onBanner: _showBanner,
                    ),
                ],
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 16,
                child: IgnorePointer(
                  ignoring: _bannerMessage == null,
                  child: _AnimatedHintBanner(
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

class _MapCard extends StatefulWidget {
  const _MapCard({
    required this.map,
    required this.storage,
    required this.onBanner,
  });

  final MapStyle map;
  final StorageService storage;
  final void Function(
      String message, {
      Color color,
      IconData icon,
      }) onBanner;

  @override
  State<_MapCard> createState() => _MapCardState();
}

class _MapCardState extends State<_MapCard>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _shakeController;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _playLockedFeedback(int neededCoins) {
    _shakeController.forward(from: 0);

    widget.onBanner(
      'You need $neededCoins more coins.',
      color: const Color(0xFFFFC64A),
      icon: Icons.lock_rounded,
    );
  }

  Future<void> _handleAction(
      BuildContext context,
      bool selected,
      bool unlocked,
      ) async {
    final storage = widget.storage;
    final map = widget.map;

    if (selected) {
      return;
    }

    if (unlocked) {
      await storage.selectMap(map.id);

      if (!context.mounted) {
        return;
      }

      widget.onBanner(
        '${map.name} selected.',
        color: map.edge,
        icon: Icons.check_circle_rounded,
      );
      return;
    }

    final success = await storage.unlockMap(
      map.id,
      map.price,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      await storage.selectMap(map.id);

      if (!context.mounted) {
        return;
      }

      widget.onBanner(
        '${map.name} unlocked!',
        color: const Color(0xFF65E3A7),
        icon: Icons.auto_awesome_rounded,
      );
      return;
    }

    final needed = map.price - storage.coins;
    _playLockedFeedback(needed);
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.map;
    final storage = widget.storage;

    final selected = storage.selectedMap == map.id;
    final unlocked = storage.unlockedMaps.contains(map.id);

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pulseController,
        _shimmerController,
        _shakeController,
      ]),
      builder: (context, child) {
        final pulse = 0.55 + (_pulseController.value * 0.45);
        final shake =
            math.sin(_shakeController.value * math.pi * 7) *
                (1 - _shakeController.value) *
                11;

        final lockedBorder = map.edge.withValues(
          alpha: 0.22 + pulse * 0.22,
        );

        final lockedGlow = map.edge.withValues(
          alpha: 0.05 + pulse * 0.08,
        );

        final selectedGlow = map.edge.withValues(
          alpha: 0.15 + pulse * 0.06,
        );

        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF121B34),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected
                    ? map.edge
                    : unlocked
                    ? const Color(0xFF273755)
                    : lockedBorder,
                width: selected ? 1.8 : 1.2,
              ),
              boxShadow: [
                if (selected)
                  BoxShadow(
                    color: selectedGlow,
                    blurRadius: 24,
                    spreadRadius: 1,
                  ),
                if (!selected && !unlocked)
                  BoxShadow(
                    color: lockedGlow,
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(21),
                  ),
                  child: SizedBox(
                    height: 125,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _MapPreviewPainter(map),
                        ),
                        if (!unlocked)
                          Container(
                            color: const Color(0xAA07101E),
                          ),
                        Positioned(
                          left: 14,
                          top: 14,
                          child: Container(
                            padding:
                            const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xCC080D20),
                              borderRadius:
                              BorderRadius.circular(20),
                              border: Border.all(
                                color: map.edge.withValues(
                                  alpha: !unlocked
                                      ? 0.36 + pulse * 0.28
                                      : 0.50,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _mapIcon(map.id),
                                  size: 15,
                                  color: map.edge,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  selected
                                      ? 'ACTIVE'
                                      : unlocked
                                      ? 'UNLOCKED'
                                      : 'LOCKED',
                                  style: TextStyle(
                                    color: selected
                                        ? map.edge
                                        : !unlocked
                                        ? const Color(
                                      0xFFFFD166,
                                    )
                                        : const Color(
                                      0xFFD5DEF0,
                                    ),
                                    fontSize: 10,
                                    fontWeight:
                                    FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!unlocked)
                          Positioned(
                            right: 14,
                            top: 14,
                            child: Transform.rotate(
                              angle:
                              math.sin(
                                _shakeController.value *
                                    math.pi *
                                    6,
                              ) *
                                  0.08,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xCC080D20,
                                  ),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFFC64A,
                                    ).withValues(
                                      alpha: 0.28 +
                                          pulse * 0.30,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFFC64A,
                                      ).withValues(
                                        alpha: 0.08 +
                                            pulse * 0.08,
                                      ),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        if (!unlocked)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: _LockedShimmer(
                                progress:
                                _shimmerController.value,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              map.name,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight:
                                FontWeight.w900,
                              ),
                            ),
                          ),
                          if (!unlocked)
                            _PriceChip(price: map.price),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _mapDescription(map.id),
                        style: const TextStyle(
                          color: Color(0xFF9EB0CF),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => _handleAction(
                            context,
                            selected,
                            unlocked,
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: selected
                                ? const Color(0xFF1C2A45)
                                : unlocked
                                ? map.edge
                                : const Color(0xFF192744),
                            foregroundColor: selected
                                ? const Color(0xFFBFD0EA)
                                : unlocked
                                ? const Color(
                              0xFF07111E,
                            )
                                : const Color(
                              0xFFFFE7A9,
                            ),
                            padding:
                            const EdgeInsets.symmetric(
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(14),
                            ),
                            side: !unlocked && !selected
                                ? BorderSide(
                              color: const Color(
                                0xFFFFC64A,
                              ).withValues(
                                alpha:
                                0.22 + pulse * 0.20,
                              ),
                            )
                                : BorderSide.none,
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              if (!selected && !unlocked) ...[
                                const Icon(
                                  Icons.lock_open_rounded,
                                  size: 16,
                                ),
                                const SizedBox(width: 7),
                              ],
                              Text(
                                selected
                                    ? 'CURRENT MAP'
                                    : unlocked
                                    ? 'SELECT MAP'
                                    : 'UNLOCK • ${map.price} COINS',
                                style: const TextStyle(
                                  fontWeight:
                                  FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LockedShimmer extends StatelessWidget {
  const _LockedShimmer({
    required this.progress,
  });

  final double progress;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final travel = screenWidth * 0.9;

    return Stack(
      children: [
        Positioned(
          left: -travel + travel * 2 * progress,
          top: -20,
          bottom: -20,
          child: Transform.rotate(
            angle: -0.28,
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0.15),
                    Colors.white.withValues(alpha: 0.06),
                    Colors.white.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AnimatedHintBanner extends StatelessWidget {
  const _AnimatedHintBanner({
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
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      offset: visible ? Offset.zero : const Offset(0, 1.4),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: visible ? 1 : 0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF1F7),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message ?? '',
                    style: const TextStyle(
                      color: Color(0xFF243247),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MissionsScreen extends StatefulWidget {
  const MissionsScreen({
    super.key,
    required this.storage,
  });

  final StorageService storage;

  @override
  State<MissionsScreen> createState() =>
      _MissionsScreenState();
}

class _MissionsScreenState
    extends State<MissionsScreen> {
  static const _names = [
    'Distance Runner',
    'Hazard Hunter',
    'Coin Collector',
  ];

  static const _descriptions = [
    'Travel 2,500 metres today.',
    'Successfully dodge 40 obstacles.',
    'Collect 20 coins during your runs.',
  ];

  static const _icons = [
    Icons.speed_rounded,
    Icons.bolt_rounded,
    Icons.monetization_on_rounded,
  ];

  static const _colors = [
    Color(0xFF53EAFF),
    Color(0xFFFF6C91),
    Color(0xFFFFC64A),
  ];

  @override
  void initState() {
    super.initState();
    widget.storage.refreshDailyMissions();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, child) {
        final claimed =
            widget.storage.claimedMissions.length;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'DAILY MISSIONS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1.4,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              8,
              16,
              30,
            ),
            children: [
              _Balance(
                coins: widget.storage.coins,
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF182846),
                      Color(0xFF101A32),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2B4268),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF20365A),
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Color(0xFF53EAFF),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TODAY\'S CHALLENGE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w900,
                              letterSpacing: 1.4,
                              color: Color(0xFF91A6C9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$claimed / 3 rewards claimed',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Resets at your device\'s local midnight.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF8194B5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              for (var i = 0; i < _names.length; i++)
                _missionCard(context, i),
            ],
          ),
        );
      },
    );
  }

  Widget _missionCard(
      BuildContext context,
      int index,
      ) {
    final storage = widget.storage;

    final goal = StorageService.missionGoals[index];
    final progress = storage.missionProgress(index);
    final claimed =
    storage.claimedMissions.contains(index);
    final complete = progress >= goal;

    final displayProgress =
    progress > goal ? goal : progress;

    final ratio = (progress / goal)
        .clamp(0.0, 1.0)
        .toDouble();

    final color = _colors[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF121B34),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: complete && !claimed
              ? color.withValues(alpha: 0.75)
              : const Color(0xFF273755),
          width: complete && !claimed ? 1.5 : 1,
        ),
        boxShadow: [
          if (complete && !claimed)
            BoxShadow(
              color: color.withValues(alpha: 0.11),
              blurRadius: 18,
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.45),
                  ),
                ),
                child: Icon(
                  _icons[index],
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      _names[index],
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _descriptions[index],
                      style: const TextStyle(
                        color: Color(0xFF94A6C5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF202D4A),
                  borderRadius:
                  BorderRadius.circular(30),
                ),
                child: Text(
                  '+${StorageService.missionRewards[index]} 🪙',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 9,
              backgroundColor:
              const Color(0xFF26334E),
              valueColor:
              AlwaysStoppedAnimation<Color>(
                color,
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '$displayProgress / $goal',
                style: const TextStyle(
                  color: Color(0xFFB5C4DF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (claimed)
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: Color(0xFF65E3A7),
                    ),
                    SizedBox(width: 5),
                    Text(
                      'CLAIMED',
                      style: TextStyle(
                        color: Color(0xFF65E3A7),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                )
              else if (complete)
                FilledButton(
                  onPressed: () async {
                    final success =
                    await storage.claimMission(index);

                    if (!context.mounted || !success) {
                      return;
                    }

                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(
                        content: Text(
                          '+${StorageService.missionRewards[index]} coins claimed!',
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor:
                    const Color(0xFF07111E),
                    visualDensity:
                    VisualDensity.compact,
                  ),
                  child: const Text(
                    'CLAIM',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                )
              else
                Text(
                  '${(ratio * 100).floor()}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Balance extends StatelessWidget {
  const _Balance({
    required this.coins,
  });

  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A2847),
            Color(0xFF131E38),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2C4267),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFC64A),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(0xFF6E4A00),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'YOUR BALANCE',
              style: TextStyle(
                color: Color(0xFF91A6C9),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFD166),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'COINS',
            style: TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  const _PriceChip({
    required this.price,
  });

  final int price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC64A).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFC64A).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Text(
        '🪙 $price',
        style: const TextStyle(
          color: Color(0xFFFFD166),
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

IconData _mapIcon(String id) {
  switch (id) {
    case 'cyber_tunnel':
      return Icons.hub_rounded;
    case 'space_station':
      return Icons.rocket_launch_rounded;
    case 'lava_core':
      return Icons.local_fire_department_rounded;
    case 'frozen_world':
      return Icons.ac_unit_rounded;
    case 'dark_galaxy':
      return Icons.auto_awesome_rounded;
    case 'neon_city':
    default:
      return Icons.location_city_rounded;
  }
}

String _mapDescription(String id) {
  switch (id) {
    case 'cyber_tunnel':
      return 'Race through a glowing digital tunnel filled with violet energy.';
    case 'space_station':
      return 'A cold orbital track surrounded by stars and futuristic structures.';
    case 'lava_core':
      return 'Enter a dangerous molten world surrounded by burning energy.';
    case 'frozen_world':
      return 'Survive an icy course with frozen particles and crystal edges.';
    case 'dark_galaxy':
      return 'Push deep into a mysterious galaxy of stars and cosmic energy.';
    case 'neon_city':
    default:
      return 'The original Vexora track surrounded by futuristic neon towers.';
  }
}

class _MapPreviewPainter extends CustomPainter {
  const _MapPreviewPainter(this.map);

  final MapStyle map;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint = Paint();

    paint.color = map.background;
    canvas.drawRect(Offset.zero & size, paint);

    final roadWidth = size.width * 0.58;
    final roadLeft = (size.width - roadWidth) / 2;

    final roadRect = Rect.fromLTWH(
      roadLeft,
      0,
      roadWidth,
      size.height,
    );

    paint.color = map.floor;
    canvas.drawRect(roadRect, paint);

    paint
      ..color = map.edge.withValues(alpha: 0.95)
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(roadRect.left, 0),
      Offset(roadRect.left, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(roadRect.right, 0),
      Offset(roadRect.right, size.height),
      paint,
    );

    paint
      ..color = map.edge.withValues(alpha: 0.16)
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );

    for (double y = 12; y < size.height; y += 28) {
      canvas.drawLine(
        Offset(roadRect.left, y),
        Offset(roadRect.right, y),
        paint,
      );
    }

    switch (map.id) {
      case 'neon_city':
        _drawNeonCity(
          canvas,
          size,
          roadRect,
          paint,
        );
        break;
      case 'cyber_tunnel':
        _drawCyberTunnel(
          canvas,
          size,
          paint,
        );
        break;
      case 'space_station':
        _drawSpace(
          canvas,
          size,
          roadRect,
          paint,
        );
        break;
      case 'lava_core':
        _drawLava(
          canvas,
          size,
          roadRect,
          paint,
        );
        break;
      case 'frozen_world':
        _drawFrozen(
          canvas,
          size,
          roadRect,
          paint,
        );
        break;
      case 'dark_galaxy':
        _drawGalaxy(
          canvas,
          size,
          roadRect,
          paint,
        );
        break;
    }
  }

  void _drawNeonCity(
      Canvas canvas,
      Size size,
      Rect road,
      Paint paint,
      ) {
    paint.color = map.edge.withValues(alpha: 0.2);

    for (var i = 0; i < 5; i++) {
      final y = 8.0 + i * 25;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            6,
            y,
            road.left - 12,
            18,
          ),
          const Radius.circular(3),
        ),
        paint,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            road.right + 6,
            y,
            size.width - road.right - 12,
            18,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  void _drawCyberTunnel(
      Canvas canvas,
      Size size,
      Paint paint,
      ) {
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 4; i++) {
      final inset = 5.0 + i * 10;

      paint.color = map.edge.withValues(
        alpha: 0.12 + i * 0.07,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            inset,
            inset * 0.4,
            size.width - inset * 2,
            size.height - inset * 0.8,
          ),
          const Radius.circular(12),
        ),
        paint,
      );
    }

    paint.style = PaintingStyle.fill;
  }

  void _drawSpace(
      Canvas canvas,
      Size size,
      Rect road,
      Paint paint,
      ) {
    paint.color = Colors.white.withValues(alpha: 0.65);

    const stars = [
      Offset(12, 15),
      Offset(28, 45),
      Offset(8, 82),
      Offset(34, 108),
      Offset(320, 18),
      Offset(344, 47),
      Offset(326, 76),
      Offset(349, 106),
    ];

    for (final star in stars) {
      if (star.dx <= size.width) {
        canvas.drawCircle(star, 1.5, paint);
      }
    }

    paint.color = map.edge.withValues(alpha: 0.2);

    canvas.drawCircle(
      Offset(road.left / 2, size.height * 0.6),
      16,
      paint,
    );
  }

  void _drawLava(
      Canvas canvas,
      Size size,
      Rect road,
      Paint paint,
      ) {
    paint
      ..color = map.edge.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final left = Path()
      ..moveTo(8, 0)
      ..lineTo(18, 22)
      ..lineTo(9, 45)
      ..lineTo(22, 70)
      ..lineTo(12, 96)
      ..lineTo(20, size.height);

    canvas.drawPath(left, paint);

    final right = Path()
      ..moveTo(size.width - 8, 0)
      ..lineTo(size.width - 20, 24)
      ..lineTo(size.width - 10, 50)
      ..lineTo(size.width - 24, 80)
      ..lineTo(size.width - 12, size.height);

    canvas.drawPath(right, paint);
    paint.style = PaintingStyle.fill;
  }

  void _drawFrozen(
      Canvas canvas,
      Size size,
      Rect road,
      Paint paint,
      ) {
    paint
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.2;

    const flakes = [
      Offset(15, 20),
      Offset(31, 58),
      Offset(12, 96),
      Offset(342, 25),
      Offset(328, 64),
      Offset(347, 104),
    ];

    for (final flake in flakes) {
      if (flake.dx > size.width) {
        continue;
      }

      canvas.drawLine(
        flake.translate(-4, 0),
        flake.translate(4, 0),
        paint,
      );

      canvas.drawLine(
        flake.translate(0, -4),
        flake.translate(0, 4),
        paint,
      );
    }
  }

  void _drawGalaxy(
      Canvas canvas,
      Size size,
      Rect road,
      Paint paint,
      ) {
    paint.color = map.edge.withValues(alpha: 0.16);

    canvas.drawCircle(
      Offset(18, size.height * 0.3),
      23,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width - 18, size.height * 0.75),
      28,
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.6);

    const stars = [
      Offset(9, 12),
      Offset(29, 35),
      Offset(15, 74),
      Offset(35, 112),
      Offset(330, 12),
      Offset(350, 42),
      Offset(326, 86),
      Offset(346, 115),
    ];

    for (final star in stars) {
      if (star.dx <= size.width) {
        canvas.drawCircle(star, 1.3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(
      covariant _MapPreviewPainter oldDelegate,
      ) {
    return oldDelegate.map.id != map.id;
  }
}