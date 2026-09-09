import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';

class StatusBadge extends StatelessWidget {
  final bool isRequired;

  const StatusBadge({
    super.key,
    required this.isRequired,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        isRequired ? AppColors.requiredBadgeBg : AppColors.optionalBadgeBg;
    final Color textColor =
        isRequired ? AppColors.requiredBadgeText : AppColors.optionalBadgeText;
    final String label =
        isRequired ? AppConstants.requiredBadge : AppConstants.optionalBadge;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.badge.copyWith(color: textColor),
      ),
    );
  }
}
