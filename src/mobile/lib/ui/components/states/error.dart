import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../utils/constants.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.title,
    this.image,
    this.onPressed,
    this.subtitle,
    this.ctaLabel,
  });

  final String? title, subtitle, ctaLabel, image;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          spacing: 16.0,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: seedPalette.shade400.withValues(alpha: 0.16),
                    blurRadius: 60.0,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(image ?? errorImg, width: 160.0),
            ).animate().scale(duration: 300.ms),
            const Gap(16.0),
            Text(
              title ?? 'An error occurred',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const Gap(8.0),
              Text(
                subtitle ?? '',
                style: AppTextStyles.body.copyWith(
                  color: greyColor,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Gap(24.0),
            FilledButton.icon(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: borderRadius * 2.75,
                ),
                backgroundColor: seedPalette.shade100,
                foregroundColor: seedColor,
                padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
              ),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 20.0,
                strokeWidth: 1.8,
              ),
              label: Text(ctaLabel ?? 'Try Again'),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms),
      ),
    );
  }
}
