import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/report.dart';
import '../../utils/constants.dart';

/// Card widget displaying a report summary in the swiper
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.isExpanded = false,
  });

  final ReportModel report;
  final VoidCallback? onTap;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: borderRadius * 3.5,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact header (always visible)
            _buildCompactHeader(),

            // Expanded content
            if (isExpanded) ...[
              const Divider(height: 1),
              _buildExpandedContent(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Status indicator
          _StatusBadge(status: report.status),
          const Gap(12),

          // Title and location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report.title,
                  style: AppTextStyles.h4.copyWith(color: seedColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLocation01,
                      color: greyColor,
                      size: 14,
                    ),
                    const Gap(4),
                    Expanded(
                      child: Text(
                        report.streetName,
                        style: AppTextStyles.small.copyWith(color: greyColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Distance and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _SeverityBadge(severity: report.severity),
              const Gap(4),
              Text(
                timeago.format(report.createdAt, locale: 'en_short'),
                style: AppTextStyles.small.copyWith(color: greyColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          if (report.description != null && report.description!.isNotEmpty) ...[
            Text(
              report.description!,
              style: AppTextStyles.body.copyWith(color: darkColor),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(12),
          ],

          // Stats row
          Row(
            children: [
              _StatItem(
                icon: HugeIcons.strokeRoundedThumbsUp,
                value: report.endorsementCount.toString(),
                label: 'Endorsements',
              ),
              const Gap(24),
              _StatItem(
                icon: HugeIcons.strokeRoundedView,
                value: report.viewCount.toString(),
                label: 'Views',
              ),
              const Gap(24),
              _StatItem(
                icon: HugeIcons.strokeRoundedImage01,
                value: report.imageCount.toString(),
                label: 'Photos',
              ),
            ],
          ),

          const Gap(16),

          // Category and tags
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _CategoryChip(category: report.category),
              ...report.tags.take(3).map((tag) => _TagChip(tag: tag)),
            ],
          ),

          const Gap(16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedThumbsUp,
                    color: seedColor,
                    size: 18,
                  ),
                  label: const Text('Endorse'),
                ),
              ),
              const Gap(12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedNavigation01,
                    color: lightColor,
                    size: 18,
                  ),
                  label: const Text('Navigate'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Status badge with color coding
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  Color get _color {
    return switch (status) {
      ReportStatus.pending => const Color(0xFFFFA726),
      ReportStatus.verified => const Color(0xFF4CAF50),
      ReportStatus.inProgress => const Color(0xFF2196F3),
      ReportStatus.resolved => const Color(0xFF9E9E9E),
      ReportStatus.rejected => const Color(0xFFF44336),
      ReportStatus.duplicate => const Color(0xFF9E9E9E),
    };
  }

  IconData get _icon {
    return switch (status) {
      ReportStatus.pending => Icons.schedule,
      ReportStatus.verified => Icons.verified,
      ReportStatus.inProgress => Icons.engineering,
      ReportStatus.resolved => Icons.check_circle,
      ReportStatus.rejected => Icons.cancel,
      ReportStatus.duplicate => Icons.content_copy,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        _icon,
        color: _color,
        size: 20,
      ),
    );
  }
}

/// Severity badge
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final ReportSeverity severity;

  Color get _color {
    return switch (severity) {
      ReportSeverity.low => const Color(0xFF4CAF50),
      ReportSeverity.medium => const Color(0xFFFFA726),
      ReportSeverity.high => const Color(0xFFFF7043),
      ReportSeverity.critical => const Color(0xFFF44336),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: borderRadius,
      ),
      child: Text(
        severity.displayName,
        style: AppTextStyles.small.copyWith(
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Stat item for the expanded view
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final List<List<dynamic>> icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            HugeIcon(
              icon: icon,
              color: seedColor,
              size: 16,
            ),
            const Gap(4),
            Text(
              value,
              style: AppTextStyles.h4.copyWith(color: seedColor),
            ),
          ],
        ),
        Text(
          label,
          style: AppTextStyles.small.copyWith(color: greyColor),
        ),
      ],
    );
  }
}

/// Category chip
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final TrashCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: seedPalette.shade100,
        borderRadius: borderRadius,
      ),
      child: Text(
        category.displayName,
        style: AppTextStyles.small.copyWith(
          color: seedColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Tag chip
class _TagChip extends StatelessWidget {
  const _TagChip({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: greyColor.withValues(alpha: 0.1),
        borderRadius: borderRadius,
      ),
      child: Text(
        '#$tag',
        style: AppTextStyles.small.copyWith(
          color: greyColor,
        ),
      ),
    );
  }
}

/// Empty state when no reports are nearby
class NoReportsNearby extends StatelessWidget {
  const NoReportsNearby({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: borderRadius * 2.5,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.eco,
            size: 64,
            color: seedPalette.shade300,
          ),
          const Gap(16),
          Text(
            'No trash reports nearby!',
            style: AppTextStyles.h3.copyWith(color: seedColor),
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            'Your area looks clean. Be the first to report if you spot any trash dumps.',
            style: AppTextStyles.body.copyWith(color: greyColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), duration: 500.ms);
  }
}

