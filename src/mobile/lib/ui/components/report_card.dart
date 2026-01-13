import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/models.dart';
import '../../utils/constants.dart';

/// Card widget displaying a report summary in the swiper
/// Adapts to different sizes based on the draggable sheet snap position
class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.distanceAway,
  });

  final ReportModel report;
  final VoidCallback? onTap;

  /// Distance from user's location (e.g., "1.2 km")
  final String? distanceAway;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: borderRadius * 3.0,
          border: Border.all(color: lightColor, width: 4.0),
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
            // Image with stacked info (severity, status)
            Expanded(child: _buildImageSection()),

            // Title and metadata
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  /// Builds the image section with stacked badges
  Widget _buildImageSection() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius.topLeft.x * 2.5),
        topRight: Radius.circular(borderRadius.topRight.x * 2.5),
      ),
      child: SizedBox(
        height: 160.0,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (report.hasImages)
              CachedNetworkImage(
                imageUrl: report.thumbnailUrl ?? '',
                fit: BoxFit.cover,
                placeholder: (context, url) => _buildImagePlaceholder(),
                errorWidget: (context, url, error) => _buildImagePlaceholder(),
              )
            else
              _buildImagePlaceholder(),

            // Gradient overlay for better text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Top row: Severity badge + Status (if pending/rejected)
            Positioned(
              top: 8,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Severity badge
                  _SeverityBadge(severity: report.severity),

                  const Spacer(),

                  // Status badge (only for pending or rejected)
                  if (_shouldShowStatus) _StatusBadge(status: report.status),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Whether to show the status badge
  bool get _shouldShowStatus {
    return report.status == ReportStatus.pending ||
        report.status == ReportStatus.rejected;
  }

  /// Builds the image placeholder
  Widget _buildImagePlaceholder() {
    return Container(
      color: seedPalette.shade100,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          color: seedPalette.shade300,
          size: 32,
        ),
      ),
    );
  }

  /// Builds the info section below the image
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title (max 2 lines)
          Text(
            report.title,
            style: AppTextStyles.h4.copyWith(color: darkColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const Gap(8),

          // Metadata wrap: distance, category, author
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Distance away
              if (distanceAway != null && distanceAway!.isNotEmpty)
                _MetadataChip(
                  icon: HugeIcons.strokeRoundedLocation06,
                  label: distanceAway!,
                ),

              // Category
              _MetadataChip(
                icon: HugeIcons.strokeRoundedDelete02,
                label: report.categoryDisplayName,
              ),

              // Author
              if (report.hasAuthor)
                _MetadataChip(
                  icon: HugeIcons.strokeRoundedUser,
                  label: report.authorDisplayName ?? 'Unknown',
                  avatarUrl: report.authorAvatarUrl,
                ),

              // Time ago
              _MetadataChip(
                icon: HugeIcons.strokeRoundedClock01,
                label: timeago.format(report.createdAt, locale: 'en_short'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Severity badge with color coding
class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.severity});

  final ReportSeverityModel severity;

  Color get _color {
    return switch (severity.level) {
      1 => const Color(0xFF4CAF50),
      2 => const Color(0xFFFFA726),
      3 => const Color(0xFFFF7043),
      4 => const Color(0xFFF44336),
      _ => const Color(0xFFFFA726),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.4),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        severity.name,
        style: AppTextStyles.small.copyWith(
          color: lightColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Status badge (only for pending/rejected)
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final ReportStatus status;

  Color get _color {
    return switch (status) {
      ReportStatus.pending => const Color(0xFFFFA726),
      ReportStatus.rejected => const Color(0xFFF44336),
      _ => greyColor,
    };
  }

  IconData get _icon {
    return switch (status) {
      ReportStatus.pending => Icons.schedule,
      ReportStatus.rejected => Icons.cancel,
      _ => Icons.info,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: lightColor.withValues(alpha: 0.9),
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: 14),
          const Gap(4),
          Text(
            status.displayName,
            style: AppTextStyles.small.copyWith(
              color: _color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small metadata chip for info display
class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
    this.avatarUrl,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: seedPalette.shade50,
        borderRadius: borderRadius,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar or icon
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: 14,
                height: 14,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    HugeIcon(icon: icon, color: seedColor, size: 14),
              ),
            )
          else
            HugeIcon(icon: icon, color: seedColor, size: 14),
          const Gap(4),
          Text(
            label,
            style: AppTextStyles.small.copyWith(
              color: seedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no reports are nearby
class NoReportsNearby extends StatelessWidget {
  const NoReportsNearby({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
            padding: const EdgeInsets.all(24.0),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedEcoPower, size: 64, color: seedPalette.shade300),
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
                const Gap(16.0),
                // refresh text button
                TextButton(
                  onPressed: () {
                    // TODO: Implement refresh functionality
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: seedColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(borderRadius: borderRadius * 2.5),
                  ),
                  child: Text(
                    'Refresh',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: seedColor,
                    ),
                  ),
                ),
              ],
            ),
          )
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(begin: const Offset(0.9, 0.9), duration: 500.ms),
    );
  }
}

/// Compact report card for lists
class ReportListItem extends StatelessWidget {
  const ReportListItem({super.key, required this.report, this.onTap});

  final ReportModel report;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius * 2,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: lightColor,
          borderRadius: borderRadius * 2,
          border: Border.all(color: seedPalette.shade100, width: 1),
        ),
        child: Row(
          children: [
            // Image thumbnail
            ClipRRect(
              borderRadius: borderRadius,
              child: SizedBox(
                width: 60,
                height: 60,
                child: report.hasImages
                    ? CachedNetworkImage(
                        imageUrl: report.thumbnailUrl ?? '',
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            const Gap(12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: darkColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      _SeverityBadge(severity: report.severity),
                      const Gap(8),
                      Text(
                        report.categoryDisplayName,
                        style: AppTextStyles.small.copyWith(color: greyColor),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              color: greyColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: seedPalette.shade100,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          color: seedPalette.shade300,
          size: 24,
        ),
      ),
    );
  }
}
