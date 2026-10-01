import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';
import '../../widgets/history/watermarked_photo_thumbnail.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import 'audit_photo_fullscreen_viewer.dart';

class AdminAuditDetailScreen extends StatefulWidget {
  final CaptureHistoryItem session;

  const AdminAuditDetailScreen({
    super.key,
    required this.session,
  });

  @override
  State<AdminAuditDetailScreen> createState() => _AdminAuditDetailScreenState();
}

class _AdminAuditDetailScreenState extends State<AdminAuditDetailScreen> {
  bool _isCarouselView = false;
  int _currentCarouselIndex = 0;
  late PageController _carouselController;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.92);
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  void _openFullscreen(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AuditPhotoFullscreenViewer(
          images: widget.session.images,
          initialIndex: initialIndex,
          stationName: widget.session.stationName,
          operatorName: widget.session.operatorName,
          modeName: widget.session.modeName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: CustomCurvedAppBar(
        title: 'Audit Inspection',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Station & Operator Metadata Card
                    _buildSessionInfoCard(),
                    SizedBox(height: 16.h),

                    // 4. Section Header for Photos & View Mode Toggle (Grid vs Carousel)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CAPTURED WATERMARKED PHOTOS (${session.images.length})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.figmaEmerald,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'Pinch-to-zoom & pan stamped pixel watermarks',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // View Switcher (Grid vs Carousel)
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              padding: const EdgeInsets.all(2),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () => setState(() => _isCarouselView = false),
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: !_isCarouselView ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Icon(
                                        Icons.grid_view_rounded,
                                        size: 14.sp,
                                        color: !_isCarouselView ? AppColors.figmaEmerald : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => setState(() => _isCarouselView = true),
                                    borderRadius: BorderRadius.circular(6.r),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                                      decoration: BoxDecoration(
                                        color: _isCarouselView ? Colors.white : Colors.transparent,
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Icon(
                                        Icons.view_carousel_rounded,
                                        size: 14.sp,
                                        color: _isCarouselView ? AppColors.figmaEmerald : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (session.images.isNotEmpty) ...[
                              SizedBox(width: 8.w),
                              TextButton.icon(
                                onPressed: () => _openFullscreen(context, 0),
                                icon: Icon(
                                  Icons.fullscreen_rounded,
                                  size: 16.sp,
                                  color: AppColors.primaryTeal,
                                ),
                                label: Text(
                                  'Fullscreen',
                                  style: TextStyle(
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),

                    // 5. Photos: Carousel or Grid
                    if (_isCarouselView)
                      _buildPhotosCarousel(context)
                    else
                      _buildPhotosGrid(context),

                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 16.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.borderLight)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: session.images.isEmpty
                          ? null
                          : () => _openFullscreen(context, _isCarouselView ? _currentCarouselIndex : 0),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryTeal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      icon: const Icon(
                        Icons.zoom_in_rounded,
                        color: AppColors.primaryTeal,
                      ),
                      label: Text(
                        'Full-screen Zoom',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryTeal,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        elevation: 0,
                      ),
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildSessionInfoCard() {
    final session = widget.session;

    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.lightTeal,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.local_gas_station_rounded,
                        color: AppColors.primaryTeal,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        session.stationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (session.modeName != null) ...[
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 3.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF56BAA7),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    session.modeName!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 10.h),
          Divider(color: AppColors.borderLight, height: 1),
          SizedBox(height: 10.h),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  label: 'Operator',
                  value: session.operatorName,
                  icon: Icons.person_outline_rounded,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  label: 'Audit Timestamp',
                  value: session.formattedDateTime,
                  icon: Icons.access_time_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12.sp, color: const Color(0xFF64748B)),
            SizedBox(width: 4.w),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5.sp,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 3.h),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }



  Widget _buildPhotosCarousel(BuildContext context) {
    final images = widget.session.images;

    if (images.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'No photos captured for this session',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 270.h,
          child: PageView.builder(
            controller: _carouselController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentCarouselIndex = i),
            itemBuilder: (context, index) {
              final captured = images[index];
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: AppColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8.r,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.camera_alt_outlined, size: 14.sp, color: AppColors.primaryTeal),
                                SizedBox(width: 6.w),
                                Text(
                                  captured.label,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: AppColors.lightTeal,
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'Photo ${index + 1} of ${images.length}',
                                style: TextStyle(
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryTeal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: WatermarkedPhotoThumbnail(
                          capturedImage: captured,
                          width: double.infinity,
                          height: double.infinity,
                          isHighRes: true,
                          onTap: () => _openFullscreen(context, index),
                        ),
                      ),
                      InkWell(
                        onTap: () => _openFullscreen(context, index),
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(14.r)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.pinch_rounded, size: 14.sp, color: AppColors.primaryTeal),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  'Tap to inspect stamped watermark in full-screen zoom',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10.5.sp,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 10.h),
        // Dots Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(images.length, (idx) {
            final isCurrent = idx == _currentCarouselIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isCurrent ? 18.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isCurrent ? AppColors.figmaEmerald : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPhotosGrid(BuildContext context) {
    final images = widget.session.images;

    if (images.isEmpty) {
      return Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            'No photos captured for this session',
            style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(images.length, (index) {
        final captured = images[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.borderLight),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.025),
                  blurRadius: 8.r,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Strip
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 14.sp,
                              color: AppColors.primaryTeal,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                captured.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightTeal,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              size: 10.sp,
                              color: AppColors.primaryTeal,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'Stamped Watermark',
                              style: TextStyle(
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryTeal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Large Interactive Photo Box
                WatermarkedPhotoThumbnail(
                  capturedImage: captured,
                  width: double.infinity,
                  height: 180.h,
                  isHighRes: true,
                  onTap: () => _openFullscreen(context, index),
                ),

                // Bottom Tap to Inspect CTA
                InkWell(
                  onTap: () => _openFullscreen(context, index),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(14.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.pinch_rounded,
                          size: 14.sp,
                          color: AppColors.primaryTeal,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Tap to inspect stamped watermark in full-screen zoom',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryTeal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
