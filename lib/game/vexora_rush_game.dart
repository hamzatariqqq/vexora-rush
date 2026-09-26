import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../models/map_style.dart';
import 'models/track_row.dart';

enum RunState {
  playing,
  paused,
  impact,
  gameOver,
}

enum PowerUpKind {
  shield,
  magnet,
  slowMotion,
}

class _PowerUpPickup {
  _PowerUpPickup({
    required this.kind,
    required this.lane,
    required this.y,
  });

  final PowerUpKind kind;
  final int lane;

  double y;
  bool collected = false;

  double get x => lane == 0 ? 110 : 250;

  Offset get position => Offset(x, y);

  void advance(double movement) {
    y += movement;
  }
}

class _SkillCoin {
  _SkillCoin({
    required this.lane,
    required this.y,
    this.value = 1,
  });

  final int lane;
  final int value;

  double y;
  bool collected = false;

  double get x => lane == 0 ? 110 : 250;

  Offset get position => Offset(x, y);

  void advance(double movement) {
    y += movement;
  }
}

class _FxParticle {
  _FxParticle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.life,
    required this.size,
  });

  Offset position;
  Offset velocity;
  final Color color;
  final double life;
  final double size;

  double age = 0;

  bool get isDead => age >= life;

  void step(double dt) {
    age += dt;

    position =
        position +
            velocity * dt;

    final drag =
    pow(
      0.90,
      dt * 60,
    ).toDouble();

    velocity = Offset(
      velocity.dx * drag,
      velocity.dy * drag + 22 * dt,
    );
  }
}

class VexoraRushGame extends FlameGame {
  VexoraRushGame({
    this.ballStyleId = 'plasma',
    this.ballColor = const Color(0xFF53EAFF),
    this.mapStyle = const MapStyle(
      id: 'neon_city',
      name: 'Neon City',
      price: 0,
      background: Color(0xFF080D20),
      floor: Color(0xFF101832),
      edge: Color(0xFF29CBE7),
    ),
  });

  final String ballStyleId;
  final Color ballColor;
  final MapStyle mapStyle;

  static const double logicalWidth = 360;
  static const double ballRadius = 12;
  static const double dashDuration = 0.18;

  final Random _random = Random();

  final List<TrackRow> _rows = [];
  final List<_PowerUpPickup> _powerUps = [];
  final List<_SkillCoin> _skillCoins = [];

  final List<_FxParticle> _particles = [];

  double _screenShakeTime = 0;
  double _screenShakeMagnitude = 0;
  double _screenFlashTime = 0;
  Color _screenFlashColor = const Color(0xFFFFFFFF);
  double _dashFxTime = 0;
  double _comboGraceTime = 0;

  final ValueNotifier<int> changes = ValueNotifier(0);

  RunState state = RunState.playing;

  double distance = 0;
  double bestDistance = 0;

  int runCoins = 0;
  int wallet = 0;
  int dodgedObstacles = 0;

  // ============================================================
  // SCORE / COMBO
  // ============================================================

  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int nearMisses = 0;

  String? rushEvent;
  double rushEventTime = 0;

  int get comboMultiplier {
    return min(
      1 + combo ~/ 5,
      5,
    );
  }

  int get scoreMultiplier {
    return comboMultiplier *
        (rushZoneActive ? 2 : 1);
  }

  bool get showRushEvent {
    return rushEvent != null &&
        rushEventTime > 0;
  }

  // ============================================================
  // POWER UPS
  // ============================================================

  double shieldTime = 0;
  double magnetTime = 0;
  double slowMotionTime = 0;

  bool get shieldActive => shieldTime > 0;

  bool get magnetActive => magnetTime > 0;

  bool get slowMotionActive => slowMotionTime > 0;

  double _invulnerableTime = 0;
  double _nextPowerUpDistance = 420;
  double _nextSkillPatternDistance = 100;

  // ============================================================
  // RUSH ZONE
  // ============================================================

  double rushZoneTime = 0;

  bool get rushZoneActive => rushZoneTime > 0;

  // ============================================================
  // PLAYER
  // ============================================================

  double _ballX = 110;
  double _dashStartX = 110;
  double _dashTargetX = 110;
  double _dashTime = dashDuration;

  double _timeSinceDash = 999;

  int _targetLane = 0;

  // ============================================================
  // WORLD
  // ============================================================

  double _floorOffset = 0;
  double _impactTime = 0;
  double _uiTime = 0;

  double _runTime = 0;

  bool _hasDashed = false;

  int? _lastBlockedLane;
  int _sameLaneStreak = 0;

  HazardKind? _lastHazard;

  // ============================================================
  // SIZE
  // ============================================================

  double get _scale {
    return size.x > 0
        ? size.x / logicalWidth
        : 1;
  }

  double get _height {
    return size.y / _scale;
  }

  double get _ballY {
    return _height * 0.72;
  }

  // ============================================================
  // DIFFICULTY
  // ============================================================

  int get difficultyTier {
    if (distance < 600) {
      return 1;
    }

    if (distance < 1600) {
      return 2;
    }

    if (distance < 3000) {
      return 3;
    }

    if (distance < 5000) {
      return 4;
    }

    return 5;
  }

  String get difficultyLabel {
    switch (difficultyTier) {
      case 1:
        return 'WARM UP';

      case 2:
        return 'RISING';

      case 3:
        return 'FAST';

      case 4:
        return 'INTENSE';

      case 5:
        return 'MAX RUSH';

      default:
        return 'WARM UP';
    }
  }

  Color get difficultyColor {
    switch (difficultyTier) {
      case 1:
        return const Color(0xFF65F2B5);

      case 2:
        return const Color(0xFF53EAFF);

      case 3:
        return const Color(0xFFFFD85A);

      case 4:
        return const Color(0xFFFF8B4D);

      case 5:
        return const Color(0xFFFF4F78);

      default:
        return const Color(0xFF65F2B5);
    }
  }

  double get _speed {
    // The run accelerates more aggressively now, but keeps a hard cap
    // so the game remains reaction-based rather than unfair.
    return 175.0 +
        min(
          distance / 24,
          175.0,
        );
  }

  double get _effectiveSpeed {
    double speed = _speed;

    if (rushZoneActive) {
      speed *= 1.22;
    }

    if (slowMotionActive) {
      speed *= 0.66;
    }

    return speed;
  }

  double get _rowSpacing {
    final double distanceTightening = min(
      distance / 40,
      78.0,
    );

    final double baseSpacing =
        380.0 - distanceTightening;

    return max(
      baseSpacing,
      _speed * 0.90,
    ).toDouble();
  }

  double get _coinChance {
    if (rushZoneActive) {
      return 0.30;
    }

    if (distance < 800) {
      return 0.13;
    }

    if (distance < 2500) {
      return 0.16;
    }

    return 0.19;
  }

  // ============================================================
  // BASIC
  // ============================================================

  void _notify() {
    changes.value++;
  }

  @override
  Color backgroundColor() {
    return mapStyle.background;
  }


  // ============================================================
  // VISUAL FX
  // ============================================================

  void _spawnBurst(
      Offset origin,
      Color color, {
        int count = 10,
        double speed = 90,
        double life = 0.38,
        double size = 2.8,
      }) {
    for (var i = 0; i < count; i++) {
      final angle =
          _random.nextDouble() *
              pi *
              2;

      final particleSpeed =
          speed *
              (
                  0.45 +
                      _random.nextDouble() *
                          0.75
              );

      _particles.add(
        _FxParticle(
          position: origin,
          velocity: Offset(
            cos(angle) *
                particleSpeed,
            sin(angle) *
                particleSpeed,
          ),
          color: color,
          life:
          life *
              (
                  0.75 +
                      _random.nextDouble() *
                          0.45
              ),
          size:
          size *
              (
                  0.70 +
                      _random.nextDouble() *
                          0.65
              ),
        ),
      );
    }
  }

  void _triggerImpactFx({
    required Color color,
    double shake = 6,
    double flash = 0.14,
  }) {
    _screenShakeMagnitude =
        max(
          _screenShakeMagnitude,
          shake,
        ).toDouble();

    _screenShakeTime =
        max(
          _screenShakeTime,
          0.24,
        ).toDouble();

    _screenFlashColor = color;

    _screenFlashTime =
        max(
          _screenFlashTime,
          flash,
        ).toDouble();
  }

  void _updateVisualFx(
      double dt,
      ) {
    for (final particle in _particles) {
      particle.step(dt);
    }

    _particles.removeWhere(
          (particle) =>
      particle.isDead,
    );

    if (_screenShakeTime > 0) {
      _screenShakeTime =
          max(
            0.0,
            _screenShakeTime - dt,
          ).toDouble();
    }

    if (_screenFlashTime > 0) {
      _screenFlashTime =
          max(
            0.0,
            _screenFlashTime - dt,
          ).toDouble();
    }

    if (_dashFxTime > 0) {
      _dashFxTime =
          max(
            0.0,
            _dashFxTime - dt,
          ).toDouble();
    }
  }

  void _drawParticles(
      Canvas canvas,
      Paint paint,
      ) {
    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    for (final particle in _particles) {
      final progress =
      (
          1 -
              particle.age /
                  particle.life
      ).clamp(
        0.0,
        1.0,
      );

      paint.color =
          particle.color.withValues(
            alpha:
            0.92 *
                progress,
          );

      canvas.drawCircle(
        particle.position,
        particle.size *
            (
                0.55 +
                    progress *
                        0.65
            ),
        paint,
      );
    }
  }

