import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../models/models.dart';
import '../../utils/constants.dart';

/// Modal bottom sheet to display report details when a pin is tapped
class ReportDetailsModal extends StatelessWidget {
  const ReportDetailsModal({
    super.key,
    required this.report,
    this.distanceAway,
    this.onNavigate,
    this.onShare,
  });

  final ReportModel report;
  final String? distanceAway;
  final VoidCallback? onNavigate;
  final VoidCallback? onShare;

  /// Show the modal
  static Future<void> show(
    BuildContext context, {
    required ReportModel report,
    String? distanceAway,
    VoidCallback? onNavigate,
    VoidCallback? onShare,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ReportDetailsModal(
        report: report,
        distanceAway: distanceAway,
        onNavigate: onNavigate,
        onShare: onShare,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: borderRadius * 3,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image header with badges
          _buildImageHeader(),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  report.title,
                  style: AppTextStyles.h3.copyWith(color: darkColor),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const Gap(8),

                // Metadata row
                _buildMetadataRow(),

                // Observation if available
                if (report.observation != null &&
                    report.observation!.isNotEmpty) ...[
                  const Gap(12),
                  Text(
                    report.observation!,
                    style: AppTextStyles.body.copyWith(color: greyColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Author info
                if (report.hasAuthor) ...[
                  const Gap(12),
                  _buildAuthorRow(),
                ],

                const Gap(16),

                // Action buttons
                _buildActionButtons(context),
              ],
            ),
          ),
        ],
      ),
    ).animate().slideY(begin: 0.3, duration: 300.ms).fadeIn(duration: 300.ms);
  }

  Widget _buildImageHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(borderRadius.topLeft.x * 3),
        topRight: Radius.circular(borderRadius.topRight.x * 3),
      ),
      child: SizedBox(
        height: 160,
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

            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // Top badges row
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  _SeverityBadge(severity: report.severity),
                  const Spacer(),
                  _StatusBadge(status: report.status),
                ],
              ),
            ),

            // Close button
            Positioned(
              top: 8,
              right: 8,
              child: Builder(
                builder: (context) => IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: lightColor.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 20),
                  ),
                ),
              ),
            ),

            // Image count badge
            if (report.imageCount > 1)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: darkColor.withValues(alpha: 0.7),
                    borderRadius: borderRadius,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.photo_library,
                          color: lightColor, size: 14),
                      const Gap(4),
                      Text(
                        '${report.imageCount}',
                        style:
                            AppTextStyles.small.copyWith(color: lightColor),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: seedPalette.shade100,
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImage01,
          color: seedPalette.shade300,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildMetadataRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        // Distance
        if (distanceAway != null && distanceAway!.isNotEmpty)
          _MetadataChip(
            icon: HugeIcons.strokeRoundedLocation01,
            label: distanceAway!,
          ),

        // Category
        _MetadataChip(
          icon: HugeIcons.strokeRoundedDelete02,
          label: report.categoryDisplayName,
        ),

        // Time
        _MetadataChip(
          icon: HugeIcons.strokeRoundedClock01,
          label: timeago.format(report.createdAt),
        ),

        // Location address if available
        if (report.location?.hasStreetName == true)
          _MetadataChip(
            icon: HugeIcons.strokeRoundedMapsLocation01,
            label: report.location!.streetName!,
          ),
      ],
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        // Avatar
        if (report.authorAvatarUrl != null)
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: report.authorAvatarUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 24,
                height: 24,
                color: seedPalette.shade100,
                child: Center(
                  child: Text(
                    report.authorInitials,
                    style: AppTextStyles.small.copyWith(color: seedColor),
                  ),
                ),
              ),
            ),
          )
        else
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: seedPalette.shade100,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                report.authorInitials,
                style: AppTextStyles.small.copyWith(color: seedColor),
              ),
            ),
          ),

        const Gap(8),

        Text(
          'Reported by ${report.authorDisplayName}',
          style: AppTextStyles.small.copyWith(color: greyColor),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Share button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onShare ?? () {},
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              color: seedColor,
              size: 18,
            ),
            label: const Text('Share'),
          ),
        ),

        const Gap(12),

        // Navigate button
        Expanded(
          child: FilledButton.icon(
            onPressed: onNavigate ?? () {},
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNavigation01,
              color: lightColor,
              size: 18,
            ),
            label: const Text('Navigate'),
          ),
        ),
      ],
    );
  }
}

/// Severity badge
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

/// Status badge
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

/// Metadata chip
class _MetadataChip extends StatelessWidget {
  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  final List<List<dynamic>> icon;
  final String label;

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
          HugeIcon(
            icon: icon,
            color: seedColor,
            size: 14,
          ),
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

