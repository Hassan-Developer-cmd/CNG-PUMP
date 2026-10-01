import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';

enum AsyncStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class AsyncStateView extends StatelessWidget {
  final AsyncStatus status;
  final Widget child;
  final VoidCallback? onRetry;
  final String? errorMessage;
  final String emptyTitle;
  final String emptySubtitle;
  final IconData emptyIcon;
  final Widget? loadingWidget;

  const AsyncStateView({
    super.key,
    required this.status,
    required this.child,
    this.onRetry,
    this.errorMessage,
    this.emptyTitle = 'No Records Found',
    this.emptySubtitle = 'There are no items to display at this time.',
    this.emptyIcon = Icons.inbox_outlined,
    this.loadingWidget,
  });

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case AsyncStatus.loading:
      case AsyncStatus.initial:
        return loadingWidget ?? _buildDefaultLoading();

      case AsyncStatus.error:
        return _buildErrorState(context);

      case AsyncStatus.empty:
        return _buildEmptyState(context);

      case AsyncStatus.loaded:
        return child;
    }
  }

  Widget _buildDefaultLoading() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.figmaEmerald),
              strokeWidth: 2.8,
            ),
            SizedBox(height: 14.h),
            Text(
              'Loading data...',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36.sp,
                color: Colors.red.shade700,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              'Failed to Load Data',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              errorMessage ?? 'A network or server error occurred. Please try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.figmaEmerald,
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: AppColors.figmaEmerald.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                emptyIcon,
                size: 36.sp,
                color: AppColors.figmaEmerald,
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              emptyTitle,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              emptySubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              SizedBox(height: 16.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.figmaEmerald,
                  side: const BorderSide(color: AppColors.figmaEmerald),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