  void _drawScreenFlash(
      Canvas canvas,
      Paint paint,
      ) {
    if (_screenFlashTime <= 0) {
      return;
    }

    final alpha =
    (
        _screenFlashTime /
            0.14
    ).clamp(
      0.0,
      1.0,
    );

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null
      ..color =
      _screenFlashColor.withValues(
        alpha:
        0.16 *
            alpha,
      );

    canvas.drawRect(
      Rect.fromLTWH(
        0,
        0,
        logicalWidth,
        _height,
      ),
      paint,
    );
  }

  Color _hazardGlowColor(
      HazardKind kind,
      ) {
    switch (kind) {
      case HazardKind.barrier:
        return const Color(
          0xFFFF4D72,
        );

      case HazardKind.laser:
        return const Color(
          0xFFFF5D86,
        );

      case HazardKind.spikes:
        return const Color(
          0xFFFF8A4B,
        );

      case HazardKind.blade:
        return const Color(
          0xFFFF6C91,
        );

      case HazardKind.movingGate:
        return const Color(
          0xFFFF5C88,
        );
    }
  }

  // ============================================================
  // CONTROL
  // ============================================================

  void dash() {
    if (state != RunState.playing) {
      return;
    }

    _hasDashed = true;
    _timeSinceDash = 0;

    _spawnBurst(
      Offset(
        _ballX,
        _ballY,
      ),
      rushZoneActive
          ? const Color(
        0xFFFFA640,
      )
          : ballColor,
      count: 5,
      speed: 48,
      life: 0.22,
      size: 2.0,
    );

    _dashFxTime = 0.20;

    _targetLane =
        1 - _targetLane;

    _dashStartX =
        _ballX;

    _dashTargetX =
    _targetLane == 0
        ? 110
        : 250;

    _dashTime = 0;
  }

  void pause() {
    if (state != RunState.playing) {
      return;
    }

    state = RunState.paused;

    _notify();
  }

  void resume() {
    if (state != RunState.paused) {
      return;
    }

    state = RunState.playing;

    _notify();
  }

  // ============================================================
  // RESTART
  // ============================================================

  void restart() {
    _rows.clear();
    _powerUps.clear();
    _skillCoins.clear();
    _particles.clear();

    distance = 0;

    runCoins = 0;
    dodgedObstacles = 0;

    score = 0;
    combo = 0;
    bestCombo = 0;
    nearMisses = 0;

    rushEvent = null;
    rushEventTime = 0;

    shieldTime = 0;
    magnetTime = 0;
    slowMotionTime = 0;

    rushZoneTime = 0;

    _invulnerableTime = 0;

    _screenShakeTime = 0;
    _screenShakeMagnitude = 0;
    _screenFlashTime = 0;
    _dashFxTime = 0;
    _comboGraceTime = 0;

    _nextPowerUpDistance =
        360 +
            _random.nextDouble() *
                150;

    _nextSkillPatternDistance = 100;

    _ballX = 110;
    _dashStartX = 110;
    _dashTargetX = 110;
    _dashTime = dashDuration;

    _timeSinceDash = 999;

    _targetLane = 0;

    _floorOffset = 0;
    _impactTime = 0;
    _uiTime = 0;

    _runTime = 0;

    _hasDashed = false;

    _lastBlockedLane = null;
    _sameLaneStreak = 0;

    _lastHazard = null;

    state = RunState.playing;

    _notify();
  }

  // ============================================================
  // COLLISION
  // ============================================================

  void _hit() {
    if (_invulnerableTime > 0) {
      return;
    }

    final player =
    Offset(
      _ballX,
      _ballY,
    );

    if (shieldActive) {
      shieldTime = 0;

      _invulnerableTime = 0.9;

      _spawnBurst(
        player,
        const Color(
          0xFF53EAFF,
        ),
        count: 20,
        speed: 145,
        life: 0.48,
        size: 3.1,
      );

      _triggerImpactFx(
        color: const Color(
          0xFF53EAFF,
        ),
        shake: 4.5,
        flash: 0.12,
      );

      rushEvent = 'SHIELD SAVE!';
      rushEventTime = 1.1;

      score += 75;

      _notify();

      return;
    }

    _spawnBurst(
      player,
      ballColor,
      count: 28,
      speed: 185,
      life: 0.58,
      size: 3.8,
    );

    _spawnBurst(
      player,
      const Color(
        0xFFFF557B,
      ),
      count: 14,
      speed: 135,
      life: 0.42,
      size: 2.6,
    );

    _triggerImpactFx(
      color: const Color(
        0xFFFF557B,
      ),
      shake: 7.5,
      flash: 0.14,
    );

    state = RunState.impact;

    _impactTime = 0;

    combo = 0;
    _comboGraceTime = 0;

    bestDistance = max(
      bestDistance,
      distance,
    );

    wallet += runCoins;

    _notify();
  }

  // ============================================================
  // FAIR LANE GENERATION
  // ============================================================

  int _chooseBlockedLane() {
    if (_lastBlockedLane == null) {
      final first =
      _random.nextInt(2);

      _lastBlockedLane = first;
      _sameLaneStreak = 1;

      return first;
    }

    int candidate;

    if (_sameLaneStreak >= 2) {
      candidate =
          1 - _lastBlockedLane!;
    } else {
      final alternate =
          _random.nextDouble() <
              0.68;

      candidate =
      alternate
          ? 1 - _lastBlockedLane!
          : _lastBlockedLane!;
    }

    if (candidate ==
        _lastBlockedLane) {
      _sameLaneStreak++;
    } else {
      _sameLaneStreak = 1;
    }

    _lastBlockedLane = candidate;

    return candidate;
  }

  // ============================================================
  // HAZARDS
  // ============================================================

  HazardKind _chooseHazard() {
    late List<HazardKind> choices;

    if (distance < 600) {
      choices = const [
        HazardKind.barrier,
      ];
    } else if (distance < 1600) {
      choices = const [
        HazardKind.barrier,
        HazardKind.laser,
        HazardKind.spikes,
      ];
    } else if (distance < 3000) {
      choices = const [
        HazardKind.barrier,
        HazardKind.laser,
        HazardKind.spikes,
        HazardKind.blade,
      ];
    } else {
      choices = const [
        HazardKind.barrier,
        HazardKind.laser,
        HazardKind.spikes,
        HazardKind.blade,
        HazardKind.movingGate,
      ];
    }

    var selected =
    choices[
    _random.nextInt(
      choices.length,
    )
    ];

    final dangerousRepeat =
        selected == _lastHazard &&
            (
                selected ==
                    HazardKind.blade ||
                    selected ==
                        HazardKind.movingGate
            );

    if (dangerousRepeat &&
        choices.length > 1) {
      final alternatives =
      choices
          .where(
            (hazard) =>
        hazard != selected,
      )
          .toList();

      selected =
      alternatives[
      _random.nextInt(
        alternatives.length,
      )
      ];
    }

    _lastHazard = selected;

    return selected;
  }

  TrackRow _newRow(
      double y, {
        bool first = false,
      }) {
    return TrackRow(
      y: y,
      blockedLane:
      _chooseBlockedLane(),
      kind:
      first
          ? HazardKind.barrier
          : _chooseHazard(),
      hasCoin:
      !first &&
          _random.nextDouble() <
              _coinChance,
    );
  }

  double _skillLaserGap() {
    // Time between the two lasers gets tighter as difficulty rises.
    // It still leaves enough time for: dash in -> collect -> dash out.
    final double windowSeconds;

    switch (difficultyTier) {
      case 1:
        windowSeconds = 1.05;
        break;
      case 2:
        windowSeconds = 0.92;
        break;
      case 3:
        windowSeconds = 0.82;
        break;
      case 4:
        windowSeconds = 0.74;
        break;
      case 5:
      default:
        windowSeconds = 0.68;
        break;
    }

    return (_effectiveSpeed * windowSeconds)
        .clamp(185.0, 255.0)
        .toDouble();
  }

  double _skillPatternInterval() {
    return 180 + _random.nextDouble() * 100;
  }

  void _appendSkillLaserPocket() {
    final lane = _random.nextInt(2);
    final gap = _skillLaserGap();

    final firstY =
        _rows.last.y -
            max(
              250.0,
              _rowSpacing * 0.82,
            );

    final triplePattern =
        difficultyTier >= 4 &&
            _random.nextDouble() <
                (difficultyTier == 5 ? 0.52 : 0.34);

    // First laser. Staying in the other lane is always safe.
    _rows.add(
      TrackRow(
        y: firstY,
        blockedLane: lane,
        kind: HazardKind.laser,
        hasCoin: false,
      ),
    );

    // The reward sits in the dangerous lane, exactly between lasers.
    // Magnet does not collect these coins: the player must actually dash in.
    _skillCoins.add(
      _SkillCoin(
        lane: lane,
        y: firstY - gap * 0.50,
        value: difficultyTier >= 3 ? 2 : 1,
      ),
    );

    _rows.add(
      TrackRow(
        y: firstY - gap,
        blockedLane: lane,
        kind: HazardKind.laser,
        hasCoin: false,
      ),
    );

    // At high difficulty a third laser creates a second pocket.
    // To collect both rewards the player must dash in, out, in, out.
    if (triplePattern) {
      _skillCoins.add(
        _SkillCoin(
          lane: lane,
          y: firstY - gap * 1.50,
          value: 2,
        ),
      );

      _rows.add(
        TrackRow(
          y: firstY - gap * 2,
          blockedLane: lane,
          kind: HazardKind.laser,
          hasCoin: false,
        ),
      );
    }

    // Keep the normal fair-generator state in sync with the manual pattern.
    _lastBlockedLane = lane;
    _sameLaneStreak = 2;
    _lastHazard = HazardKind.laser;

    _nextSkillPatternDistance =
        distance +
            _skillPatternInterval();
  }

