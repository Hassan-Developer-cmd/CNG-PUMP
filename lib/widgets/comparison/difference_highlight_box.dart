import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class DifferenceHighlightBox extends StatelessWidget {
  final String formattedDifference;
  final bool isCorrupted;

  const DifferenceHighlightBox({
    super.key,
    required this.formattedDifference,
    required this.isCorrupted,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor = isCorrupted
        ? const Color(0xFFFFF0F0)
        : const Color(0xFFF1F8E9);
    final Color borderColor = isCorrupted
        ? AppColors.alertRedBorder
        : AppColors.successGreenBorder;
    final Color valueColor = isCorrupted
        ? AppColors.alertRedTitle
        : AppColors.successGreenTitle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: borderColor, width: 1.0.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppConstants.difference,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            formattedDifference,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
