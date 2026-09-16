import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';

/// Clean exit confirmation dialog matching the CNG Hub theme.
class ExitConfirmationDialog extends StatelessWidget {
  const ExitConfirmationDialog({super.key});

  /// Displays the confirmation dialog.
  /// If the user confirms exit, closes the application via [SystemNavigator.pop].
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => const ExitConfirmationDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      backgroundColor: Colors.white,
      titlePadding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 8.h),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
      actionsPadding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: AppColors.lightTeal,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.exit_to_app,
              color: AppColors.primaryTeal,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Exit App?',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: Text(
        'Are you sure you want to exit the app?',
        style: TextStyle(
          fontSize: 13.sp,
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            foregroundColor: AppColors.textSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            SystemNavigator.pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          child: Text(
            'Exit',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
