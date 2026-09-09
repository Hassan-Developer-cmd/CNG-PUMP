import 'package:flutter/material.dart';

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
      height: 120,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Camera Switch Action or Spacer
          if (onSwitchCamera != null)
            IconButton(
              icon: const Icon(
                Icons.flip_camera_ios_outlined,
                color: Colors.white,
                size: 30,
              ),
              tooltip: 'Switch Camera',
              onPressed: isCapturing ? null : onSwitchCamera,
            )
          else
            const SizedBox(width: 48),

          // Center Shutter Button
          GestureDetector(
            onTap: isCapturing ? null : onCapture,
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: isCapturing
                    ? const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Container(
                        width: 62,
                        height: 62,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
              ),
            ),
          ),

          // Right History / Gallery Action
          IconButton(
            icon: const Icon(
              Icons.history,
              color: Colors.white,
              size: 32,
            ),
            tooltip: 'Choose from Gallery',
            onPressed: isCapturing ? null : onHistoryOrGallery,
          ),
        ],
      ),
    );
  }
}
