import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';
import '../../screens/history/admin_audit_detail_screen.dart';
import '../../screens/history/audit_photo_fullscreen_viewer.dart';
import 'watermarked_photo_thumbnail.dart';

class AuditSessionCard extends StatelessWidget {
  final CaptureHistoryItem session;
  final VoidCallback? onTap;
  final ValueChanged<int>? onImageTap;

  const AuditSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onImageTap,
  });

  void _handleImageTap(BuildContext context, int index) {
    if (onImageTap != null) {
      onImageTap!(index);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AuditPhotoFullscreenViewer(
            images: session.images,
            initialIndex: index,
            stationName: session.stationName,
            operatorName: session.operatorName,
            modeName: session.modeName,
          ),
        ),
      );
    }
  }

  void _handleCardTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminAuditDetailScreen(session: session),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => _handleCardTap(context),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header: Station Name & Mode Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 30.w,
                            height: 30.h,
                            decoration: BoxDecoration(
                              color: AppColors.lightTeal,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              Icons.local_gas_station_rounded,
                              size: 16.sp,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              session.stationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (session.modeName != null && session.modeName!.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF56BAA7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: const Color(0xFF56BAA7).withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          session.modeName!,
                          style: TextStyle(
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 6.h),

                // Minimal Subtitle: Operator Name & Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 12.sp,
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        session.operatorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '  •  ',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: AppColors.textMuted,
                      ),
                    ),
                    Icon(
                      Icons.access_time_rounded,
                      size: 11.sp,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(width: 3.w),
                    Flexible(
                      child: Text(
                        session.formattedDateTime,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Visual Photo Feed / Media Gallery of Captured Watermarked Photos
                _buildVisualMediaGallery(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisualMediaGallery(BuildContext context) {
    final images = session.images;

    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_outlined, size: 16.sp, color: AppColors.textMuted),
              SizedBox(width: 6.w),
              Text(
                'No audit photos recorded',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    if (images.length == 1) {
      return WatermarkedPhotoThumbnail(
        capturedImage: images[0],
        width: double.infinity,
        height: 160.h,
        onTap: () => _handleImageTap(context, 0),
      );
    }

    if (images.length == 2) {
      return Row(
        children: [
          Expanded(
            child: WatermarkedPhotoThumbnail(
              capturedImage: images[0],
              width: double.infinity,
              height: 135.h,
              onTap: () => _handleImageTap(context, 0),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: WatermarkedPhotoThumbnail(
              capturedImage: images[1],
              width: double.infinity,
              height: 135.h,
              onTap: () => _handleImageTap(context, 1),
            ),
          ),
        ],
      );
    }

    if (images.length == 3) {
      return Column(
        children: [
          WatermarkedPhotoThumbnail(
            capturedImage: images[0],
            width: double.infinity,
            height: 145.h,
            onTap: () => _handleImageTap(context, 0),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[1],
                  width: double.infinity,
                  height: 120.h,
                  onTap: () => _handleImageTap(context, 1),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[2],
                  width: double.infinity,
                  height: 120.h,
                  onTap: () => _handleImageTap(context, 2),
                ),
              ),
            ],
          ),
        ],
      );
    }

    if (images.length == 4) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[0],
                  width: double.infinity,
                  height: 125.h,
                  onTap: () => _handleImageTap(context, 0),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[1],
                  width: double.infinity,
                  height: 125.h,
                  onTap: () => _handleImageTap(context, 1),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[2],
                  width: double.infinity,
                  height: 125.h,
                  onTap: () => _handleImageTap(context, 2),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: WatermarkedPhotoThumbnail(
                  capturedImage: images[3],
                  width: double.infinity,
                  height: 125.h,
                  onTap: () => _handleImageTap(context, 3),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // 5 or more images: 2-column grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: images.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1.25,
      ),
      itemBuilder: (context, imgIndex) {
        return WatermarkedPhotoThumbnail(
          capturedImage: images[imgIndex],
          width: double.infinity,
          height: double.infinity,
          onTap: () => _handleImageTap(context, imgIndex),
        );
      },
    );
  }
}
