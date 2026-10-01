import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';

class WatermarkedPhotoThumbnail extends StatelessWidget {
  final CapturedImage capturedImage;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool showLabel;
  final bool showTimestamp;
  final bool isHighRes;

  const WatermarkedPhotoThumbnail({
    super.key,
    required this.capturedImage,
    this.width,
    this.height,
    this.onTap,
    this.showLabel = true,
    this.showTimestamp = true,
    this.isHighRes = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool fileExists = capturedImage.image.path.isNotEmpty &&
        capturedImage.image.existsSync();
    final bool hasUrl = capturedImage.imageUrl != null &&
        capturedImage.imageUrl!.isNotEmpty;
    final double boxWidth = width ?? 120.w;
    final double boxHeight = height ?? 96.h;
    final bool isLarge = boxHeight >= 115;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Container(
          width: boxWidth,
          height: boxHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Dark slate
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: AppColors.primaryTeal.withValues(alpha: 0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9.r),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Photo Layer: File Image, Network URL, Asset, or Simulated Watermarked Display
                if (fileExists)
                  Image.file(
                    capturedImage.image,
                    fit: BoxFit.cover,
                    cacheWidth: isHighRes ? 1200 : 360,
                    errorBuilder: (_, __, ___) => _buildSimulatedDispenserScreen(isLarge),
                  )
                else if (hasUrl && (capturedImage.imageUrl!.startsWith('http://') || capturedImage.imageUrl!.startsWith('https://')))
                  Image.network(
                    capturedImage.imageUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: isHighRes ? 1200 : 360,
                    errorBuilder: (_, __, ___) => _buildSimulatedDispenserScreen(isLarge),
                  )
                else if (hasUrl && capturedImage.imageUrl!.startsWith('assets/'))
                  Image.asset(
                    capturedImage.imageUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: isHighRes ? 1200 : 360,
                    errorBuilder: (_, __, ___) => _buildSimulatedDispenserScreen(isLarge),
                  )
                else
                  _buildSimulatedDispenserScreen(isLarge),

                // 2. Subtle Dark Gradient for readability of chips
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // 3. Top Label Badge
                if (showLabel)
                  Positioned(
                    top: isLarge ? 8.r : 6.r,
                    left: isLarge ? 8.r : 6.r,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLarge ? 8.w : 6.w,
                        vertical: isLarge ? 3.h : 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(5.r),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        capturedImage.label,
                        style: TextStyle(
                          fontSize: isLarge ? 10.sp : 9.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),

                // 4. Zoom / Inspection Indicator Icon (Top Right)
                Positioned(
                  top: isLarge ? 8.r : 6.r,
                  right: isLarge ? 8.r : 6.r,
                  child: Container(
                    padding: EdgeInsets.all(isLarge ? 5.r : 4.r),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                      size: isLarge ? 15.sp : 13.sp,
                    ),
                  ),
                ),

                // 5. Bottom Watermarked Timestamp Strip
                if (showTimestamp)
                  Positioned(
                    bottom: isLarge ? 6.r : 5.r,
                    left: isLarge ? 8.r : 6.r,
                    right: isLarge ? 8.r : 6.r,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLarge ? 6.w : 4.w,
                        vertical: isLarge ? 3.h : 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.verified_user_rounded,
                            size: isLarge ? 11.sp : 9.sp,
                            color: const Color(0xFF34D399), // Emerald
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              capturedImage.formattedCapturedAt,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: isLarge ? 8.5.sp : 7.5.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                                fontFeatures: const [FontFeature.tabularFigures()],
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
        ),
      ),
    );
  }

  Widget _buildSimulatedDispenserScreen(bool isLarge) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 8.w : 4.w,
        vertical: isLarge ? 8.h : 4.h,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed_outlined,
                size: isLarge ? 13.sp : 10.sp,
                color: const Color(0xFF34D399),
              ),
              SizedBox(width: 4.w),
              Flexible(
                child: Text(
                  capturedImage.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isLarge ? 9.5.sp : 7.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isLarge ? 3.h : 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              _mockValueForLabel(capturedImage.label),
              style: TextStyle(
                fontSize: isLarge ? 18.sp : 12.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF34D399), // LCD Emerald
                letterSpacing: 0.8,
                fontFamily: 'monospace',
              ),
            ),
          ),
          SizedBox(height: isLarge ? 3.h : 1.h),
          Text(
            'SN-CNG-${(capturedImage.label.hashCode.abs() % 9000 + 1000)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isLarge ? 8.sp : 6.5.sp,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _mockValueForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('vb1')) return '1,450.00 M3';
    if (lower.contains('vs1')) return '1,450.00 M3';
    if (lower.contains('flow')) return '245.8 KG/H';
    if (lower.contains('counter')) return '2,105.85 KG';
    if (lower.contains('micro')) return '2,105.85 KG';
    if (lower.contains('nozzle')) return '1,842.10 KG';
    if (lower.contains('meter')) return '2,104.50 KG';
    return '2,104.50 KG';
  }
}
