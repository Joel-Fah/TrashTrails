import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../utils/constants.dart';

/// A circular avatar widget that displays a user's profile image or initials
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    this.tag,
    this.radius = 24.0,
    this.imageUrl,
    this.initials,
    this.name,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showBorder = false,
  });

  /// Hero tag for navigation animations
  final String? tag;

  /// Radius of the avatar circle
  final double radius;

  /// URL of the user's profile image
  final String? imageUrl;

  /// Initials to display when no image is available
  final String? initials;

  /// Full name to derive initials from if initials not provided
  final String? name;

  /// Callback when avatar is tapped
  final VoidCallback? onTap;

  /// Border color around the avatar
  final Color? borderColor;

  /// Border width
  final double borderWidth;

  /// Whether to show border
  final bool showBorder;

  /// Derives initials from name
  String get _initials {
    if (initials != null && initials!.isNotEmpty) return initials!;
    if (name == null || name!.isEmpty) return '?';

    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first
        .substring(0, parts.first.length.clamp(0, 2))
        .toUpperCase();
  }

  /// Gets a consistent color based on the initials (using app's seed palette)
  Color get _backgroundColor {
    final hash = _initials.hashCode.abs();
    final paletteColors = [
      seedPalette.shade400,
      seedPalette.shade500,
      seedPalette.shade600,
      seedPalette.shade700,
      seedColor,
    ];
    return paletteColors[hash % paletteColors.length];
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = _buildAvatar();

    if (showBorder) {
      avatar = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? lightColor,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    if (tag != null && tag!.isNotEmpty) {
      avatar = Hero(tag: tag!, child: avatar);
    }

    if (onTap != null) {
      avatar = GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }

  Widget _buildAvatar() {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    if (!hasImage) {
      return _buildInitialsAvatar();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      fit: BoxFit.cover,
      imageBuilder: (context, imageProvider) {
        return CircleAvatar(radius: radius, backgroundImage: imageProvider);
      },
      placeholder: (context, url) => _buildInitialsAvatar(),
      errorWidget: (context, url, error) => _buildInitialsAvatar(),
    );
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _backgroundColor,
      child: Text(_initials, style: _getTextStyle()),
    );
  }

  TextStyle _getTextStyle() {
    if (radius >= 32) {
      return AppTextStyles.h2.copyWith(color: lightColor);
    } else if (radius >= 24) {
      return AppTextStyles.h4.copyWith(color: lightColor);
    } else {
      return AppTextStyles.small.copyWith(
        color: lightColor,
        fontWeight: FontWeight.w600,
      );
    }
  }
}

/// A simple avatar that displays an asset image
class AssetAvatar extends StatelessWidget {
  const AssetAvatar({
    super.key,
    required this.assetPath,
    this.radius = 24.0,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showBorder = true,
  });

  final String assetPath;
  final double radius;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundImage: AssetImage(assetPath),
      backgroundColor: seedPalette.shade100,
    );

    if (showBorder) {
      avatar = Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? lightColor,
            width: borderWidth,
          ),
        ),
        child: avatar,
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: avatar);
    }

    return avatar;
  }
}
