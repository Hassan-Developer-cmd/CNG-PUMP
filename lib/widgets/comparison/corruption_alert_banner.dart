import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

class CorruptionAlertBanner extends StatelessWidget {
  final bool isCorrupted;
  final String title;
  final String message;

  const CorruptionAlertBanner({
    super.key,
    required this.isCorrupted,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isCorrupted
        ? AppColors.alertRedBg
        : AppColors.successGreenBg;
    final Color borderColor = isCorrupted
        ? AppColors.alertRedBorder
        : AppColors.successGreenBorder;
    final Color iconBg = isCorrupted
        ? AppColors.alertRedIcon
        : AppColors.successGreenIcon;
    final IconData icon = isCorrupted
        ? Icons.warning_amber_rounded
        : Icons.check;
    final Color titleColor = isCorrupted
        ? AppColors.alertRedTitle
        : AppColors.successGreenTitle;
    final Color messageColor = isCorrupted
        ? AppColors.alertRedSubtitle
        : AppColors.successGreenSubtitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.h,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.alertTitle.copyWith(color: titleColor),
                ),
                SizedBox(height: 4.h),
                Text(
                  message,
                  style: AppTypography.alertSubtitle.copyWith(
                    color: messageColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
