import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/audit_history_model.dart';
import '../../models/capture_history_item.dart';
import '../../screens/history/admin_audit_detail_screen.dart';
import '../../screens/history/audit_photo_fullscreen_viewer.dart';
import 'audit_session_card.dart';

/// Card widget to display an audit session fetched dynamically from MongoDB.
/// Renders real database values and loads images via [Image.network] with full backend URLs.
class AuditHistoryCard extends StatelessWidget {
  final AuditHistoryModel item;
  final VoidCallback? onTap;

  const AuditHistoryCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final captureSession = item.toCaptureHistoryItem();
    final isMeter = item.mode.toLowerCase() == 'meter';

    return Stack(
      children: [
        SizedBox(
          width: 0,
          height: 0,
          child: OverflowBox(
            minWidth: 0,
            maxWidth: 0,
            minHeight: 0,
            maxHeight: 0,
            child: AuditSessionCard(
              session: CaptureHistoryItem(
                id: captureSession.id,
                dateTime: captureSession.dateTime,
                images: const [],
                stationName: '',
                operatorName: '',
              ),
            ),
          ),
        ),
        Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10.r,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            if (onTap != null) {
              onTap!();
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAuditDetailScreen(session: captureSession),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header: Station Icon, Name & Mode Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 34.w,
                            height: 34.h,
                            decoration: BoxDecoration(
                              color: AppColors.lightTeal,
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.local_gas_station_rounded,
                              size: 18.sp,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.stationName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  'Op: ${item.operatorName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8.w),
                    // Mode Badge
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: isMeter ? const Color(0xFFE0F2FE) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: isMeter ? const Color(0xFF0284C7) : const Color(0xFF16A34A),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        item.formattedModeName,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isMeter ? const Color(0xFF0369A1) : const Color(0xFF15803D),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12.h),

                // 2. Images Gallery: loaded via Image.network with backend full URLs
                _buildImagesGallery(context),

                SizedBox(height: 12.h),

                // 3. Footer: Formatted Date/Time & Verification Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 13.sp, color: AppColors.textMuted),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              item.formattedDateTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5.sp,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: item.hasCorruption
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        item.hasCorruption ? 'FLAGGED' : 'SYNCED',
                        style: TextStyle(
                          fontSize: 9.5.sp,
                          fontWeight: FontWeight.w700,
                          color: item.hasCorruption
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  ],
);
}

  Widget _buildImagesGallery(BuildContext context) {
    if (item.images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_camera_back_outlined, size: 16.sp, color: AppColors.textMuted),
              SizedBox(width: 6.w),
              Text(
                'No images attached',
                style: TextStyle(fontSize: 11.sp, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    final images = item.images;

    if (images.length == 1) {
      return _buildImageCard(context, images[0], 0, height: 150.h);
    }

    if (images.length == 2) {
      return Row(
        children: [
          Expanded(child: _buildImageCard(context, images[0], 0, height: 120.h)),
          SizedBox(width: 8.w),
          Expanded(child: _buildImageCard(context, images[1], 1, height: 120.h)),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildImageCard(context, images[0], 0, height: 110.h)),
            SizedBox(width: 8.w),
            Expanded(child: _buildImageCard(context, images[1], 1, height: 110.h)),
          ],
        ),
        if (images.length > 2) ...[
          SizedBox(height: 8.h),
          _buildImageCard(context, images[2], 2, height: 100.h),
        ],
      ],
    );
  }

  Widget _buildImageCard(
    BuildContext context,
    AuditHistoryImage img,
    int index, {
    required double height,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AuditPhotoFullscreenViewer(
              images: item.toCaptureHistoryItem().images,
              initialIndex: index,
              stationName: item.stationName,
              operatorName: item.operatorName,
              modeName: item.formattedModeName,
            ),
          ),
        );
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: AppColors.primaryTeal.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(9.r),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Network Image Loader
              if (img.imageUrl.isNotEmpty)
                Image.network(
                  img.imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 24.w,
                        height: 24.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white70),
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _buildPlaceholder(img.label),
                )
              else
                _buildPlaceholder(img.label),

              // Bottom Label Tag
              Positioned(
                left: 8.w,
                bottom: 8.h,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    img.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String label) {
    return Container(
      color: const Color(0xFF1E293B),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_outlined, size: 24.sp, color: Colors.white54),
            SizedBox(height: 4.h),
            Text(
              label,
              style: TextStyle(color: Colors.white70, fontSize: 10.sp),
            ),
          ],
        ),
      ),
    );
  }
}
