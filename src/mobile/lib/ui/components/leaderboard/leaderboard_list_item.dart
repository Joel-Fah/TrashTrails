import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trashtrails/utils/constants.dart';

import '../../../models/leaderboard.dart';
import '../../../utils/utils.dart';
import '../user_avatar.dart';

/// List item widget for leaderboard entries
class LeaderboardListItem extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final bool isCurrentUser;
  final int index;

  const LeaderboardListItem({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final isTopThree = entry.rank <= 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        spacing: 16.0,
        children: [
          // Rank badge
          Container(
            width: 40.0,
            height: 40.0,
            alignment: Alignment.center,
            child: isTopThree
                ? Image.asset(_getMedalImage(entry.rank), width: 40.0)
                : Text(
                    entry.rank.toString().length == 1
                        ? '0${entry.rank}'
                        : '${entry.rank}',
                    style: AppTextStyles.h1,
                  ),
          ).animate().scale(delay: (index * 50).ms, duration: 300.ms),
          Expanded(
            child:
                ListTile(
                      selected: isCurrentUser,
                      selectedTileColor: seedPalette.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 4.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius * 3.0,
                        side: BorderSide(color: seedColor),
                      ),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Avatar
                          UserAvatar(
                            imageUrl: entry.avatar,
                            name: entry.displayName,
                            radius: 24.0,
                          ).animate().fadeIn(
                            delay: (index * 50 + 100).ms,
                            duration: 300.ms,
                          ),
                        ],
                      ),
                      title: Row(
                        spacing: 8.0,
                        children: [
                          Text(
                            entry.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (isCurrentUser)
                            Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: seedColor,
                                    borderRadius: borderRadius,
                                  ),
                                  child: Text(
                                    'You',
                                    style: AppTextStyles.small.copyWith(
                                      color: lightColor,
                                      fontSize: 10.0,
                                      fontVariations: [
                                        FontVariation('wght', 500),
                                      ],
                                    ),
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: (index * 50 + 200).ms)
                                .scale(delay: (index * 50 + 200).ms),
                        ],
                      ),
                      subtitle: Text(
                        '${entry.totalReports} reports',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 14.0,
                          color: darkColor,
                          fontVariations: [FontVariation('wght', 400)],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatCount(entry.points),
                            style: AppTextStyles.h4.copyWith(
                              color: isTopThree
                                  ? _getMedalColor(entry.rank)
                                  : null,
                              fontVariations: [FontVariation('wght', 600)],
                            ),
                          ),
                          Text(
                            'pts',
                            style: AppTextStyles.small.copyWith(
                              fontVariations: [FontVariation('wght', 500)],
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (index * 50).ms, duration: 300.ms)
                    .slideX(
                      begin: 0.2,
                      end: 0,
                      delay: (index * 50).ms,
                      duration: 300.ms,
                    ),
          ),
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
