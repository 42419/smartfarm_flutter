import 'package:flutter/material.dart';

class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.networkUrl,
    this.assetPath,
    this.fallbackIcon = Icons.person,
    this.radius = 16,
    this.backgroundColor,
    this.iconColor,
  });

  final String? networkUrl;
  final String? assetPath;
  final IconData fallbackIcon;
  final double radius;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primaryContainer;
    final fgColor = iconColor ?? colorScheme.onPrimaryContainer;

    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(networkUrl!),
      );
    }

    if (assetPath != null && assetPath!.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: AssetImage(assetPath!),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(fallbackIcon, size: radius, color: fgColor),
    );
  }
}
