import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';

class InfoNoteCard extends StatelessWidget {
  const InfoNoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(2.r),
            margin: EdgeInsets.only(top: 1.r),
            child: Icon(
              Icons.info_outline,
              size: 20.sp,
              color: AppColors.primaryTeal,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              AppConstants.infoNoteText,
              style: AppTypography.infoText,
            ),
          ),
        ],
      ),
    );
  }
}
