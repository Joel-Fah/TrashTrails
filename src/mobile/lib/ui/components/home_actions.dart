import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../utils/constants.dart';
import 'user_avatar.dart';

/// Action widget for the Leaderboard with stacked avatars
class LeaderboardActionWidget extends StatelessWidget {
  const LeaderboardActionWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: AlignmentGeometry.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Stacked avatars in arc shape
          SizedBox(
            height: 72.0,
            width: 80.0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Third place (back)
                Positioned(
                      left: 0,
                      child: Transform.rotate(
                        angle: -0.15,
                        child: AssetAvatar(
                          assetPath: avatar3,
                          radius: 20.0,
                          borderColor: bronze,
                          borderWidth: 2,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .slideX(begin: -0.5, duration: 400.ms),

                // Second place (middle-right)
                Positioned(
                      right: 0,
                      child: Transform.rotate(
                        angle: 0.15,
                        child: AssetAvatar(
                          assetPath: avatar2,
                          radius: 20.0,
                          borderColor: silver,
                          borderWidth: 2,
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .slideX(begin: 0.5, duration: 400.ms),

                // First place (front, center, slightly higher)
                Positioned(
                      top: -10,
                      child: AssetAvatar(
                        assetPath: avatar1,
                        radius: 22.0,
                        borderColor: gold, // Gold
                        borderWidth: 2.5,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),
              ],
            ),
          ),

          // Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: seedColor,
              borderRadius: borderRadius * 1.5,
              border: Border.all(color: lightColor, width: 2.0),
            ),
            child: Text(
              'Leaderboard',
              style: AppTextStyles.small.copyWith(
                color: lightColor,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action widget for Trash Trails with stacked trash icons
class TrashTrailsActionWidget extends StatelessWidget {
  const TrashTrailsActionWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Stacked trash icons
          SizedBox(
            height: 72.0,
            width: 80.0,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Background trash (small)
                Positioned(
                      top: -10,
                      right: 20.0,
                      child: Image.asset(
                        trash2,
                        width: 80.0,
                        height: 80.0,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.3, 0.3), duration: 400.ms),

                // Middle trash (medium)
                Positioned(
                      left: 16,
                      top: 16.0,
                      child: Image.asset(
                        trash3,
                        width: 80.0,
                        height: 80.0,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.3, 0.3), duration: 400.ms),

                // Foreground trash (large)
                Positioned(
                      top: 30,
                      left: -10,
                      child: Image.asset(
                        trash1,
                        width: 56.0,
                        height: 56.0,
                        fit: BoxFit.contain,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.3, 0.3), duration: 400.ms),
              ],
            ),
          ),

          // Label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 4.0,
            ),
            decoration: BoxDecoration(
              color: seedColor,
              borderRadius: borderRadius * 1.5,
              border: Border.all(color: lightColor, width: 2.0),
            ),
            child: Text(
              'Trash Trails',
              style: AppTextStyles.small.copyWith(
                color: lightColor,
                fontWeight: FontWeight.w500,
                fontVariations: [FontVariation('wght', 500)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Action widget for creating a new report (same layout as other action widgets)
class NewReportActionWidget extends StatelessWidget {
  const NewReportActionWidget({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Camera/Report icon
          Image.asset(report, width: 88.0, height: 88.0, fit: BoxFit.contain)
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 400.ms),

          // Label
          Positioned(
            bottom: -5.0,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: seedColor,
                borderRadius: borderRadius * 1.5,
                border: Border.all(color: lightColor, width: 2.0),
              ),
              child: Text(
                'New Report',
                style: AppTextStyles.small.copyWith(
                  color: lightColor,
                  fontWeight: FontWeight.w500,
                  fontVariations: [FontVariation('wght', 500)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// My Location button widget
class MyLocationButton extends StatelessWidget {
  const MyLocationButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      tooltip: 'My Location',
      onPressed: onTap,
      style: IconButton.styleFrom(
        backgroundColor: seedPalette.shade200,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius * 2.0,
        ),
        padding: EdgeInsets.all(16.0)
      ),
      icon: HugeIcon(
        icon: HugeIcons.strokeRoundedLocationUser02,
        color: seedColor,
      ),
    );
  }
}
