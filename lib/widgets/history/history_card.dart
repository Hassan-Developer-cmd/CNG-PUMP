import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/comparison_history_item.dart';

/// A single row on the History screen: colored edge + status badge +
/// a 2-column grid of the readings captured for that comparison, plus a
/// signed variance highlight box. Tapping it reopens the full result.
class HistoryCard extends StatelessWidget {
  final ComparisonHistoryItem record;
  final VoidCallback? onTap;

  const HistoryCard({super.key, required this.record, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool corrupted = record.isCorrupted;
    final Color edgeColor = corrupted
        ? AppColors.alertRedIcon
        : AppColors.successGreenIcon;
    final Color badgeBg = corrupted
        ? AppColors.alertRedBg
        : AppColors.successGreenBg;
    final Color badgeText = corrupted
        ? AppColors.alertRedTitle
        : AppColors.successGreenTitle;
    final Color varianceBg = corrupted
        ? AppColors.alertRedBg
        : AppColors.headerGray;
    final Color varianceText = corrupted
        ? AppColors.alertRedTitle
        : AppColors.successGreenTitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
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
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5.w,
                  decoration: BoxDecoration(
                    color: edgeColor,
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(16.r),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(16),
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
                            Icon(
                              Icons.chevron_right,
                              size: 20.sp,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                corrupted
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle,
                                size: 13.sp,
                                color: badgeText,
                              ),
                              SizedBox(width: 5.w),
                              Text(
                                corrupted
                                    ? AppConstants.corruptionDetected
                                    : AppConstants.noCorruption,
                                style: TextStyle(
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w700,
                                  color: badgeText,
                                  letterSpacing: 0.3.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 14.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _valueColumn(
                                record.result.primaryLabel,
                                record.result.formattedDigital,
                              ),
                            ),
                            SizedBox(width: 12.w),
                            Expanded(
                              child: _valueColumn(
                                AppConstants.manualData,
                                record.result.formattedManual,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _valueColumn(
                                AppConstants.microMotion,
                                record.result.formattedMicroMotion,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _valueColumn(
                                AppConstants.suiGas,
                                record.result.formattedSuiGas,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14.h),
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: varianceBg,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                AppConstants.variance,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                record.formattedVariance,
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w800,
                                  color: varianceText,
                                ),
                              ),
                            ],
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

  Widget _valueColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
