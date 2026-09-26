import 'dart:math';
import 'dart:ui';

enum HazardKind {
  barrier,
  laser,
  spikes,
  blade,
  movingGate,
}

class TrackRow {
  TrackRow({
    required this.y,
    required this.blockedLane,
    required this.hasCoin,
    this.kind = HazardKind.barrier,
  });

  double y;
  final int blockedLane;
  bool hasCoin;
  final HazardKind kind;

  double animationTime = 0;
  bool countedAsDodged = false;

  double get laneCenter => blockedLane == 0 ? 110 : 250;

  Offset get coinPosition => Offset(
    blockedLane == 0 ? 250 : 110,
    y,
  );

  Offset get bladeCenter => Offset(
    laneCenter + sin(animationTime * 2.4) * 18,
    y,
  );

  Rect get hazardRect {
    switch (kind) {
      case HazardKind.barrier:
        return Rect.fromCenter(
          center: Offset(laneCenter, y),
          width: 124,
          height: 20,
        );

      case HazardKind.laser:
        return Rect.fromCenter(
          center: Offset(laneCenter, y),
          width: 124,
          height: 12,
        );

      case HazardKind.spikes:
        return Rect.fromCenter(
          center: Offset(laneCenter, y),
          width: 120,
          height: 24,
        );

      case HazardKind.blade:
        return Rect.fromCircle(
          center: bladeCenter,
          radius: 19,
        );

      case HazardKind.movingGate:
        return Rect.fromCenter(
          center: Offset(
            laneCenter + sin(animationTime * 2.8) * 17,
            y,
          ),
          width: 94,
          height: 22,
        );
    }
  }

  void advance(double dt, double movement) {
    y += movement;
    animationTime += dt;
  }

  bool touches(Offset player, double playerRadius) {
    if (kind == HazardKind.blade) {
      final combinedRadius = playerRadius + 19;
      return (player - bladeCenter).distanceSquared <=
          combinedRadius * combinedRadius;
    }

    return circleTouchesRect(player, playerRadius, hazardRect);
  }
}

bool circleTouchesRect(Offset center, double radius, Rect rect) {
  final closestX = center.dx.clamp(rect.left, rect.right).toDouble();
  final closestY = center.dy.clamp(rect.top, rect.bottom).toDouble();

  final dx = center.dx - closestX;
  final dy = center.dy - closestY;

  return dx * dx + dy * dy <= radius * radius;
}