  void _generateAhead() {
    if (_rows.isEmpty) {
      _rows.add(
        _newRow(
          -100,
          first: true,
        ),
      );
    }

    while (_rows.last.y >
        -_height) {
      final skillPatternReady =
          distance >=
              _nextSkillPatternDistance &&
              distance >= 100;

      if (skillPatternReady) {
        _appendSkillLaserPocket();
      } else {
        _rows.add(
          _newRow(
            _rows.last.y -
                _rowSpacing,
          ),
        );
      }
    }
  }

  // ============================================================
  // POWER-UP SPAWNING
  // ============================================================

  void _spawnPowerUpIfNeeded() {
    if (distance <
        _nextPowerUpDistance) {
      return;
    }

    final hasUncollectedPowerUp =
    _powerUps.any(
          (powerUp) =>
      !powerUp.collected,
    );

    if (hasUncollectedPowerUp) {
      return;
    }

    final kind =
    PowerUpKind.values[
    _random.nextInt(
      PowerUpKind.values.length,
    )
    ];

    final lane =
    _random.nextInt(2);

    double y = -130;

    if (_rows.isNotEmpty) {
      y =
          _rows.last.y -
              _rowSpacing * 0.45;
    }

    _powerUps.add(
      _PowerUpPickup(
        kind: kind,
        lane: lane,
        y: y,
      ),
    );

    _nextPowerUpDistance =
        distance +
            560 +
            _random.nextDouble() *
                300;
  }

  void _activatePowerUp(
      PowerUpKind kind,
      ) {
    switch (kind) {
      case PowerUpKind.shield:
        shieldTime = 12;

        rushEvent =
        'SHIELD READY';

        rushEventTime = 1.1;

        score += 50;

        break;

      case PowerUpKind.magnet:
        magnetTime = 9;

        rushEvent =
        'COIN MAGNET';

        rushEventTime = 1.1;

        score += 50;

        break;

      case PowerUpKind.slowMotion:
        slowMotionTime = 6;

        rushEvent =
        'SLOW TIME';

        rushEventTime = 1.1;

        score += 50;

        break;
    }

    _notify();
  }

  // ============================================================
  // RUN EVENTS / MILESTONES / RUSH ZONE
  // ============================================================

