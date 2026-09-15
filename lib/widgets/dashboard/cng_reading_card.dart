import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../models/cng_reading_item.dart';
import '../shared_widgets/dashed_border_box.dart';
import '../shared_widgets/source_selector_dropdown.dart';
import '../shared_widgets/status_badge.dart';

class CngReadingCard extends StatefulWidget {
  final CngReadingItem item;
  final Function(File image) onImageCaptured;
  final Function(String text) onTextChanged;
  final VoidCallback? onCustomCameraRequested;

  // First card only.
  final bool showSourceSelector;
  final PrimarySourceMode? selectedSource;
  final ValueChanged<PrimarySourceMode>? onSourceChanged;

  const CngReadingCard({
    super.key,
    required this.item,
    required this.onImageCaptured,
    required this.onTextChanged,
    this.onCustomCameraRequested,
    this.showSourceSelector = false,
    this.selectedSource,
    this.onSourceChanged,
  });

  @override
  State<CngReadingCard> createState() => _CngReadingCardState();
}

class _CngReadingCardState extends State<CngReadingCard> {
  late final TextEditingController _controller;

  final ImagePicker _picker = ImagePicker();

  // Sui Gas has three independent image areas.
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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                width: 32.w,
                height: 32.h,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 18.sp,
                  color: AppColors.primaryTeal,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  widget.item.title,
                  style: AppTypography.sectionTitle,
                ),
              ),
              StatusBadge(isRequired: widget.item.isRequired),
            ],
          ),
          // SOURCE SELECTOR
          if (widget.showSourceSelector) ...[
            SizedBox(height: 12.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SourceSelectorDropdown(
                  selected: widget.selectedSource ?? PrimarySourceMode.nozzle,
                  onChanged: widget.onSourceChanged ?? (_) {},
                ),
              ],
            ),
          ],
          SizedBox(height: 14.h),
          // SUI GAS SPECIAL LAYOUT
          if (isSuiGas)
            _buildSuiGasContent()
          else ...[
            _buildPictureBox(),
            SizedBox(height: 12.h),
            _buildInputDataBox(),
          ],

          // ERROR
          if (widget.item.error != null && widget.item.error!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                widget.item.error!,
                style: TextStyle(
                  fontSize: 12.sp,
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
      borderRadius: 12.r,
      onTap: _handlePictureTap,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 110.h,
        width: double.infinity,
        child: widget.item.isLoading
            ? _buildLoadingContent()
            : widget.item.hasImage
            ? _buildCapturedImage(widget.item.image!)
            : _buildEmptyPictureContent(),
      ),
    );
  }

  // LOADING
  Widget _buildLoadingContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 26.w,
          height: 26.h,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryTeal),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Extracting text...',
          style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  // EMPTY CAMERA
  Widget _buildEmptyPictureContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt_outlined,
          size: 28.sp,
          color: AppColors.textPrimary,
        ),
        SizedBox(height: 6.h),
        Text(AppConstants.takePicture, style: AppTypography.actionLabel),
      ],
    );
  }

  // CAPTURED IMAGE
  Widget _buildCapturedImage(File image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(image, fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.25)),
          Positioned(
            right: 8.w,
            bottom: 8.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, color: Colors.white, size: 14.sp),
                  SizedBox(width: 4.w),
                  Text(
                    'Retake',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
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

  // INPUT DATA
  Widget _buildInputDataBox() {
    return DashedBorderBox(
      borderColor: _borderColor,
      borderRadius: 12.r,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppConstants.inputData, style: AppTypography.inputLabel),
          SizedBox(height: 2.h),
          TextField(
            controller: _controller,
            enabled: !widget.item.isLoading,
            onChanged: widget.onTextChanged,
            style: AppTypography.inputText,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 4.h),
              border: InputBorder.none,
              hintText: AppConstants.inputDataHint,
              hintStyle: AppTypography.inputHint,
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
        Row(
          children: [
            Expanded(
              child: _buildSuiGasPictureBox(label: 'VB1', image: _vb1Image),
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: _buildSuiGasPictureBox(label: 'VS1', image: _vs1Image),
            ),

            SizedBox(width: 8.w),

            Expanded(
              child: _buildSuiGasPictureBox(
                label: 'R Flow',
                image: _rFlowImage,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        _buildInputDataBox(),
      ],
    );
  }

  // SUI GAS INDIVIDUAL IMAGE BOX
  Widget _buildSuiGasPictureBox({required String label, required File? image}) {
    return DashedBorderBox(
      borderColor: _borderColor,
      borderRadius: 12.r,
      onTap: () => _captureSuiGasImage(label),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 105.h,
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 25.sp,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover),
                    Container(color: Colors.black.withValues(alpha: 0.25)),
                    Positioned(
                      left: 6.w,
                      top: 6.h,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6.w,
                      bottom: 6.h,
                      child: Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
