import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:trashtrails/ui/components/default_snack_bar.dart';
import 'package:trashtrails/ui/pages/reports/new_report.dart';
import 'package:trashtrails/utils/utils.dart';

import '../../../controllers/leaderboard_controller.dart';
import '../../../models/leaderboard.dart';
import '../../../utils/constants.dart';
import '../../components/leaderboard/leaderboard_list_item.dart';
import '../../components/leaderboard/leaderboard_podium.dart';
import '../../components/states/error.dart';

/// Main leaderboard page with podium and rankings
class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  static const String routeName = '/leaderboard';

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardController _controller = Get.find<LeaderboardController>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.loadLeaderboard();
  }

  Future<void> _handleRefresh() async {
    await _controller.refreshAll();
  }

  // dart
  void _showLimitDialog() {
    final theme = Theme.of(context);
    int currentLimit = _controller.limit.value.clamp(10, 50);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ).copyWith(bottom: MediaQuery.paddingOf(context).bottom + 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        spacing: 4.0,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Leaderboard Size', style: AppTextStyles.h2),
                          Text(
                            'How many users would you like to see?',
                            style: AppTextStyles.body.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "Close",
                      onPressed: () => context.pop(),
                      icon: HugeIcon(icon: HugeIcons.strokeRoundedCancel01),
                    ),
                  ],
                ),
                const Gap(24.0),
                // Current value display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Min: 10',
                      style: AppTextStyles.small.copyWith(
                        color: greyColor,
                        fontVariations: [FontVariation('wght', 500)],
                      ),
                    ),
                    Text(
                      '$currentLimit users',
                      style: AppTextStyles.small.copyWith(
                        color: seedColor,
                        fontVariations: [FontVariation('wght', 500)],
                      ),
                    ),
                  ],
                ),
                const Gap(8.0),
                // Slider
                Slider.adaptive(
                  value: currentLimit.toDouble(),
                  min: 10,
                  max: 50,
                  divisions: 8,
                  activeColor: seedColor,
                  inactiveColor: seedPalette.shade100,
                  label: '$currentLimit',
                  onChanged: (value) {
                    setState(() => currentLimit = ((value / 5).round() * 5).clamp(10, 50));
                  },
                ),
                const Gap(16.0),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const Gap(8.0),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          if (currentLimit >= 10) {
                            _controller.changeLimit(currentLimit);
                            context.pop();
                          } else {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                buildSnackBar(
                                  backgroundColor: errorColor,
                                  prefixIcon: HugeIcon(
                                    icon: errorIcon,
                                    color: lightColor,
                                  ),
                                  label: Text("Minimum limit is 10 users"),
                                ),
                              );
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: seedPalette.shade100,
                          foregroundColor: seedColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: borderRadius * 2.75,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                        ),
                        child: Text('Apply'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoadingState =
        _controller.isLoadingLeaderboard.value &&
        !_controller.hasLeaderboardData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.0),
          child: isLoadingState
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: List.generate(
                      4,
                      (index) =>
                          Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 80,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .shimmer(
                                duration: 1500.ms,
                                delay: (index * 100).ms,
                              ),
                    ),
                  ),
                )
              : _buildPeriodFilter(),
        ),
        actions: [
          // Limit adjustment button
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal),
            onPressed: _showLimitDialog,
            tooltip: 'Adjust limit',
          ),
          // Refresh button
          Obx(
            () => IconButton(
              icon: _controller.isLoadingLeaderboard.value
                  ? SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: seedColor,
                      ),
                    )
                  : const HugeIcon(icon: HugeIcons.strokeRoundedRefresh),
              onPressed: _controller.isLoadingLeaderboard.value
                  ? null
                  : _handleRefresh,
              tooltip: 'Refresh',
            ),
          ),
        ],
      ),
      body: Obx(() {
        // Loading state (first load)
        if (isLoadingState) {
          return _buildLoadingState();
        }

        // Error state
        if (_controller.leaderboardError.value.isNotEmpty &&
            !_controller.hasLeaderboardData) {
          return ErrorState(
            title: 'Failed to Load Leaderboard',
            subtitle: _controller.leaderboardError.value,
            onPressed: _handleRefresh,
          );
        }

        // Empty state
        if (!_controller.hasLeaderboardData) {
          return _buildEmptyState();
        }

        // Success state with data
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          child: CustomScrollView(
            slivers: [
              // Period filter chips
              SliverToBoxAdapter(child: const Gap(16.0)),

              // Top 3 Podium
              SliverToBoxAdapter(
                child: LeaderboardPodium(
                  topThree: _controller.topThree,
                  isLoading: false,
                ),
              ),

              // Divider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: seedColor)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'All Rankings',
                          style: AppTextStyles.body.copyWith(color: seedColor),
                        ),
                      ),
                      Expanded(child: Divider(color: seedColor)),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms),
              ),

              const SliverToBoxAdapter(child: Gap(8.0)),

              // All entries list
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: _controller.allEntries.length,
                  (context, index) {
                    final entry = _controller.allEntries[index];
                    final isCurrentUser = _controller.isCurrentUser(
                      entry.userId,
                    );

                    return LeaderboardListItem(
                      index: index,
                      entry: entry,
                      isCurrentUser: isCurrentUser,
                    );
                  },
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: Gap(36.0)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: Obx(
        () => Row(
          spacing: 8.0,
          children: LeaderboardPeriod.values.map((period) {
            final isSelected = _controller.selectedPeriod.value == period;

            return FilterChip(
              selected: isSelected,
              label: Text(period.displayName),
              onSelected: (selected) {
                if (selected) {
                  _controller.changePeriod(period);
                }
              },
              checkmarkColor: seedColor,
              labelStyle: AppTextStyles.small.copyWith(
                color: isSelected ? seedColor : seedPalette.shade400,
                fontVariations: [FontVariation('wght', 500)],
              ),
              shape: RoundedRectangleBorder(borderRadius: borderRadius * 1.75),
              side: BorderSide(
                color: isSelected ? seedColor : seedPalette.shade400,
                width: isSelected ? 1.0 : 0.0,
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        // Podium loading
        SliverToBoxAdapter(
          child: LeaderboardPodium(topThree: const [], isLoading: true),
        ),

        // List loading
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildLoadingListItem(),
            childCount: 5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingListItem() {
    final baseColor = Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        spacing: 16.0,
        children: [
          Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: borderRadius * 1.75,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat())
              .shimmer(duration: 1500.ms),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: borderRadius * 2.5,
              ),
              child: Row(
                children: [
                  Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: baseColor,
                          shape: BoxShape.circle,
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms, delay: 100.ms),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                              height: 14,
                              width: 120,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(duration: 1500.ms, delay: 200.ms),
                        const SizedBox(height: 6),
                        Container(
                              height: 12,
                              width: 80,
                              decoration: BoxDecoration(
                                color: baseColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            )
                            .animate(
                              onPlay: (controller) => controller.repeat(),
                            )
                            .shimmer(duration: 1500.ms, delay: 300.ms),
                      ],
                    ),
                  ),
                  Container(
                        height: 16,
                        width: 60,
                        decoration: BoxDecoration(
                          color: baseColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(duration: 1500.ms, delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
                children: [
                  Image.asset(ranking, width: 300.0),
                  const Gap(8.0),
                  Text(
                    "No Ranking Yet",
                    style: AppTextStyles.h1.copyWith(
                      fontWeight: FontWeight.w400,
                      fontVariations: [FontVariation('wght', 400)],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const Gap(4.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Be a trash talker in the best way: report that dump and let's keep it clean, team! Then brag about it!",
                      style: AppTextStyles.small.copyWith(
                        color: greyColor,
                        fontWeight: FontWeight.w400,
                        fontVariations: [FontVariation('wght', 400)],
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const Gap(16.0),
                  FilledButton.icon(
                    onPressed: () {
                      context.pushNamed(
                        removeLeadingSlash(NewReportPage.routeName),
                      );
                    },
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: borderRadius * 2.75,
                      ),
                      backgroundColor: seedPalette.shade100,
                      foregroundColor: seedColor,
                      padding: EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 24.0,
                      ),
                    ),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedAddInvoice,
                      size: 20.0,
                      strokeWidth: 1.8,
                    ),
                    label: Text('Submit a report'),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: -0.2, duration: 200.ms),
          Positioned(
            bottom: -160,
            left: -64.0,
            right: -64.0,
            child: Image.asset(podium)
                .animate()
                .fadeIn(duration: 300.ms, delay: 300.ms)
                .slideY(begin: 0.1, duration: 300.ms, delay: 300.ms),
          ),
        ],
      ),
    );
  }
}
