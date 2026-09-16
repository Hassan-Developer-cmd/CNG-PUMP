import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../models/cng_reading_item.dart';
import '../../services/image_timestamp_service.dart';
import '../shared_widgets/dashed_border_box.dart';
import '../shared_widgets/status_badge.dart';

class CngReadingCard extends StatelessWidget {
  final CngReadingItem item;
  final VoidCallback? onCustomCameraRequested;
  final bool isCaptureEnabled;

  const CngReadingCard({
    super.key,
    required this.item,
    this.onCustomCameraRequested,
    this.isCaptureEnabled = true,
  });

  void _handlePictureTap() {
    if (!isCaptureEnabled) return;
    onCustomCameraRequested?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  item.icon,
                  size: 17.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(item.title, style: AppTypography.sectionTitle),
              ),
              if (item.capturedAt != null) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.primaryTeal.withValues(alpha: 0.3),
                      width: 0.7,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_outlined,
                        color: AppColors.primaryTeal,
                        size: 10.sp,
                      ),
                      SizedBox(width: 3.w),
                      Text(
                        ImageTimestampService.formatTimestamp(item.capturedAt!),
                        style: TextStyle(
                          color: AppColors.primaryTeal,
                          fontSize: 8.5.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
              ],
              StatusBadge(isRequired: item.isRequired),
            ],
          ),
          SizedBox(height: 13.h),
          _buildPictureBox(),
        ],
      ),
    );
  }

  Widget _buildPictureBox() {
    return DashedBorderBox(
      // Required cards = red dotted border
      // Optional last card = green/teal dotted border
      // Captured card = green/teal dotted border
      borderColor: item.hasImage
          ? AppColors.dashedTeal
          : !item.isRequired
          ? AppColors.dashedTeal
          : AppColors.dashedRed,

      backgroundColor: const Color(0xFFFCFDFD),
      borderRadius: 8.r,
      strokeWidth: 1.r,

      // Longer and clearer dotted segments
      dashLength: 5.r,
      dashGap: 2.r,

      padding: EdgeInsets.zero,
      onTap: _handlePictureTap,

      child: SizedBox(
        height: 120.h,
        width: double.infinity,
        child: item.hasImage
            ? _buildCapturedImage(item.image!)
            : _buildEmptyPictureContent(!isCaptureEnabled),
      ),
    );
  }

  Widget _buildEmptyPictureContent(bool disabled) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 24.sp,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 5.h),
        Text(
          AppConstants.takePicture,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImage(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.15)),

          Positioned(
            right: 7.w,
            bottom: 7.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 12.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Retake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
