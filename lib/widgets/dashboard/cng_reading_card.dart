import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../models/cng_reading_item.dart';
import '../shared_widgets/dashed_border_box.dart';
import '../shared_widgets/status_badge.dart';

class CngReadingCard extends StatefulWidget {
  final CngReadingItem item;
  final Function(File image) onImageCaptured;
  final Function(String text) onInputDataChanged;
  final VoidCallback? onCustomCameraRequested;

  const CngReadingCard({
    super.key,
    required this.item,
    required this.onImageCaptured,
    required this.onInputDataChanged,
    this.onCustomCameraRequested,
  });

  @override
  State<CngReadingCard> createState() => _CngReadingCardState();
}

class _CngReadingCardState extends State<CngReadingCard> {
  late final TextEditingController _controller;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.item.inputData);
  }

  @override
  void didUpdateWidget(covariant CngReadingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.inputData != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.item.inputData,
        selection: TextSelection.collapsed(offset: widget.item.inputData.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  Future<void> _handlePictureTap() async {
    if (widget.onCustomCameraRequested != null) {
      widget.onCustomCameraRequested!();
      return;
    }
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );
      if (photo != null) widget.onImageCaptured(File(photo.path));
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 6.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(widget.item.icon, size: 17.sp, color: AppColors.primaryTeal),
              ),
              SizedBox(width: 9.w),
              Expanded(child: Text(widget.item.title, style: AppTypography.sectionTitle)),
              StatusBadge(isRequired: widget.item.isRequired),
            ],
          ),
          SizedBox(height: 13.h),
          _buildPictureBox(),
          SizedBox(height: 10.h),
          _buildInputDataBox(),
        ],
      ),
    );
  }

  Widget _buildPictureBox() {
    return DashedBorderBox(
      borderColor: widget.item.hasImage ? AppColors.dashedTeal : AppColors.dashedRed,
      backgroundColor: const Color(0xFFFCFDFD),
      borderRadius: 8.r,
      strokeWidth: 1.r,
      dashLength: 3.r,
      dashGap: 2.r,
      padding: EdgeInsets.zero,
      onTap: _handlePictureTap,
      child: SizedBox(
        height: 105.h,
        width: double.infinity,
        child: widget.item.hasImage
            ? _buildCapturedImage(widget.item.image!)
            : _buildEmptyPictureContent(),
      ),
    );
  }

  Widget _buildEmptyPictureContent() => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt_outlined, size: 24.sp, color: AppColors.textPrimary),
          SizedBox(height: 5.h),
          Text(AppConstants.takePicture, style: TextStyle(fontSize: 10.sp, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
        ],
      );

  Widget _buildCapturedImage(File image) => ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(image, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.22)),
            Positioned(
              right: 7.w,
              bottom: 7.h,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.65), borderRadius: BorderRadius.circular(5.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 12.sp),
                  SizedBox(width: 4.w),
                  Text('Retake', style: TextStyle(color: Colors.white, fontSize: 9.sp, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      );

  Widget _buildInputDataBox() {
    return DashedBorderBox(
      // Input Data is optional, so an empty field is not shown as an error.
      borderColor: widget.item.hasInputData
          ? AppColors.dashedTeal
          : AppColors.borderLight,
      backgroundColor: const Color(0xFFFCFDFD),
      borderRadius: 8.r,
      strokeWidth: 1.r,
      dashLength: 3.r,
      dashGap: 2.r,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConstants.inputData, style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          SizedBox(height: 1.h),
          TextField(
            controller: _controller,
            onChanged: widget.onInputDataChanged,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 2.h),
              border: InputBorder.none,
              hintText: AppConstants.inputDataHint,
              hintStyle: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary.withValues(alpha: 0.7)),
            ),
          ),
        ],
      ),
    );
  }
}
