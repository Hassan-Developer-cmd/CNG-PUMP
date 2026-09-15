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
  final Function(String text) onTextChanged;
  final VoidCallback? onCustomCameraRequested;

  const CngReadingCard({
    super.key,
    required this.item,
    required this.onImageCaptured,
    required this.onTextChanged,
    this.onCustomCameraRequested,
  });

  @override
  State<CngReadingCard> createState() => _CngReadingCardState();
}

class _CngReadingCardState extends State<CngReadingCard> {
  late final TextEditingController _controller;

  final ImagePicker _picker = ImagePicker();

  File? _vb1Image;
  File? _vs1Image;
  File? _rFlowImage;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(text: widget.item.extractedText);
  }

  @override
  void didUpdateWidget(covariant CngReadingCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.item.extractedText != _controller.text &&
        !widget.item.isLoading) {
      _controller.value = TextEditingValue(
        text: widget.item.extractedText,
        selection: TextSelection.collapsed(
          offset: widget.item.extractedText.length,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // BORDER COLOR
  Color get _borderColor {
    if (widget.item.isRequired) {
      return widget.item.hasText || widget.item.hasImage
          ? AppColors.dashedTeal
          : AppColors.dashedRed;
    }

    return AppColors.dashedGreen;
  }

  // NORMAL CAMERA
  Future<void> _handlePictureTap() async {
    if (widget.item.isLoading) return;

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

      if (photo != null) {
        widget.onImageCaptured(File(photo.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  // SUI GAS CAMERA
  Future<void> _captureSuiGasImage(String type) async {
    if (widget.item.isLoading) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 100,
      );

      if (photo == null) return;

      final File image = File(photo.path);

      setState(() {
        switch (type) {
          case 'VB1':
            _vb1Image = image;
            break;

          case 'VS1':
            _vs1Image = image;
            break;

          case 'R Flow':
            _rFlowImage = image;
            break;
        }
      });
    } catch (e) {
      debugPrint('Error capturing Sui Gas image: $e');
    }
  }

  // MAIN BUILD
  @override
  Widget build(BuildContext context) {
    final bool isSuiGas = widget.item.type == CngReadingType.suiGas;

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
          // HEADER
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 30.w,
                height: 30.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 17.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 9.w),
              Expanded(
                child: Text(
                  widget.item.title,
                  style: AppTypography.sectionTitle,
                ),
              ),
              StatusBadge(isRequired: widget.item.isRequired),
            ],
          ),
          SizedBox(height: 13.h),
          // CONTENT
          if (isSuiGas)
            _buildSuiGasContent()
          else ...[
            _buildPictureBox(),
            SizedBox(height: 10.h),
            _buildInputDataBox(),
          ],

          // ERROR
          if (widget.item.error != null && widget.item.error!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              child: Text(
                widget.item.error!,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.alertRedTitle,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // NORMAL PICTURE BOX
  Widget _buildPictureBox() {
    return DashedBorderBox(
      borderColor: _borderColor,
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
        child: widget.item.isLoading
            ? _buildLoadingContent()
            : widget.item.hasImage
            ? _buildCapturedImage(widget.item.image!)
            : _buildEmptyPictureContent(),
      ),
    );
  }

  // EMPTY PICTURE CONTENT
  Widget _buildEmptyPictureContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 24.sp,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 5.h),
        Text(
          AppConstants.takePicture,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // LOADING
  Widget _buildLoadingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24.w,
          height: 24.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
        ),
        SizedBox(height: 7.h),
        Text(
          'Extracting text...',
          style: TextStyle(fontSize: 10.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // CAPTURED IMAGE
  Widget _buildCapturedImage(File image) {
    return ClipRRect(
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
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 12.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Retake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // INPUT DATA BOX
  Widget _buildInputDataBox() {
    return DashedBorderBox(
      borderColor: _borderColor,
      backgroundColor: const Color(0xFFFCFDFD),
      borderRadius: 8.r,
      strokeWidth: 1.r,
      dashLength: 3.r,
      dashGap: 2.r,
      padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 7.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppConstants.inputData,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _controller,
            enabled: !widget.item.isLoading,
            onChanged: widget.onTextChanged,
            style: TextStyle(fontSize: 11.sp, color: AppColors.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 2.h),
              border: InputBorder.none,
              hintText: AppConstants.inputDataHint,
              hintStyle: TextStyle(
                fontSize: 10.sp,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // SUI GAS CONTENT
  Widget _buildSuiGasContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // VB1
        _buildSuiGasPictureBox(label: 'VB1', image: _vb1Image),
        SizedBox(height: 10.h),

        // VS1
        _buildSuiGasPictureBox(label: 'VS1', image: _vs1Image),
        SizedBox(height: 10.h),

        // R FLOW
        _buildSuiGasPictureBox(label: 'R Flow', image: _rFlowImage),

        // INPUT DATA BOX
        SizedBox(height: 12.h),

        _buildInputDataBox(),
      ],
    );
  }

  // SUI GAS IMAGE BOX

  Widget _buildSuiGasPictureBox({required String label, required File? image}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        DashedBorderBox(
          borderColor: _borderColor,
          backgroundColor: const Color(0xFFFCFDFD),
          borderRadius: 8.r,
          strokeWidth: 1.r,
          dashLength: 3.r,
          dashGap: 2.r,
          padding: EdgeInsets.zero,
          onTap: () => _captureSuiGasImage(label),
          child: SizedBox(
            width: double.infinity,
            height: 105.h,
            child: image == null
                ? _buildSuiGasEmptyContent()
                : _buildSuiGasCapturedImage(image),
          ),
        ),

        // LABEL
        Positioned(
          left: 10.w,
          top: -6.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(5.r),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 8.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // SUI GAS EMPTY CONTENT
  Widget _buildSuiGasEmptyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 24.sp,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 5.h),
        Text(
          AppConstants.takePicture,
          style: TextStyle(
            fontSize: 10.sp,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // SUI GAS CAPTURED IMAGE
  Widget _buildSuiGasCapturedImage(File image) {
    return ClipRRect(
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
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}
