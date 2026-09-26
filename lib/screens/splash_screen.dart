import 'dart:math' as math;

import 'package:flutter/material.dart';

class VexoraSplashScreen extends StatefulWidget {
  const VexoraSplashScreen({
    super.key,
    required this.nextScreen,
  });

  final Widget nextScreen;

  @override
  State<VexoraSplashScreen> createState() =>
      _VexoraSplashScreenState();
}

class _VexoraSplashScreenState extends State<VexoraSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _loopController;

  @override
  void initState() {
    super.initState();

    _introController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 3000,
      ),
    )..forward();

    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2200,
      ),
    )..repeat();

    Future.delayed(
      const Duration(
        milliseconds: 3200,
      ),
          () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacement(
          PageRouteBuilder<void>(
            transitionDuration:
            const Duration(
              milliseconds: 600,
            ),
            pageBuilder: (
                context,
                animation,
                secondaryAnimation,
                ) {
              return widget.nextScreen;
            },
            transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
                ) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _introController.dispose();
    _loopController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(
        0xFF020611,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge(
          [
            _introController,
            _loopController,
          ],
        ),
        builder: (
            context,
            child,
            ) {
          final intro =
          Curves.easeOutCubic.transform(
            _introController.value,
          );

          final loop =
              _loopController.value;

          final zoom =
              1.0 +
                  (
                      _introController.value *
                          0.045
                  );

          final glowPulse =
              0.5 +
                  (
                      math.sin(
                        loop *
                            math.pi *
                            2,
                      ) +
                          1
                  ) /
                      2;

          return Stack(
            fit: StackFit.expand,
            children: [
              Transform.scale(
                scale: zoom,
                child: Image.asset(
                  'assets/images/splash_bg.png',
                  fit: BoxFit.fill,
                  alignment:
                  Alignment.center,
                ),
              ),

              Container(
                decoration:
                BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,
                    end:
                    Alignment.bottomCenter,
                    colors: [
                      Colors.black
                          .withValues(
                        alpha: 0.02,
                      ),
                      Colors.transparent,
                      Colors.black
                          .withValues(
                        alpha: 0.08,
                      ),
                    ],
                  ),
                ),
              ),

              CustomPaint(
                painter:
                _SplashParticlePainter(
                  progress: loop,
                ),
              ),

              Positioned(
                top:
                MediaQuery.of(
                  context,
                ).size.height *
                    0.15,
                left:
                MediaQuery.of(
                  context,
                ).size.width *
                    0.14,
                right:
                MediaQuery.of(
                  context,
                ).size.width *
                    0.14,
                child: IgnorePointer(
                  child: Container(
                    height: 240,
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color:
                          const Color(
                            0xFF53EAFF,
                          ).withValues(
                            alpha:
                            0.05 +
                                glowPulse *
                                    0.11,
                          ),
                          blurRadius:
                          95,
                          spreadRadius:
                          18,
                        ),
                        BoxShadow(
                          color:
                          const Color(
                            0xFF8B62FF,
                          ).withValues(
                            alpha:
                            0.03 +
                                glowPulse *
                                    0.07,
                          ),
                          blurRadius:
                          110,
                          spreadRadius:
                          20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity:
                    intro.clamp(
                      0.0,
                      1.0,
                    ),
                    child: CustomPaint(
                      painter:
                      _SpeedStreakPainter(
                        progress:
                        loop,
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 34,
                right: 34,
                bottom: 42,
                child: Opacity(
                  opacity:
                  intro.clamp(
                    0.0,
                    1.0,
                  ),
                  child: Column(
                    children: [
                      Container(
                        height: 5,
                        decoration:
                        BoxDecoration(
                          color:
                          Colors.black
                              .withValues(
                            alpha:
                            0.30,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            20,
                          ),
                          border:
                          Border.all(
                            color:
                            const Color(
                              0xFF53EAFF,
                            ).withValues(
                              alpha:
                              0.28,
                            ),
                          ),
                        ),
                        child: Align(
                          alignment:
                          Alignment
                              .centerLeft,
                          child:
                          FractionallySizedBox(
                            widthFactor:
                            _introController
                                .value
                                .clamp(
                              0.0,
                              1.0,
                            ),
                            child:
                            Container(
                              decoration:
                              BoxDecoration(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  20,
                                ),
                                gradient:
                                const LinearGradient(
                                  colors: [
                                    Color(
                                      0xFF53EAFF,
                                    ),
                                    Color(
                                      0xFF79E6FF,
                                    ),
                                    Color(
                                      0xFF9A63FF,
                                    ),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                    const Color(
                                      0xFF53EAFF,
                                    ).withValues(
                                      alpha:
                                      0.55,
                                    ),
                                    blurRadius:
                                    12,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 9,
                      ),
                      Text(
                        'ENTERING THE RUSH',
                        style:
                        TextStyle(
                          color:
                          Colors.white
                              .withValues(
                            alpha:
                            0.72,
                          ),
                          fontSize: 9,
                          fontWeight:
                          FontWeight
                              .w800,
                          letterSpacing:
                          2.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child:
                  AnimatedOpacity(
                    opacity:
                    intro < 0.12
                        ? 1
                        : 0,
                    duration:
                    const Duration(
                      milliseconds:
                      500,
                    ),
                    child:
                    Container(
                      color:
                      const Color(
                        0xFF020611,
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

class _SplashParticlePainter
    extends CustomPainter {
  const _SplashParticlePainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final random =
    math.Random(27);

    final paint =
    Paint();

    for (
    var i = 0;
    i < 42;
    i++
    ) {
      final x =
          random.nextDouble() *
              size.width;

      final speed =
          0.25 +
              random.nextDouble() *
                  0.75;

      final initialY =
      random.nextDouble();

      final y =
          (
              initialY -
                  progress * speed
          ) %
              1;

      final radius =
          0.6 +
              random.nextDouble() *
                  1.7;

      final alpha =
          0.08 +
              random.nextDouble() *
                  0.28;

      final color =
      i % 7 == 0
          ? const Color(
        0xFF9A63FF,
      )
          : i % 5 == 0
          ? const Color(
        0xFFFF8C42,
      )
          : const Color(
        0xFF53EAFF,
      );

      paint.color =
          color.withValues(
            alpha: alpha,
          );

      canvas.drawCircle(
        Offset(
          x,
          size.height * y,
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _SplashParticlePainter
      oldDelegate,
      ) {
    return oldDelegate.progress !=
        progress;
  }
}

class _SpeedStreakPainter
    extends CustomPainter {
  const _SpeedStreakPainter({
    required this.progress,
  });

  final double progress;

  @override
  void paint(
      Canvas canvas,
      Size size,
      ) {
    final paint =
    Paint()
      ..strokeCap =
          StrokeCap.round;

    final centerX =
        size.width / 2;

    final centerY =
        size.height * 0.33;

    for (
    var i = 0;
    i < 12;
    i++
    ) {
      final phase =
          (
              i / 12 +
                  progress
          ) %
              1;

      final angle =
          -math.pi * 0.82 +
              (
                  i /
                      11
              ) *
                  math.pi *
                  0.64;

      final startDistance =
          40 +
              phase * 80;

      final endDistance =
          startDistance +
              30 +
              phase * 95;

      final start =
      Offset(
        centerX +
            math.cos(
              angle,
            ) *
                startDistance,
        centerY +
            math.sin(
              angle,
            ) *
                startDistance,
      );

      final end =
      Offset(
        centerX +
            math.cos(
              angle,
            ) *
                endDistance,
        centerY +
            math.sin(
              angle,
            ) *
                endDistance,
      );

      paint
        ..strokeWidth =
            0.8 +
                phase * 2.0
        ..color =
        (
            i % 4 == 0
                ? const Color(
              0xFF9A63FF,
            )
                : const Color(
              0xFF53EAFF,
            )
        ).withValues(
          alpha:
          0.04 +
              phase * 0.18,
        );

      canvas.drawLine(
        start,
        end,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _SpeedStreakPainter
      oldDelegate,
      ) {
    return oldDelegate.progress !=
        progress;
  }
}