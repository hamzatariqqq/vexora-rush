import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ad_service.dart';
import '../services/storage_service.dart';

class RewardShopScreen extends StatefulWidget {
  const RewardShopScreen({
    super.key,
    required this.storage,
    required this.ads,
  });

  final StorageService storage;
  final AdService ads;

  @override
  State<RewardShopScreen> createState() => _RewardShopScreenState();
}

class _RewardShopScreenState extends State<RewardShopScreen> {
  bool _loading = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();

    _ticker = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _watchAd() async {
    if (_loading || !widget.storage.canWatchForCoins) {
      return;
    }

    setState(() => _loading = true);

    final earned = await widget.ads.showRewarded();

    var credited = false;

    if (earned) {
      credited =
      await widget.storage.creditRewardedCoins();
    }

    if (!mounted) return;

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          credited
              ? '+100 coins added to your balance!'
              : earned
              ? 'Reward could not be credited.'
              : 'Ad was not completed. No reward was used.',
        ),
      ),
    );
  }

  String _formatWait(Duration duration) {
    final totalSeconds = duration.inSeconds;

    final minutes =
    (totalSeconds ~/ 60)
        .toString()
        .padLeft(2, '0');

    final seconds =
    (totalSeconds % 60)
        .toString()
        .padLeft(2, '0');

    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, child) {
        final storage = widget.storage;

        final wait =
            storage.adWaitRemaining;

        final rewardsUsed =
            storage.currentAdRewards;

        final rewardsLeft =
            StorageService.maxAdRewardsPerDay -
                rewardsUsed;

        final dailyLimitReached =
            rewardsUsed >=
                StorageService.maxAdRewardsPerDay;

        final canWatch =
            storage.canWatchForCoins &&
                !_loading;

        String statusTitle;
        String statusText;

        if (dailyLimitReached) {
          statusTitle = 'DAILY LIMIT REACHED';
          statusText =
          'You have claimed all 3 rewarded bonuses today.';
        } else if (wait > Duration.zero) {
          statusTitle = 'REWARD COOLDOWN';
          statusText =
          'Next rewarded ad available in ${_formatWait(wait)}';
        } else {
          statusTitle = 'REWARD READY';
          statusText =
          '$rewardsLeft reward${rewardsLeft == 1 ? '' : 's'} remaining today.';
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'REWARD SHOP',
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
              _CoinBalance(
                coins: storage.coins,
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF172746),
                      Color(0xFF111A32),
                    ],
                  ),
                  borderRadius:
                  BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(
                      0xFF2E456D,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF53EAFF,
                      ).withValues(
                        alpha: 0.08,
                      ),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(
                          0xFF53EAFF,
                        ).withValues(
                          alpha: 0.10,
                        ),
                        border: Border.all(
                          color: const Color(
                            0xFF53EAFF,
                          ).withValues(
                            alpha: 0.38,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF53EAFF,
                            ).withValues(
                              alpha: 0.18,
                            ),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons
                            .play_circle_fill_rounded,
                        size: 53,
                        color: Color(
                          0xFF53EAFF,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'WATCH & EARN',
                      style: TextStyle(
                        color: Color(
                          0xFF91A6C9,
                        ),
                        fontSize: 12,
                        fontWeight:
                        FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      '100 COINS',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight:
                        FontWeight.w900,
                        color: Color(
                          0xFFFFD166,
                        ),
                        letterSpacing: 1,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Complete an optional rewarded ad to receive 100 coins.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(
                          0xFFA8B8D3,
                        ),
                        height: 1.45,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        onPressed:
                        canWatch
                            ? _watchAd
                            : null,
                        icon: _loading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(
                          Icons
                              .play_arrow_rounded,
                        ),
                        label: Text(
                          _loading
                              ? 'LOADING AD...'
                              : dailyLimitReached
                              ? 'DAILY LIMIT REACHED'
                              : wait >
                              Duration.zero
                              ? 'COOLDOWN ACTIVE'
                              : 'WATCH AD • +100 COINS',
                          style: const TextStyle(
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style:
                        FilledButton.styleFrom(
                          backgroundColor:
                          const Color(
                            0xFF53EAFF,
                          ),
                          foregroundColor:
                          const Color(
                            0xFF07111E,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              _DailyRewardsCard(
                rewardsUsed: rewardsUsed,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF121B34,
                  ),
                  borderRadius:
                  BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(
                      0xFF273755,
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                      BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                        _statusColor(
                          dailyLimitReached,
                          wait,
                        ).withValues(
                          alpha: 0.12,
                        ),
                      ),
                      child: Icon(
                        _statusIcon(
                          dailyLimitReached,
                          wait,
                        ),
                        color:
                        _statusColor(
                          dailyLimitReached,
                          wait,
                        ),
                        size: 21,
                      ),
                    ),

                    const SizedBox(width: 13),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            statusTitle,
                            style:
                            TextStyle(
                              fontSize: 13,
                              fontWeight:
                              FontWeight
                                  .w900,
                              letterSpacing:
                              0.7,
                              color:
                              _statusColor(
                                dailyLimitReached,
                                wait,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            statusText,
                            style:
                            const TextStyle(
                              color: Color(
                                0xFF9CAECD,
                              ),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFF10182D,
                  ),
                  borderRadius:
                  BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 19,
                          color: Color(
                            0xFF8297BB,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'HOW REWARDS WORK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w900,
                            letterSpacing: 1,
                            color: Color(
                              0xFF9FB1CF,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 13),
                    _InfoRow(
                      text:
                      'Each completed rewarded ad gives 100 coins.',
                    ),
                    _InfoRow(
                      text:
                      'Maximum 3 rewarded coin bonuses per day.',
                    ),
                    _InfoRow(
                      text:
                      'There is a 20-minute cooldown between rewards.',
                    ),
                    _InfoRow(
                      text:
                      'Watching ads is completely optional.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Watch optional rewarded ads to earn bonus coins.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(
                    0xFF667A9D,
                  ),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(
      bool limitReached,
      Duration wait,
      ) {
    if (limitReached) {
      return const Color(
        0xFFFF6C91,
      );
    }

    if (wait > Duration.zero) {
      return const Color(
        0xFFFFC64A,
      );
    }

    return const Color(
      0xFF65E3A7,
    );
  }

  IconData _statusIcon(
      bool limitReached,
      Duration wait,
      ) {
    if (limitReached) {
      return Icons.block_rounded;
    }

    if (wait > Duration.zero) {
      return Icons.timer_rounded;
    }

    return Icons.check_circle_rounded;
  }
}

class _CoinBalance extends StatelessWidget {
  const _CoinBalance({
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
        borderRadius:
        BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFF2C4267,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
            const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFFFFC64A,
              ),
            ),
            child: const Icon(
              Icons.monetization_on_rounded,
              color: Color(
                0xFF6E4A00,
              ),
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR BALANCE',
                  style: TextStyle(
                    color: Color(
                      0xFF91A6C9,
                    ),
                    fontSize: 11,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Spend coins on balls and maps',
                  style: TextStyle(
                    color: Color(
                      0xFF7184A6,
                    ),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
              FontWeight.w900,
              color: Color(
                0xFFFFD166,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRewardsCard
    extends StatelessWidget {
  const _DailyRewardsCard({
    required this.rewardsUsed,
  });

  final int rewardsUsed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(
          0xFF121B34,
        ),
        borderRadius:
        BorderRadius.circular(20),
        border: Border.all(
          color: const Color(
            0xFF273755,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'DAILY REWARDS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                    FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Text(
                '$rewardsUsed / ${StorageService.maxAdRewardsPerDay}',
                style: const TextStyle(
                  color: Color(
                    0xFF9FB2D1,
                  ),
                  fontSize: 12,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: List.generate(
              StorageService
                  .maxAdRewardsPerDay,
                  (index) {
                final claimed =
                    index < rewardsUsed;

                return Expanded(
                  child: Padding(
                    padding:
                    EdgeInsets.only(
                      right: index <
                          StorageService
                              .maxAdRewardsPerDay -
                              1
                          ? 8
                          : 0,
                    ),
                    child: Container(
                      height: 58,
                      decoration:
                      BoxDecoration(
                        color: claimed
                            ? const Color(
                          0xFF65E3A7,
                        ).withValues(
                          alpha: 0.12,
                        )
                            : const Color(
                          0xFF1B2742,
                        ),
                        borderRadius:
                        BorderRadius
                            .circular(
                          13,
                        ),
                        border: Border.all(
                          color: claimed
                              ? const Color(
                            0xFF65E3A7,
                          ).withValues(
                            alpha: 0.55,
                          )
                              : const Color(
                            0xFF33415D,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .center,
                        children: [
                          Icon(
                            claimed
                                ? Icons
                                .check_circle_rounded
                                : Icons
                                .play_circle_outline_rounded,
                            size: 20,
                            color: claimed
                                ? const Color(
                              0xFF65E3A7,
                            )
                                : const Color(
                              0xFF7588A9,
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Text(
                            '+100',
                            style:
                            TextStyle(
                              fontSize: 11,
                              fontWeight:
                              FontWeight
                                  .w900,
                              color: claimed
                                  ? const Color(
                                0xFF65E3A7,
                              )
                                  : const Color(
                                0xFF8B9DBC,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
      const EdgeInsets.only(
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          const Padding(
            padding:
            EdgeInsets.only(
              top: 4,
            ),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Color(
                0xFF53EAFF,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(
                  0xFF91A4C5,
                ),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}