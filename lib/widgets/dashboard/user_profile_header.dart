import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class UserProfileHeader extends StatelessWidget {
  final String userName;

  const UserProfileHeader({
    super.key,
    this.userName = AppConstants.defaultUserName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6.r,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          SizedBox(width: 14.w),
          Text(
            userName,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 46.w,
      height: 46.h,
      decoration: BoxDecoration(
        color: const Color(0xFFD7CCC8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.w),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.person, color: Color(0xFF5D4037), size: 28.sp),
      ),
    );
  }
}
