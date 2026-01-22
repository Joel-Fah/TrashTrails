import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';

import '../../../models/leaderboard.dart';
import '../../../utils/constants.dart';
import '../../../utils/utils.dart';
import '../user_avatar.dart';

/// Podium widget displaying top 3 users
class LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntryModel> topThree;
  final bool isLoading;

  const LeaderboardPodium({
    super.key,
    required this.topThree,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (topThree.isEmpty) {
      return _buildEmptyState();
    }

    // Arrange entries: [2nd (Silver), 1st (Gold), 3rd (Bronze)]
    final first = topThree.isNotEmpty ? topThree[0] : null;
    final second = topThree.length > 1 ? topThree[1] : null;
    final third = topThree.length > 2 ? topThree[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        spacing: 8.0,
        children: [
          // 2nd place (Silver)
          if (second != null)
            Expanded(
              child: _buildPodiumItem(
                context: context,
                entry: second,
                rank: 2,
                height: 160.0,
                delay: 200.ms,
              ),
            ),
          if (second != null) const Gap(12.0),

          // 1st place (Gold) - Tallest
          if (first != null)
            Expanded(
              child: _buildPodiumItem(
                context: context,
                entry: first,
                rank: 1,
                height: 200.0,
                delay: 0.ms,
              ),
            ),
          if (first != null && third != null) const Gap(12.0),

          // 3rd place (Bronze)
          if (third != null)
            Expanded(
              child: _buildPodiumItem(
                context: context,
                entry: third,
                rank: 3,
                height: 120.0,
                delay: 400.ms,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumItem({
    required BuildContext context,
    required LeaderboardEntryModel entry,
    required int rank,
    required double height,
    required Duration delay,
  }) {
    final medalColor = _getMedalColor(rank);
    final medalImg = _getMedalImage(rank);
    final isFirst = rank == 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with crown for first place
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    medalColor.withValues(alpha: 0.3),
                    medalColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: medalColor,
                  width: isFirst ? 3.0 : 2.0,
                ),
              ),
              child: UserAvatar(
                imageUrl: entry.avatar,
                name: entry.displayName,
                radius: isFirst ? 40.0 : 30.0,
              ),
            ),
            if (isFirst)
              Positioned(
                top: -36,
                left: 0,
                right: -40,
                child: Transform.rotate(
                  angle: 20.0 * pi / 180.0,
                  child: Image.asset(crown, height: 70)
                      .animate()
                      .scale(delay: delay + 300.ms, duration: 300.ms)
                      .then()
                      .shake(hz: 2, duration: 500.ms),
                ),
              ),
          ],
        ).animate().scale(
          delay: delay,
          duration: 400.ms,
          curve: Curves.elasticOut,
        ),

        const Gap(8.0),

        // Username
        Text(
          entry.displayName,
          style: AppTextStyles.h3.copyWith(
            color: darkColor,
            fontWeight: FontWeight.w500,
            fontVariations: [FontVariation('wght', 500)],
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ).animate().fadeIn(delay: delay + 100.ms, duration: 300.ms),

        // Points
        Text(
          '${formatCount(entry.points)} pts',
          style: AppTextStyles.body.copyWith(
            color: successColor,
            fontVariations: [FontVariation('wght', 600)],
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: delay + 200.ms, duration: 300.ms),

        const Gap(12.0),

        // Podium stand
        Container(
              height: height,
              constraints: BoxConstraints(maxWidth: 96.0),
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: medalColor.withValues(alpha: 0.16),
                    blurRadius: 60.0,
                    spreadRadius: 5,
                  ),
                ],
                gradient: LinearGradient(
                  colors: [
                    medalColor.withValues(alpha: 0.6),
                    medalColor.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: borderRadius * 4.5,
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Image.asset(medalImg, width: 64.0)),
                      Text(
                        '#$rank',
                        style: AppTextStyles.h1.copyWith(
                          fontVariations: [FontVariation('wght', 600)],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .animate()
            .slideY(
              begin: 1,
              end: 0,
              delay: delay + 300.ms,
              duration: 500.ms,
              curve: Curves.easeOutBack,
            )
            .fadeIn(delay: delay + 300.ms, duration: 300.ms),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildLoadingPodiumItem(100),
          const Gap(12.0),
          _buildLoadingPodiumItem(140),
          const Gap(12.0),
          _buildLoadingPodiumItem(80),
        ],
      ),
    );
  }

  Widget _buildLoadingPodiumItem(double height) {
    final baseColor = Colors.grey.shade300;

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
                width: 60.0,
                height: 60.0,
                decoration: BoxDecoration(
                  color: baseColor,
                  shape: BoxShape.circle,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms),
          const Gap(8.0),
          Container(
                height: 14.0,
                width: 80.0,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, delay: 100.ms),
          const Gap(4.0),
          Container(
                height: 12.0,
                width: 60.0,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, delay: 200.ms),
          const Gap(12.0),
          Container(
                height: height,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: borderRadius * 4.0,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms, delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(ranking, width: 300.0).animate().scale(duration: 300.ms),
          const Gap(16.0),
          Text(
            "No Leaders Yet",
            style: AppTextStyles.h1.copyWith(
              fontWeight: FontWeight.w400,
              fontVariations: [FontVariation('wght', 400)],
              fontStyle: FontStyle.italic,
            ),
          ).animate().fadeIn(delay: 100.ms),
        ],
      ),
    );
  }

  Color _getMedalColor(int rank) {
    switch (rank) {
      case 1:
        return gold;
      case 2:
        return silver;
      case 3:
        return bronze;
      default:
        return Colors.grey;
    }
  }

  String _getMedalImage(int rank) {
    switch (rank) {
      case 1:
        return goldImg;
      case 2:
        return silverImg;
      case 3:
        return bronzeImg;
      default:
        return goldImg;
    }
  }
}
