import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../utils/constants.dart';

/// Shimmer loading placeholder for report cards
/// Matches the size and layout of ReportCard for seamless loading UX
class ReportCardShimmer extends StatelessWidget {
  const ReportCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: lightColor,
        borderRadius: borderRadius * 3.0,
        border: Border.all(color: lightColor, width: 4.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image placeholder
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius.topLeft.x * 2.5),
              topRight: Radius.circular(borderRadius.topRight.x * 2.5),
            ),
            child: _ShimmerBox(width: double.infinity, height: 180),
          ),

          // Content placeholder
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title placeholder (2 lines)
                _ShimmerBox(
                  width: double.infinity,
                  height: 18,
                  borderRadius: borderRadius,
                ),
                const SizedBox(height: 6),
                _ShimmerBox(width: 180, height: 18, borderRadius: borderRadius),
                const SizedBox(height: 12),
                // Metadata chips placeholder
                Row(
                  children: [
                    _ShimmerBox(
                      width: 70,
                      height: 24,
                      borderRadius: borderRadius,
                    ),
                    const SizedBox(width: 8),
                    _ShimmerBox(
                      width: 80,
                      height: 24,
                      borderRadius: borderRadius,
                    ),
                    const SizedBox(width: 8),
                    _ShimmerBox(
                      width: 60,
                      height: 24,
                      borderRadius: borderRadius,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Single shimmer box placeholder with animation
class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: seedPalette.shade100,
            borderRadius: borderRadius ?? BorderRadius.zero,
          ),
        )
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(
          duration: 1200.ms,
          color: seedPalette.shade50.withValues(alpha: 0.8),
        );
  }
}

/// A loading widget showing multiple shimmer cards for the swiper area
class ReportCardsShimmerLoading extends StatelessWidget {
  const ReportCardsShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      child: ReportCardShimmer(),
    );
  }
}
