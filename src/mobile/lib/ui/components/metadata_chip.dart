import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../utils/constants.dart';

/// Small metadata chip for info display
class MetadataChip extends StatelessWidget {
  const MetadataChip({required this.icon, required this.label, this.avatarUrl});

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
                width: 14.0,
                height: 14.0,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) =>
                    HugeIcon(icon: icon, color: seedColor, size: 14),
              ),
            )
          else
            HugeIcon(icon: icon, color: seedColor, size: 14),
          const Gap(4.0),
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
