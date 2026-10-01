import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final IconData? badgeIcon;
  final bool isDarkTheme;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.badgeIcon,
    this.isDarkTheme = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Circular Logo with subtle shadow and border
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.figmaEmerald.withValues(alpha: 0.08),
            border: Border.all(
              color: isDarkTheme
                  ? Colors.white.withValues(alpha: 0.25)
                  : AppColors.figmaEmerald.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Image.asset(
            AppConstants.appLogo,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Icon(
              Icons.local_gas_station_rounded,
              size: 42,
              color: isDarkTheme ? Colors.white : AppColors.figmaEmerald,
            ),
          ),
        ),
        const SizedBox(height: 14),

        // App Brand Name
        Text(
          AppConstants.appName,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: isDarkTheme ? Colors.white : AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),

        // Optional Portal / Access Badge
        if (badgeText != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDarkTheme
                  ? Colors.white.withValues(alpha: 0.15)
                  : AppColors.badgeActiveBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badgeIcon != null) ...[
                  Icon(
                    badgeIcon,
                    size: 13,
                    color: isDarkTheme ? Colors.white : AppColors.figmaEmerald,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  badgeText!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDarkTheme ? Colors.white : AppColors.figmaEmerald,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
        ],

        // Subtitle / Description
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.8)
                : AppColors.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
