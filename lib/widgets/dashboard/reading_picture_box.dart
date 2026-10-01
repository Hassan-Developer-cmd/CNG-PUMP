import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_constants.dart';
import '../../services/image_timestamp_service.dart';
import '../shared_widgets/dashed_border_box.dart';

class ReadingPictureBox extends StatelessWidget {
  final File? image;
  final DateTime? capturedAt;
  final Color borderColor;
  final VoidCallback onTap;
  final double? height;
  final String label;

  /// True while the image is being uploaded to the server.
  final bool isUploading;

  /// True once the server has confirmed the image was stored successfully.
  final bool isVerified;

  /// Non-null when the last upload attempt failed.
  final String? uploadError;

  const ReadingPictureBox({
    super.key,
    required this.image,
    required this.borderColor,
    required this.onTap,
    this.capturedAt,
    this.height,
    this.label = AppConstants.takePicture,
    this.isUploading = false,
    this.isVerified = false,
    this.uploadError,
  });


  @override
  Widget build(BuildContext context) {
    final boxHeight = height ?? 105.h;

    return DashedBorderBox(
      borderColor: isVerified
          ? const Color(0xFF22C55E)
          : (uploadError != null ? const Color(0xFFEF4444) : borderColor),
      backgroundColor: const Color(0xFFFCFDFD),
      borderRadius: 10.r,
      strokeWidth: (isVerified || uploadError != null) ? 1.8 : 1.2,
      dashLength: 5.0,
      dashGap: 3.5,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: boxHeight,
        width: double.infinity,
        child: image != null
            ? _buildCapturedImage(image!)
            : _buildEmptyContent(),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 26.sp,
          color: const Color(0xFF1E293B),
        ),
        SizedBox(height: 5.h),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.sp,
            color: const Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCapturedImage(File imageFile) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(imageFile, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.15)),

          // Upload Error Banner (top)
          if (uploadError != null && !isUploading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                color: const Color(0xCCB00020),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 11.sp),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Text(
                        'Upload failed — tap Retry in banner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Upload spinner overlay
          if (isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22.sp,
                      height: 22.sp,
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Uploading…',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Verified badge (top-right)
          if (isVerified && !isUploading)
            Positioned(
              top: 6.h,
              right: 6.w,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_done_rounded, color: Colors.white, size: 10.sp),
                    SizedBox(width: 3.w),
                    Text(
                      'Uploaded',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.5.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Timestamp (bottom-left)
          if (capturedAt != null)
            Positioned(
              left: 8.w,
              bottom: 8.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 10.sp,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      ImageTimestampService.formatTimestamp(capturedAt!),
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

          // Retake button (bottom-right), hidden while uploading
          if (!isUploading)
            Positioned(
              right: 8.w,
              bottom: 8.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
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
                        fontSize: 9.5.sp,
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
