import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../models/capture_history_item.dart';

class HistoryCard extends StatelessWidget {
  final CaptureHistoryItem record;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8.r,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.formattedDateTime,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20.sp, color: AppColors.textMuted),
                ],
              ),
              SizedBox(height: 12.h),
              SizedBox(
                height: 100.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: record.images.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) {
                    final captured = record.images[index];
                    return SizedBox(
                      width: 110.w,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.r),
                              child: Image.file(
                                captured.image,
                                width: 110.w,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            captured.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time_outlined,
                                size: 8.sp,
                                color: AppColors.primaryTeal,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  captured.formattedCapturedAt,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 7.5.sp,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