  void _checkRunEvents(
      double previousDistance,
      double currentDistance,
      ) {
    // ----------------------------------------------------------
    // 500 MILESTONE
    // ----------------------------------------------------------

    final previousMilestone =
    (
        previousDistance /
            500
    ).floor();

    final currentMilestone =
    (
        currentDistance /
            500
    ).floor();

    if (currentMilestone >
        previousMilestone &&
        currentMilestone > 0) {
      final metres =
          currentMilestone *
              500;

      final bonus =
          75 +
              currentMilestone *
                  25;

      score += bonus;

      rushEvent =
      '$metres m REACHED  +$bonus';

      rushEventTime = 1.1;
    }

    // ----------------------------------------------------------
    // RUSH ZONES
    //
    // 800 m
    // 2000 m
    // 3200 m
    // 4400 m
    // etc.
    // ----------------------------------------------------------

    double nextRushDistance;

    if (previousDistance <
        800) {
      nextRushDistance =
      800.0;
    } else {
      final completedZones =
      (
          (
              previousDistance -
                  800
          ) /
              1200
      )
          .floor();

      nextRushDistance =
          800.0 +
              (
                  completedZones +
                      1
              ) *
                  1200.0;
    }

    if (!rushZoneActive &&
        previousDistance <
            nextRushDistance &&
        currentDistance >=
            nextRushDistance) {
      rushZoneTime = 8;

      score += 100;

      rushEvent =
      'RUSH ZONE!  x2 SCORE';

      rushEventTime = 1.3;

      _notify();
    }
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void update(
      double dt,
      ) {
    super.update(dt);

    if (size.x <= 0 ||
        size.y <= 0) {
      return;
    }

    if (state != RunState.paused) {
      _updateVisualFx(dt);
    }

    if (state ==
        RunState.impact) {
      _impactTime += dt;

      if (_impactTime >=
          0.46) {
        state =
            RunState.gameOver;

        _notify();
      }

      return;
    }

    if (state !=
        RunState.playing) {
      return;
    }

    _runTime += dt;
    _timeSinceDash += dt;

    if (_comboGraceTime > 0) {
      _comboGraceTime =
          max(
            0.0,
            _comboGraceTime - dt,
          ).toDouble();

      if (_comboGraceTime <= 0 &&
          combo > 0) {
        combo = 0;
      }
    }

    // ----------------------------------------------------------
    // POWER-UP TIMERS
    // ----------------------------------------------------------

    if (shieldTime > 0) {
      shieldTime =
          max(
            0.0,
            shieldTime - dt,
          ).toDouble();
    }

    if (magnetTime > 0) {
      magnetTime =
          max(
            0.0,
            magnetTime - dt,
          ).toDouble();
    }

    if (slowMotionTime > 0) {
      slowMotionTime =
          max(
            0.0,
            slowMotionTime - dt,
          ).toDouble();
    }

    if (_invulnerableTime > 0) {
      _invulnerableTime =
          max(
            0.0,
            _invulnerableTime - dt,
          ).toDouble();
    }

    // ----------------------------------------------------------
    // RUSH TIMER
    // ----------------------------------------------------------

    if (rushZoneTime > 0) {
      final previousRushTime =
          rushZoneTime;

      rushZoneTime =
          max(
            0.0,
            rushZoneTime - dt,
          ).toDouble();

      if (previousRushTime > 0 &&
          rushZoneTime <= 0) {
        rushEvent =
        'RUSH COMPLETE';

        rushEventTime = 0.9;
      }
    }

    // ----------------------------------------------------------
    // EVENT POPUP TIMER
    // ----------------------------------------------------------

    if (rushEventTime > 0) {
      rushEventTime =
          max(
            0.0,
            rushEventTime - dt,
          ).toDouble();

      if (rushEventTime <= 0) {
        rushEvent = null;
      }
    }

    // ----------------------------------------------------------
    // PHYSICS
    // ----------------------------------------------------------

    var remaining =
    dt
        .clamp(
      0.0,
      0.1,
    )
        .toDouble();

    while (
    remaining > 0 &&
        state ==
            RunState.playing) {
      final step =
      min(
        remaining,
        1 / 120,
      ).toDouble();

      _advance(step);

      remaining -= step;
    }

    // ----------------------------------------------------------
    // UI UPDATE
    // ----------------------------------------------------------

    _uiTime += dt;

    if (_uiTime >= 0.1) {
      _uiTime = 0;

      _notify();
    }
  }

  // ============================================================
  // NEAR MISS
  // ============================================================

  bool _isNearMiss(
      TrackRow row,
      Offset player,
      ) {
    final rect =
        row.hazardRect;

    final playerLeft =
        player.dx -
            ballRadius;

    final playerRight =
        player.dx +
            ballRadius;

    if (playerRight >=
        rect.left &&
        playerLeft <=
            rect.right) {
      return false;
    }

    double gap;

    if (player.dx <
        rect.left) {
      gap =
          rect.left -
              playerRight;
    } else {
      gap =
          playerLeft -
              rect.right;
    }

    final skillDash =
        _timeSinceDash <=
            0.28 &&
            gap <= 42;

    return gap >= 0 &&
        (
            gap <= 25 ||
                skillDash
        );
  }

  // ============================================================
  // GAME ADVANCE
  // ============================================================

  void _advance(
      double dt,
      ) {
    _generateAhead();
    _spawnPowerUpIfNeeded();

    // ----------------------------------------------------------
    // DASH
    // ----------------------------------------------------------

    if (_dashTime <
        dashDuration) {
      _dashTime =
          min(
            _dashTime + dt,
            dashDuration,
          ).toDouble();

      final t =
          _dashTime /
              dashDuration;

      final eased =
          1 -
              pow(
                1 - t,
                3,
              ).toDouble();

      _ballX =
          _dashStartX +
              (
                  _dashTargetX -
                      _dashStartX
              ) *
                  eased;
    }

    // ----------------------------------------------------------
    // WORLD MOVEMENT
    // ----------------------------------------------------------

    final movement =
        _effectiveSpeed *
            dt;

    _floorOffset =
        (
            _floorOffset +
                movement
        ) %
            80;

    final previousDistance =
        distance;

    distance +=
        movement /
            10;

    _checkRunEvents(
      previousDistance,
      distance,
    );

    final player =
    Offset(
      _ballX,
      _ballY,
    );

    // ----------------------------------------------------------
    // POWER-UP PICKUPS
    // ----------------------------------------------------------

    for (final powerUp
    in _powerUps) {
      powerUp.advance(
        movement,
      );

      if (powerUp.collected) {
        continue;
      }

      final pickupDistance =
          (
              player -
                  powerUp.position
          ).distanceSquared;

      if (pickupDistance <
          30 * 30) {
        powerUp.collected = true;

        _spawnBurst(
          powerUp.position,
          _powerUpColor(
            powerUp.kind,
          ),
          count: 16,
          speed: 105,
          life: 0.42,
          size: 2.8,
        );

        _triggerImpactFx(
          color: _powerUpColor(
            powerUp.kind,
          ),
          shake: 2.0,
          flash: 0.07,
        );

        _activatePowerUp(
          powerUp.kind,
        );
      }
    }

    // ----------------------------------------------------------
    // SKILL COINS
    // ----------------------------------------------------------

    for (final skillCoin in _skillCoins) {
      skillCoin.advance(movement);

      if (skillCoin.collected) {
        continue;
      }

      // Skill coins deliberately ignore Magnet. Their purpose is to tempt
      // the player into the laser pocket and require a real double dash.
      final pickupRadius =
          ballRadius + 12;

      if ((player - skillCoin.position).distanceSquared <
          pickupRadius * pickupRadius) {
        skillCoin.collected = true;

        runCoins +=
            skillCoin.value;

        final bonus =
            70 *
                skillCoin.value *
                scoreMultiplier;

        score += bonus;

        _spawnBurst(
          skillCoin.position,
          const Color(0xFFFFD45A),
          count: 16,
          speed: 105,
          life: 0.40,
          size: 2.8,
        );

        _triggerImpactFx(
          color: const Color(0xFFFFD45A),
          shake: 2.2,
          flash: 0.06,
        );

        rushEvent =
        'SKILL COIN  +${skillCoin.value}';
        rushEventTime = 0.95;

        _comboGraceTime = 3.25;
      }
    }

    // ----------------------------------------------------------
    // HAZARDS / COINS / DODGES
    // ----------------------------------------------------------

    for (final row
    in _rows) {
      row.advance(
        dt,
        movement,
      );

      // Collision.
      if (row.touches(
        player,
        ballRadius,
      )) {
        _hit();

        if (state !=
            RunState.playing) {
          return;
        }
      }

      // Coin collection.
      if (row.hasCoin) {
        final coinRadius =
        magnetActive
            ? 175.0
            : ballRadius + 9;

        if (
        (
            player -
                row.coinPosition
        ).distanceSquared <
            coinRadius *
                coinRadius) {
          row.hasCoin = false;

          runCoins++;

          _spawnBurst(
            row.coinPosition,
            const Color(
              0xFFFFC64A,
            ),
            count: 8,
            speed: 72,
            life: 0.28,
            size: 2.1,
          );

          score +=
              20 *
                  scoreMultiplier;
        }
      }

      // Successful dodge.
      if (!row.countedAsDodged &&
          row.y >
              _ballY +
                  ballRadius +
                  24) {
        row.countedAsDodged = true;

        dodgedObstacles++;

        combo++;

        _comboGraceTime = 3.25;

        if (combo >
            bestCombo) {
          bestCombo = combo;
        }

        final multiplier =
            scoreMultiplier;

        score +=
            10 *
                multiplier;

        final nearMiss =
        _isNearMiss(
          row,
          player,
        );

        if (nearMiss) {
          nearMisses++;

          final bonus =
              40 *
                  multiplier;

          score += bonus;

          _spawnBurst(
            player,
            const Color(
              0xFFFFD45A,
            ),
            count: 5,
            speed: 42,
            life: 0.22,
            size: 1.8,
          );

          rushEvent =
          'NEAR MISS  +$bonus';

          rushEventTime =
          0.95;
        } else if (
        combo % 5 ==
            0) {
          rushEvent =
          'COMBO  x$multiplier';

          rushEventTime =
          0.8;
        }
      }
    }

    // ----------------------------------------------------------
    // CLEANUP
    // ----------------------------------------------------------

    _rows.removeWhere(
          (row) =>
      row.y >
          _height +
              100,
    );

    _powerUps.removeWhere(
          (powerUp) =>
      powerUp.collected ||
          powerUp.y >
              _height +
                  100,
    );

    _skillCoins.removeWhere(
          (skillCoin) =>
      skillCoin.collected ||
          skillCoin.y >
              _height +
                  80,
    );
  }

  // ============================================================
  // HAZARD DRAWING
  // ============================================================

  void _drawHazard(
      Canvas canvas,
      Paint paint,
      TrackRow row,
      ) {
    final rect =
        row.hazardRect;

    final glowColor =
    _hazardGlowColor(
      row.kind,
    );

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        8,
      )
      ..color = glowColor.withValues(
        alpha: 0.16,
      );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.inflate(5),
        const Radius.circular(
          9,
        ),
      ),
      paint,
    );

    paint.maskFilter = null;

    switch (row.kind) {
      case HazardKind.barrier:
        paint
          ..style =
              PaintingStyle.fill
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFE496B,
          );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            const Radius.circular(
              6,
            ),
          ),
          paint,
        );

        paint.color =
        const Color(
          0xFFFFBBC8,
        );

        canvas.drawRect(
          Rect.fromLTWH(
            rect.left +
                8,
            row.y -
                2,
            rect.width -
                16,
            4,
          ),
          paint,
        );

        break;

      case HazardKind.laser:
        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFFFF507B,
          ).withValues(
            alpha:
            0.35,
          )
          ..maskFilter =
          const MaskFilter.blur(
            BlurStyle.normal,
            10,
          );

        canvas.drawRect(
          rect.inflate(
            7,
          ),
          paint,
        );

        paint
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFF6788,
          );

        canvas.drawRect(
          rect,
          paint,
        );

        paint.color =
        const Color(
          0xFFFFD2E0,
        );

        canvas.drawRect(
          Rect.fromLTWH(
            rect.left,
            row.y -
                2,
            rect.width,
            4,
          ),
          paint,
        );

        break;

      case HazardKind.spikes:
        paint
          ..style =
              PaintingStyle.fill
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFF8458,
          );

        const spikeCount =
        6;

        final spikeWidth =
            rect.width /
                spikeCount;

        for (var i = 0;
        i <
            spikeCount;
        i++) {
          final left =
              rect.left +
                  i *
                      spikeWidth;

          final triangle =
          Path()
            ..moveTo(
              left,
              rect.bottom,
            )
            ..lineTo(
              left +
                  spikeWidth /
                      2,
              rect.top,
            )
            ..lineTo(
              left +
                  spikeWidth,
              rect.bottom,
            )
            ..close();

          canvas.drawPath(
            triangle,
            paint,
          );
        }

        break;

      case HazardKind.blade:
        paint
          ..style =
              PaintingStyle.fill
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFF6C91,
          );

        canvas.drawCircle(
          row.bladeCenter,
          19,
          paint,
        );

        paint.color =
        const Color(
          0xFF4E162C,
        );

        canvas.drawCircle(
          row.bladeCenter,
          14,
          paint,
        );

        paint
          ..color =
          const Color(
            0xFFFFB0C3,
          )
          ..strokeWidth =
          3;

        for (var i = 0;
        i < 4;
        i++) {
          final angle =
              row.animationTime *
                  5 +
                  i *
                      pi /
                      2;

          canvas.drawLine(
            row.bladeCenter,
            row.bladeCenter +
                Offset(
                  cos(
                    angle,
                  ),
                  sin(
                    angle,
                  ),
                ) *
                    14,
            paint,
          );
        }

        paint.color =
        const Color(
          0xFFFFFFFF,
        );

        canvas.drawCircle(
          row.bladeCenter,
          4,
          paint,
        );

        break;

      case HazardKind.movingGate:
        paint
          ..style =
              PaintingStyle.fill
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFF5C88,
          );

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect,
            const Radius.circular(
              6,
            ),
          ),
          paint,
        );

        paint.color =
        const Color(
          0xFFFFD3DC,
        );

        canvas.drawRect(
          Rect.fromLTWH(
            rect.left +
                7,
            row.y -
                2,
            rect.width -
                14,
            4,
          ),
          paint,
        );

        break;
    }
  }

  // ============================================================
  // SKILL COIN DRAWING
  // ============================================================

  void _drawSkillCoin(
      Canvas canvas,
      Paint paint,
      _SkillCoin skillCoin,
      ) {
    final center = skillCoin.position;
    final pulse =
        (sin(_runTime * 10 + skillCoin.y * 0.02) + 1) / 2;

    const gold = Color(0xFFFFD45A);

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        12,
      )
      ..color = gold.withValues(
        alpha: 0.24 + pulse * 0.18,
      );

    canvas.drawCircle(
      center,
      19 + pulse * 3,
      paint,
    );

    paint
      ..maskFilter = null
      ..color = const Color(0xFFFFC64A);

    final diamond = Path()
      ..moveTo(center.dx, center.dy - 11)
      ..lineTo(center.dx + 9, center.dy)
      ..lineTo(center.dx, center.dy + 11)
      ..lineTo(center.dx - 9, center.dy)
      ..close();

    canvas.drawPath(diamond, paint);

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFFFF2B2);

    canvas.drawPath(diamond, paint);

    paint
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF7A4D00);

    final text = TextPainter(
      text: TextSpan(
        text: skillCoin.value > 1 ? '${skillCoin.value}' : '★',
        style: const TextStyle(
          color: Color(0xFF7A4D00),
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    text.paint(
      canvas,
      Offset(
        center.dx - text.width / 2,
        center.dy - text.height / 2,
      ),
    );
  }

  // ============================================================
  // POWER-UP DRAWING
  // ============================================================

  Color _powerUpColor(
      PowerUpKind kind,
      ) {
    switch (kind) {
      case PowerUpKind.shield:
        return const Color(
          0xFF53EAFF,
        );

      case PowerUpKind.magnet:
        return const Color(
          0xFF65F2B5,
        );

      case PowerUpKind.slowMotion:
        return const Color(
          0xFFB76CFF,
        );
    }
  }

  void _drawPowerUp(
      Canvas canvas,
      Paint paint,
      _PowerUpPickup powerUp,
      ) {
    final center =
        powerUp.position;

    final color =
    _powerUpColor(
      powerUp.kind,
    );

    final pulse =
        (
            sin(
              _runTime *
                  6 +
                  powerUp.y *
                      0.01,
            ) +
                1
        ) /
            2;

    // Glow.
    paint
      ..style =
          PaintingStyle.fill
      ..color =
      color.withValues(
        alpha:
        0.20 +
            pulse *
                0.10,
      )
      ..maskFilter =
      const MaskFilter.blur(
        BlurStyle.normal,
        13,
      );

    canvas.drawCircle(
      center,
      24 +
          pulse *
              3,
      paint,
    );

    // Core.
    paint
      ..maskFilter =
      null
      ..color =
      const Color(
        0xFF101A31,
      );

    canvas.drawCircle(
      center,
      17,
      paint,
    );

    // Ring.
    paint
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
      2.5
      ..color =
          color;

    canvas.drawCircle(
      center,
      16,
      paint,
    );

    switch (powerUp.kind) {
      case PowerUpKind.shield:
        final shield =
        Path()
          ..moveTo(
            center.dx,
            center.dy -
                9,
          )
          ..lineTo(
            center.dx +
                8,
            center.dy -
                5,
          )
          ..lineTo(
            center.dx +
                6,
            center.dy +
                6,
          )
          ..lineTo(
            center.dx,
            center.dy +
                11,
          )
          ..lineTo(
            center.dx -
                6,
            center.dy +
                6,
          )
          ..lineTo(
            center.dx -
                8,
            center.dy -
                5,
          )
          ..close();

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          2
          ..color =
              color;

        canvas.drawPath(
          shield,
          paint,
        );

        break;

      case PowerUpKind.magnet:
        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          4
          ..color =
              color;

        canvas.drawArc(
          Rect.fromCircle(
            center:
            center.translate(
              0,
              -1,
            ),
            radius:
            8,
          ),
          0,
          pi,
          false,
          paint,
        );

        paint
          ..style =
              PaintingStyle.fill
          ..color =
              color;

        canvas.drawCircle(
          center.translate(
            -8,
            -1,
          ),
          2.5,
          paint,
        );

        canvas.drawCircle(
          center.translate(
            8,
            -1,
          ),
          2.5,
          paint,
        );

        break;

      case PowerUpKind.slowMotion:
        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          2
          ..color =
              color;

        canvas.drawCircle(
          center,
          8,
          paint,
        );

        canvas.drawLine(
          center,
          center.translate(
            0,
            -5,
          ),
          paint,
        );

        canvas.drawLine(
          center,
          center.translate(
            5,
            2,
          ),
          paint,
        );

        break;
    }

    paint.style =
        PaintingStyle.fill;
  }

  // ============================================================
  // MAP SCENERY
  // ============================================================

  void _drawMapScenery(
      Canvas canvas,
      Paint paint,
      ) {
    // The old chunky side blocks were intentionally removed.
    // Thin continuous cues make the environment feel smooth and fast.

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;

    switch (mapStyle.id) {
      case 'neon_city':
        for (var i = 0; i < 7; i++) {
          final leftX =
              7.0 +
                  i % 3 *
                      7;

          final rightX =
              353.0 -
                  i % 3 *
                      7;

          final y =
              (
                  _floorOffset *
                      0.44 +
                      i *
                          128
              ) %
                  (
                      _height +
                          160
                  ) -
                  80;

          final height =
              64.0 +
                  i % 3 *
                      24;

          paint.color =
              mapStyle.edge.withValues(
                alpha:
                0.08 +
                    i % 2 *
                        0.035,
              );

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                leftX,
                y,
                3.2,
                height,
              ),
              const Radius.circular(
                2,
              ),
            ),
            paint,
          );

          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(
                rightX - 3.2,
                y + 22,
                3.2,
                height * 0.82,
              ),
              const Radius.circular(
                2,
              ),
            ),
            paint,
          );
        }

        paint.color =
            const Color(
              0xFFFFFFFF,
            ).withValues(
              alpha: 0.34,
            );

        for (var i = 0; i < 16; i++) {
          final leftSide =
              i.isEven;

          final x =
          leftSide
              ? 9.0 +
              (
                  i *
                      11
              ) %
                  24
              : 351.0 -
              (
                  i *
                      13
              ) %
                  24;

          final y =
              (
                  i *
                      71 +
                      _floorOffset *
                          0.31
              ) %
                  (
                      _height +
                          50
                  ) -
                  25;

          canvas.drawCircle(
            Offset(
              x,
              y,
            ),
            0.9 +
                i % 3 *
                    0.25,
            paint,
          );
        }

        break;

      case 'cyber_tunnel':
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;

        for (var i = 0; i < 9; i++) {
          final y =
              (
                  _floorOffset *
                      0.82 +
                      i *
                          92
              ) %
                  (
                      _height +
                          100
                  ) -
                  50;

          paint.color =
              mapStyle.edge.withValues(
                alpha:
                0.10 +
                    i % 3 *
                        0.04,
              );

          canvas.drawLine(
            Offset(
              4,
              y,
            ),
            Offset(
              34,
              y + 24,
            ),
            paint,
          );

          canvas.drawLine(
            Offset(
              356,
              y,
            ),
            Offset(
              326,
              y + 24,
            ),
            paint,
          );
        }

        paint.style =
            PaintingStyle.fill;

        break;

      case 'space_station':
        paint.color =
            const Color(
              0xFFFFFFFF,
            ).withValues(
              alpha: 0.44,
            );

        for (var i = 0; i < 30; i++) {
          final x =
              (
                  i *
                      71 +
                      13
              ) %
                  360;

          final y =
              (
                  i *
                      97 +
                      _floorOffset *
                          0.28
              ) %
                  (
                      _height +
                          60
                  ) -
                  30;

          if (x > 38 &&
              x < 322) {
            continue;
          }

          canvas.drawCircle(
            Offset(
              x.toDouble(),
              y,
            ),
            0.8 +
                i % 3 *
                    0.45,
            paint,
          );
        }

        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color =
          mapStyle.edge.withValues(
            alpha: 0.18,
          );

        for (var i = 0; i < 6; i++) {
          final y =
              (
                  _floorOffset *
                      0.38 +
                      i *
                          142
              ) %
                  (
                      _height +
                          120
                  ) -
                  60;

          canvas.drawLine(
            Offset(
              8,
              y,
            ),
            Offset(
              31,
              y + 34,
            ),
            paint,
          );

          canvas.drawLine(
            Offset(
              352,
              y,
            ),
            Offset(
              329,
              y + 34,
            ),
            paint,
          );
        }

        paint.style =
            PaintingStyle.fill;

        break;

      case 'lava_core':
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..color =
          mapStyle.edge.withValues(
            alpha: 0.34,
          );

        for (var side = 0;
        side < 2;
        side++) {
          final path =
          Path();

          final baseX =
          side == 0
              ? 21.0
              : 339.0;

          path.moveTo(
            baseX,
            -20,
          );

          for (double y = -20;
          y < _height + 30;
          y += 34) {
            final wave =
                sin(
                  (
                      y +
                          _floorOffset *
                              1.15
                  ) /
                      32,
                ) *
                    7;

            path.lineTo(
              baseX +
                  (
                      side == 0
                          ? wave
                          : -wave
                  ),
              y,
            );
          }

          canvas.drawPath(
            path,
            paint,
          );
        }

        paint.style =
            PaintingStyle.fill;

        break;

      case 'frozen_world':
        paint
          ..style = PaintingStyle.fill
          ..color =
          const Color(
            0xFFE7FCFF,
          ).withValues(
            alpha: 0.34,
          );

        for (var i = 0; i < 24; i++) {
          final leftSide =
              i.isEven;

          final x =
          leftSide
              ? 8.0 +
              i % 4 *
                  6
              : 352.0 -
              i % 4 *
                  6;

          final y =
              (
                  _floorOffset *
                      0.50 +
                      i *
                          61
              ) %
                  (
                      _height +
                          70
                  ) -
                  35;

          canvas.drawCircle(
            Offset(
              x,
              y,
            ),
            1.3 +
                i % 3 *
                    0.5,
            paint,
          );
        }

        break;

      case 'dark_galaxy':
        paint
          ..style = PaintingStyle.fill
          ..color =
          const Color(
            0xFFFFFFFF,
          ).withValues(
            alpha: 0.45,
          );

        for (var i = 0; i < 34; i++) {
          final x =
              (
                  i *
                      73 +
                      17
              ) %
                  360;

          final y =
              (
                  i *
                      113 +
                      _floorOffset *
                          0.18
              ) %
                  (
                      _height +
                          80
                  ) -
                  40;

          if (x > 38 &&
              x < 322) {
            continue;
          }

          canvas.drawCircle(
            Offset(
              x.toDouble(),
              y,
            ),
            0.8 +
                i % 4 *
                    0.35,
            paint,
          );
        }

        paint
          ..color =
          mapStyle.edge.withValues(
            alpha: 0.09,
          )
          ..maskFilter =
          const MaskFilter.blur(
            BlurStyle.normal,
            18,
          );

        final drift =
            sin(
              _floorOffset /
                  80,
            ) *
                6;

        canvas.drawCircle(
          Offset(
            18 + drift,
            _height * 0.29,
          ),
          30,
          paint,
        );

        canvas.drawCircle(
          Offset(
            342 - drift,
            _height * 0.67,
          ),
          38,
          paint,
        );

        paint.maskFilter = null;

        break;

      default:
        break;
    }

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;
  }


  void _drawRoadFlow(
      Canvas canvas,
      Paint paint,
      ) {
    final laneX =
    _targetLane == 0
        ? 110.0
        : 250.0;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        18,
      )
      ..color =
      ballColor.withValues(
        alpha: 0.035,
      );

    canvas.drawLine(
      Offset(
        laneX,
        _ballY - 150,
      ),
      Offset(
        laneX,
        _ballY + 95,
      ),
      paint,
    );

    paint.maskFilter = null;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color =
      mapStyle.edge.withValues(
        alpha:
        0.08 +
            difficultyTier *
                0.015,
      );

    for (var i = 0; i < 7; i++) {
      final y =
          (
              _floorOffset *
                  1.35 +
                  i *
                      96
          ) %
              (
                  _height +
                      80
              ) -
              40;

      canvas.drawLine(
        Offset(
          54,
          y,
        ),
        Offset(
          72,
          y + 32,
        ),
        paint,
      );

      canvas.drawLine(
        Offset(
          306,
          y,
        ),
        Offset(
          288,
          y + 32,
        ),
        paint,
      );
    }

    paint.style =
        PaintingStyle.fill;
  }

  void _drawSideRails(
      Canvas canvas,
      Paint paint,
      ) {
    final pulse =
        (
            sin(
              _runTime *
                  5,
            ) +
                1
        ) /
            2;

    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        10,
      )
      ..color =
      mapStyle.edge.withValues(
        alpha:
        0.10 +
            pulse *
                0.05,
      );

    canvas.drawLine(
      const Offset(
        40,
        0,
      ),
      Offset(
        40,
        _height,
      ),
      paint,
    );

    canvas.drawLine(
      const Offset(
        320,
        0,
      ),
      Offset(
        320,
        _height,
      ),
      paint,
    );

    paint
      ..maskFilter = null
      ..strokeWidth = 2.2
      ..color =
      mapStyle.edge.withValues(
        alpha: 0.94,
      );

    canvas.drawLine(
      const Offset(
        40,
        0,
      ),
      Offset(
        40,
        _height,
      ),
      paint,
    );

    canvas.drawLine(
      const Offset(
        320,
        0,
      ),
      Offset(
        320,
        _height,
      ),
      paint,
    );

    final packetSpeed =
        1.65 +
            difficultyTier *
                0.14;

    for (var i = 0; i < 8; i++) {
      final y =
          (
              _floorOffset *
                  packetSpeed +
                  i *
                      105
          ) %
              (
                  _height +
                      70
              ) -
              35;

      final packetAlpha =
          0.30 +
              i % 3 *
                  0.10;

      paint
        ..strokeWidth = 3.4
        ..color =
        (
            rushZoneActive
                ? const Color(
              0xFFFFA640,
            )
                : mapStyle.edge
        ).withValues(
          alpha:
          packetAlpha,
        );

      canvas.drawLine(
        Offset(
          40,
          y,
        ),
        Offset(
          40,
          y + 22,
        ),
        paint,
      );

      canvas.drawLine(
        Offset(
          320,
          y + 34,
        ),
        Offset(
          320,
          y + 56,
        ),
        paint,
      );
    }

    paint
      ..style = PaintingStyle.fill
      ..maskFilter = null;
  }

  // ============================================================
  // NORMAL SPEED EFFECTS
  // ============================================================

  void _drawSpeedEffects(
      Canvas canvas,
      Paint paint,
      ) {
    if (difficultyTier < 2) {
      return;
    }

    final intensity =
        (
            difficultyTier -
                1
        ) /
            4;

    paint
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          1.5 +
              intensity *
                  1.5
      ..color =
      mapStyle.edge
          .withValues(
        alpha:
        0.12 +
            intensity *
                0.24,
      );

    for (var i = 0;
    i < 12;
    i++) {
      final y =
          (
              _floorOffset *
                  (
                      1.2 +
                          intensity
                  ) +
                  i *
                      78
          ) %
              (
                  _height +
                      120
              ) -
              60;

      final length =
          18 +
              intensity *
                  34;

      final leftX =
          10 +
              (
                  i %
                      3
              ) *
                  9;

      final rightX =
          350 -
              (
                  i %
                      3
              ) *
                  9;

      canvas.drawLine(
        Offset(
          leftX.toDouble(),
          y,
        ),
        Offset(
          leftX.toDouble(),
          y +
              length,
        ),
        paint,
      );

      canvas.drawLine(
        Offset(
          rightX.toDouble(),
          y,
        ),
        Offset(
          rightX.toDouble(),
          y +
              length,
        ),
        paint,
      );
    }

    paint.style =
        PaintingStyle.fill;
  }

  // ============================================================
  // RUSH ZONE VISUAL EFFECT
  // ============================================================

  void _drawRushZoneEffect(
      Canvas canvas,
      Paint paint,
      ) {
    if (!rushZoneActive) {
      return;
    }

    final pulse =
        (
            sin(
              _runTime *
                  10,
            ) +
                1
        ) /
            2;

    const rushColor =
    Color(
      0xFFFFA640,
    );

    // Orange track tint.
    paint
      ..style =
          PaintingStyle.fill
      ..maskFilter =
      null
      ..color =
      rushColor.withValues(
        alpha:
        0.04 +
            pulse *
                0.025,
      );

    canvas.drawRect(
      Rect.fromLTWH(
        40,
        0,
        280,
        _height,
      ),
      paint,
    );

    // Glowing track border.
    paint
      ..style =
          PaintingStyle.stroke
      ..strokeWidth =
          3 +
              pulse *
                  2
      ..color =
      rushColor.withValues(
        alpha:
        0.42 +
            pulse *
                0.25,
      );

    canvas.drawLine(
      const Offset(
        42,
        0,
      ),
      Offset(
        42,
        _height,
      ),
      paint,
    );

    canvas.drawLine(
      const Offset(
        318,
        0,
      ),
      Offset(
        318,
        _height,
      ),
      paint,
    );

    // Fast orange streaks.
    paint.strokeWidth =
    2;

    for (var i = 0;
    i < 10;
    i++) {
      final y =
          (
              _floorOffset *
                  2.4 +
                  i *
                      82
          ) %
              (
                  _height +
                      100
              ) -
              50;

      canvas.drawLine(
        Offset(
          55,
          y,
        ),
        Offset(
          55,
          y +
              38,
        ),
        paint,
      );

      canvas.drawLine(
        Offset(
          305,
          y,
        ),
        Offset(
          305,
          y +
              38,
        ),
        paint,
      );
    }

    paint.style =
        PaintingStyle.fill;
  }

  // ============================================================
  // ACTIVE POWER-UP EFFECTS
  // ============================================================

  void _drawPowerUpEffects(
      Canvas canvas,
      Paint paint,
      Offset player,
      ) {
    // Shield.
    if (shieldActive) {
      final pulse =
          (
              sin(
                _runTime *
                    7,
              ) +
                  1
          ) /
              2;

      paint
        ..style =
            PaintingStyle.stroke
        ..strokeWidth =
        2
        ..maskFilter =
        const MaskFilter.blur(
          BlurStyle.normal,
          4,
        )
        ..color =
        const Color(
          0xFF53EAFF,
        ).withValues(
          alpha:
          0.55 +
              pulse *
                  0.25,
        );

      canvas.drawCircle(
        player,
        25 +
            pulse *
                2,
        paint,
      );

      paint.maskFilter =
      null;
    }

    // Magnet orbit.
    if (magnetActive) {
      paint
        ..style =
            PaintingStyle.fill
        ..maskFilter =
        null
        ..color =
        const Color(
          0xFF65F2B5,
        );

      for (var i = 0;
      i < 3;
      i++) {
        final angle =
            _runTime *
                3 +
                i *
                    pi *
                    2 /
                    3;

        canvas.drawCircle(
          player +
              Offset(
                cos(
                  angle,
                ),
                sin(
                  angle,
                ),
              ) *
                  29,
          2.5,
          paint,
        );
      }
    }

    // Slow-time aura.
    if (slowMotionActive) {
      paint
        ..style =
            PaintingStyle.stroke
        ..strokeWidth =
        1.5
        ..color =
        const Color(
          0xFFB76CFF,
        ).withValues(
          alpha:
          0.75,
        );

      canvas.drawCircle(
        player,
        32,
        paint,
      );
    }

    // Rush Zone aura.
    if (rushZoneActive) {
      final pulse =
          (
              sin(
                _runTime *
                    12,
              ) +
                  1
          ) /
              2;

      paint
        ..style =
            PaintingStyle.stroke
        ..strokeWidth =
            2 +
                pulse
        ..color =
        const Color(
          0xFFFFA640,
        ).withValues(
          alpha:
          0.55,
        );

      canvas.drawCircle(
        player,
        36 +
            pulse *
                3,
        paint,
      );
    }

    paint
      ..style =
          PaintingStyle.fill
      ..maskFilter =
      null;
  }

  // ============================================================
  // PLAYER BALL
  // ============================================================

  void _drawPlayerBall(
      Canvas canvas,
      Paint paint,
      Offset player,
      ) {
    final pulse =
        (
            sin(
              _floorOffset *
                  0.06,
            ) +
                1
        ) /
            2;

    // ----------------------------------------------------------
    // MOTION TRAIL
    // ----------------------------------------------------------

    final trailColor =
    rushZoneActive
        ? const Color(
      0xFFFFA640,
    )
        : ballColor;

    for (var i = 5;
    i >= 1;
    i--) {
      double trailAlpha =
          0.17 *
              (
                  1 -
                      i /
                          6
              );

      if (rushZoneActive) {
        trailAlpha *= 1.7;
      }

      paint
        ..style = PaintingStyle.fill
        ..maskFilter = null
        ..color =
        trailColor.withValues(
          alpha:
          trailAlpha.clamp(
            0.0,
            1.0,
          ),
        );

      canvas.drawCircle(
        player +
            Offset(
              0,
              i * 8.5,
            ),
        ballRadius *
            (
                1 -
                    i /
                        7
            ),
        paint,
      );
    }

    if (_dashTime < dashDuration ||
        _dashFxTime > 0) {
      final direction =
          (
              _dashTargetX -
                  _dashStartX
          ).sign;

      final strength =
      max(
        _dashFxTime /
            0.20,
        1 -
            (
                _dashTime /
                    dashDuration
            ).clamp(
              0.0,
              1.0,
            ),
      ).clamp(
        0.0,
        1.0,
      );

      for (var i = 1;
      i <= 5;
      i++) {
        paint.color =
            trailColor.withValues(
              alpha:
              0.14 *
                  strength *
                  (
                      1 -
                          i /
                              6
                  ),
            );

        canvas.drawCircle(
          player.translate(
            -direction *
                i *
                10,
            i *
                1.3,
          ),
          ballRadius *
              (
                  1 -
                      i *
                          0.10
              ),
          paint,
        );
      }

      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color =
        trailColor.withValues(
          alpha:
          0.34 *
              strength,
        );

      canvas.drawLine(
        player.translate(
          -direction * 12,
          0,
        ),
        player.translate(
          -direction * 46,
          2,
        ),
        paint,
      );

      paint.style =
          PaintingStyle.fill;
    }

    // ----------------------------------------------------------
    // BALL GLOW
    // ----------------------------------------------------------

    paint
      ..style =
          PaintingStyle.fill
      ..color =
      ballColor.withValues(
        alpha:
        0.28 +
            pulse *
                0.12,
      )
      ..maskFilter =
      const MaskFilter.blur(
        BlurStyle.normal,
        12,
      );

    canvas.drawCircle(
      player,
      20 +
          pulse *
              3,
      paint,
    );

    paint.maskFilter =
    null;

    // ----------------------------------------------------------
    // BALL STYLE
    // ----------------------------------------------------------

    switch (ballStyleId) {
      case 'inferno':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint.color =
        const Color(
          0xFFFFC04A,
        );

        canvas.drawCircle(
          player.translate(
            0,
            2,
          ),
          7,
          paint,
        );

        paint.color =
        const Color(
          0xFFFFF0A6,
        );

        canvas.drawCircle(
          player.translate(
            -2,
            -2,
          ),
          3.5,
          paint,
        );

        paint.color =
            ballColor.withValues(
              alpha:
              0.65,
            );

        canvas.drawCircle(
          player.translate(
            -5,
            17,
          ),
          5,
          paint,
        );

        canvas.drawCircle(
          player.translate(
            5,
            20,
          ),
          3.5,
          paint,
        );

        break;

      case 'volt':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          2
          ..color =
          const Color(
            0xFFFFFFFF,
          );

        final bolt =
        Path()
          ..moveTo(
            player.dx -
                3,
            player.dy -
                9,
          )
          ..lineTo(
            player.dx +
                2,
            player.dy -
                2,
          )
          ..lineTo(
            player.dx -
                1,
            player.dy -
                2,
          )
          ..lineTo(
            player.dx +
                4,
            player.dy +
                9,
          );

        canvas.drawPath(
          bolt,
          paint,
        );

        break;

      case 'crystal':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        final crystal =
        Path();

        for (var i = 0;
        i < 6;
        i++) {
          final angle =
              -pi /
                  2 +
                  i *
                      pi /
                      3;

          final point =
              player +
                  Offset(
                    cos(
                      angle,
                    ),
                    sin(
                      angle,
                    ),
                  ) *
                      ballRadius;

          if (i == 0) {
            crystal.moveTo(
              point.dx,
              point.dy,
            );
          } else {
            crystal.lineTo(
              point.dx,
              point.dy,
            );
          }
        }

        crystal.close();

        canvas.drawPath(
          crystal,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          1.5
          ..color =
          const Color(
            0xFFFFFFFF,
          ).withValues(
            alpha:
            0.65,
          );

        canvas.drawLine(
          player.translate(
            0,
            -9,
          ),
          player.translate(
            -5,
            5,
          ),
          paint,
        );

        canvas.drawLine(
          player.translate(
            0,
            -9,
          ),
          player.translate(
            6,
            4,
          ),
          paint,
        );

        break;

      case 'galaxy':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFF371153,
          );

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          3
          ..color =
              ballColor;

        canvas.drawArc(
          Rect.fromCircle(
            center:
            player,
            radius:
            9,
          ),
          -0.4,
          4.7,
          false,
          paint,
        );

        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFFFFFFFF,
          );

        canvas.drawCircle(
          player.translate(
            5,
            -5,
          ),
          2,
          paint,
        );

        canvas.drawCircle(
          player.translate(
            -4,
            4,
          ),
          1.3,
          paint,
        );

        break;

      case 'shadow':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFF222738,
          );

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          2
          ..color =
          ballColor.withValues(
            alpha:
            0.8,
          );

        canvas.drawCircle(
          player,
          ballRadius -
              1,
          paint,
        );

        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFFDEE4FF,
          ).withValues(
            alpha:
            0.8,
          );

        canvas.drawCircle(
          player.translate(
            -4,
            -4,
          ),
          2.5,
          paint,
        );

        break;

      case 'neon':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFF09271A,
          );

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          3
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius -
              2,
          paint,
        );

        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          4,
          paint,
        );

        break;

      case 'ice':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          1.5
          ..color =
          const Color(
            0xFFFFFFFF,
          ).withValues(
            alpha:
            0.88,
          );

        for (var i = 0;
        i < 3;
        i++) {
          final angle =
              i *
                  pi /
                  3;

          final direction =
          Offset(
            cos(
              angle,
            ),
            sin(
              angle,
            ),
          );

          canvas.drawLine(
            player -
                direction *
                    8,
            player +
                direction *
                    8,
            paint,
          );
        }

        break;

      case 'gold':
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          2
          ..color =
          const Color(
            0xFFFFF1A8,
          );

        canvas.drawCircle(
          player,
          ballRadius -
              3,
          paint,
        );

        paint
          ..style =
              PaintingStyle.fill
          ..color =
          const Color(
            0xFFFFF7C7,
          );

        canvas.drawCircle(
          player.translate(
            -4,
            -4,
          ),
          3,
          paint,
        );

        break;

      case 'plasma':
      default:
        paint
          ..style =
              PaintingStyle.fill
          ..color =
              ballColor;

        canvas.drawCircle(
          player,
          ballRadius,
          paint,
        );

        paint.color =
        const Color(
          0xFFFFFFFF,
        );

        canvas.drawCircle(
          player,
          5,
          paint,
        );

        paint
          ..style =
              PaintingStyle.stroke
          ..strokeWidth =
          1.5
          ..color =
          const Color(
            0xFFFFFFFF,
          ).withValues(
            alpha:
            0.55,
          );

        canvas.drawCircle(
          player,
          8,
          paint,
        );

        break;
    }

    _drawPowerUpEffects(
      canvas,
      paint,
      player,
    );

    paint
      ..style =
          PaintingStyle.fill
      ..maskFilter =
      null;
  }

  // ============================================================
  // START HINT
  // ============================================================

  void _drawStartHint(
      Canvas canvas,
      ) {
    if (_hasDashed ||
        _runTime > 4.5) {
      return;
    }

    double alpha = 1;

    if (_runTime > 3) {
      alpha =
          (
              1 -
                  (
                      _runTime -
                          3
                  ) /
                      1.5
          ).clamp(
            0.0,
            1.0,
          );
    }

    final title =
    TextPainter(
      text:
      TextSpan(
        text:
        'TAP TO SWITCH LANES',
        style:
        TextStyle(
          color:
          const Color(
            0xFFFFFFFF,
          ).withValues(
            alpha:
            alpha,
          ),
          fontSize:
          16,
          fontWeight:
          FontWeight.w900,
          letterSpacing:
          1.6,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    );

    title.layout();

    final subtitle =
    TextPainter(
      text:
      TextSpan(
        text:
        'Dodge • collect • grab power-ups',
        style:
        TextStyle(
          color:
          const Color(
            0xFFB7C9E7,
          ).withValues(
            alpha:
            alpha *
                0.9,
          ),
          fontSize:
          11,
          fontWeight:
          FontWeight.w600,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    );

    subtitle.layout();

    final centerY =
        _height *
            0.51;

    title.paint(
      canvas,
      Offset(
        (
            logicalWidth -
                title.width
        ) /
            2,
        centerY,
      ),
    );

    subtitle.paint(
      canvas,
      Offset(
        (
            logicalWidth -
                subtitle.width
        ) /
            2,
        centerY +
            25,
      ),
    );
  }

  // ============================================================
  // EVENT POPUP
  // ============================================================

  void _drawRushEvent(
      Canvas canvas,
      Paint paint,
      ) {
    if (!showRushEvent) {
      return;
    }

    final event =
        rushEvent;

    if (event == null) {
      return;
    }

    final progress =
    (
        rushEventTime /
            1.3
    ).clamp(
      0.0,
      1.0,
    );

    Color color =
    const Color(
      0xFF53EAFF,
    );

    if (event.startsWith(
      'NEAR',
    )) {
      color =
      const Color(
        0xFFFFD45A,
      );
    } else if (
    event.contains(
      'SHIELD',
    )) {
      color =
      const Color(
        0xFF53EAFF,
      );
    } else if (
    event.contains(
      'MAGNET',
    )) {
      color =
      const Color(
        0xFF65F2B5,
      );
    } else if (
    event.contains(
      'SLOW',
    )) {
      color =
      const Color(
        0xFFB76CFF,
      );
    } else if (
    event.contains(
      'RUSH',
    )) {
      color =
      const Color(
        0xFFFFA640,
      );
    } else if (
    event.contains(
      'REACHED',
    )) {
      color =
      const Color(
        0xFFFFD45A,
      );
    }

    final pulse =
        1 +
            sin(
              progress *
                  pi,
            ) *
                0.08;

    final painter =
    TextPainter(
      text:
      TextSpan(
        text:
        event,
        style:
        TextStyle(
          color:
          color.withValues(
            alpha:
            progress,
          ),
          fontSize:
          21 *
              pulse,
          fontWeight:
          FontWeight.w900,
          letterSpacing:
          1.3,
        ),
      ),
      textDirection:
      TextDirection.ltr,
    );

    painter.layout();

    final y =
        _height *
            0.40 -
            (
                1 -
                    progress
            ) *
                12;

    paint
      ..style =
          PaintingStyle.fill
      ..maskFilter =
      const MaskFilter.blur(
        BlurStyle.normal,
        18,
      )
      ..color =
      color.withValues(
        alpha:
        0.16 *
            progress,
      );

    canvas.drawCircle(
      Offset(
        logicalWidth /
            2,
        y +
            10,
      ),
      55,
      paint,
    );

    paint.maskFilter =
    null;

    painter.paint(
      canvas,
      Offset(
        (
            logicalWidth -
                painter.width
        ) /
            2,
        y,
      ),
    );
  }

  // ============================================================
  // RENDER
  // ============================================================

  @override
  void render(
      Canvas canvas,
      ) {
    super.render(canvas);

    if (size.x <= 0 ||
        size.y <= 0) {
      return;
    }

    canvas.save();

    canvas.scale(
      _scale,
    );

    if (_screenShakeTime > 0) {
      final shakeProgress =
      (
          _screenShakeTime /
              0.24
      ).clamp(
        0.0,
        1.0,
      );

      final shake =
          _screenShakeMagnitude *
              shakeProgress;

      final shakeClock =
          _runTime +
              _impactTime;

      canvas.translate(
        sin(
          shakeClock *
              91,
        ) *
            shake,
        cos(
          shakeClock *
              73,
        ) *
            shake *
            0.62,
      );
    }

    final paint =
    Paint();

    // ----------------------------------------------------------
    // BACKGROUND
    // ----------------------------------------------------------

    _drawMapScenery(
      canvas,
      paint,
    );

    _drawSpeedEffects(
      canvas,
      paint,
    );

    // ----------------------------------------------------------
    // TRACK
    // ----------------------------------------------------------

    paint
      ..style =
          PaintingStyle.fill
      ..maskFilter =
      null
      ..color =
          mapStyle.floor;

    canvas.drawRect(
      Rect.fromLTWH(
        40,
        0,
        280,
        _height,
      ),
      paint,
    );

    // Floor horizontal movement.
    paint
      ..color =
      mapStyle.edge
          .withValues(
        alpha:
        0.18,
      )
      ..strokeWidth =
      1;

    for (double y =
        _floorOffset -
            80;
    y <
        _height;
    y +=
    80) {
      canvas.drawLine(
        Offset(
          40,
          y,
        ),
        Offset(
          320,
          y,
        ),
        paint,
      );
    }

    // Middle divider.
    paint.color =
        mapStyle.edge
            .withValues(
          alpha:
          0.14,
        );

    canvas.drawLine(
      const Offset(
        180,
        0,
      ),
      Offset(
        180,
        _height,
      ),
      paint,
    );

    _drawRoadFlow(
      canvas,
      paint,
    );

    _drawSideRails(
      canvas,
      paint,
    );

    // IMPORTANT:
    // Rush effect is drawn AFTER the road,
    // so the orange effect is actually visible.
    _drawRushZoneEffect(
      canvas,
      paint,
    );

    // ----------------------------------------------------------
    // HAZARDS + COINS
    // ----------------------------------------------------------

    for (final row
    in _rows) {
      if (row.y <
          -35 ||
          row.y >
              _height +
                  35) {
        continue;
      }

      _drawHazard(
        canvas,
        paint,
        row,
      );

      if (row.hasCoin) {
        // Coin glow.
        paint
          ..style =
              PaintingStyle.fill
          ..maskFilter =
          const MaskFilter.blur(
            BlurStyle.normal,
            7,
          )
          ..color =
          const Color(
            0xFFFFC64A,
          ).withValues(
            alpha:
            0.40,
          );

        canvas.drawCircle(
          row.coinPosition,
          14,
          paint,
        );

        // Coin body.
        paint
          ..maskFilter =
          null
          ..color =
          const Color(
            0xFFFFC64A,
          );

        canvas.drawCircle(
          row.coinPosition,
          9,
          paint,
        );

        paint.color =
        const Color(
          0xFFFFEAB0,
        );

        canvas.drawCircle(
          row.coinPosition,
          4,
          paint,
        );
      }
    }

    // ----------------------------------------------------------
    // SKILL COINS
    // ----------------------------------------------------------

    for (final skillCoin in _skillCoins) {
      if (skillCoin.collected ||
          skillCoin.y < -40 ||
          skillCoin.y > _height + 40) {
        continue;
      }

      _drawSkillCoin(
        canvas,
        paint,
        skillCoin,
      );
    }

    // ----------------------------------------------------------
    // POWER-UP PICKUPS
    // ----------------------------------------------------------

    for (final powerUp
    in _powerUps) {
      if (powerUp.collected ||
          powerUp.y <
              -40 ||
          powerUp.y >
              _height +
                  40) {
        continue;
      }

      _drawPowerUp(
        canvas,
        paint,
        powerUp,
      );
    }

    _drawParticles(
      canvas,
      paint,
    );

    // ----------------------------------------------------------
    // PLAYER
    // ----------------------------------------------------------

    final player =
    Offset(
      _ballX,
      _ballY,
    );

    if (state ==
        RunState.impact) {
      final progress =
      (
          _impactTime /
              0.4
      ).clamp(
        0.0,
        1.0,
      );

      paint
        ..style =
            PaintingStyle.fill
        ..maskFilter =
        null
        ..color =
        ballColor.withValues(
          alpha:
          1 -
              progress,
        );

      for (var i = 0;
      i < 12;
      i++) {
        final angle =
            i *
                pi *
                2 /
                12;

        canvas.drawCircle(
          player +
              Offset(
                cos(
                  angle,
                ),
                sin(
                  angle,
                ),
              ) *
                  (
                      progress *
                          70
                  ),
          4 *
              (
                  1 -
                      progress
              ),
          paint,
        );
      }
    } else if (
    state !=
        RunState.gameOver) {
      _drawPlayerBall(
        canvas,
        paint,
        player,
      );
    }

    // ----------------------------------------------------------
    // GAMEPLAY FEEDBACK
    // ----------------------------------------------------------

    _drawRushEvent(
      canvas,
      paint,
    );

    _drawStartHint(
      canvas,
    );

    _drawScreenFlash(
      canvas,
      paint,
    );

    canvas.restore();
  }
}
