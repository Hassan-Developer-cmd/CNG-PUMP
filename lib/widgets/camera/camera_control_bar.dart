import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CameraControlBar extends StatelessWidget {
  final VoidCallback onCapture;
  final VoidCallback? onHistoryOrGallery;
  final VoidCallback? onSwitchCamera;
  final bool isCapturing;

  const CameraControlBar({
    super.key,
    required this.onCapture,
    this.onHistoryOrGallery,
    this.onSwitchCamera,
    this.isCapturing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120.h,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Camera Switch Action or Spacer
          if (onSwitchCamera != null)
            IconButton(
              icon: Icon(
                Icons.flip_camera_ios_outlined,
                color: Colors.white,
                size: 30.sp,
              ),
              tooltip: 'Switch Camera',
              onPressed: isCapturing ? null : onSwitchCamera,
            )
          else
            SizedBox(width: 48.w),

          // Center Shutter Button
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: Container(
              width: 78.w,
              height: 78.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4.w),
              ),
              child: Center(
                child: isCapturing
                    ? SizedBox(
                        width: 32.w,
                        height: 32.h,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Container(
                        width: 62.w,
                        height: 62.h,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),

          // Right History / Gallery Action
          IconButton(
            icon: Icon(Icons.history, color: Colors.white, size: 32.sp),
            tooltip: 'Choose from Gallery',
            onPressed: isCapturing ? null : onHistoryOrGallery,
          ),
        ],
      ),
    );
  }
}
