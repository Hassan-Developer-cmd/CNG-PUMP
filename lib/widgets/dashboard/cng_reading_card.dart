import 'dart:io';
import 'package:flutter/material.dart';
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

  Color get _borderColor {
    if (widget.item.isRequired) {
      return widget.item.hasText || widget.item.hasImage
          ? AppColors.dashedTeal
          : AppColors.dashedRed;
    }
    return AppColors.dashedGreen;
  }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Icon + Title + Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lightTeal,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.item.icon,
                  size: 18,
                  color: AppColors.primaryTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.title,
                  style: AppTypography.sectionTitle,
                ),
              ),
              StatusBadge(isRequired: widget.item.isRequired),
            ],
          ),
          const SizedBox(height: 14),

          // Picture Box
          _buildPictureBox(),
          const SizedBox(height: 12),

          // Input Data Box
          _buildInputDataBox(),

          // Error or status note if any
          if (widget.item.error != null && widget.item.error!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                widget.item.error!,
                style: const TextStyle(
                  fontSize: 12,
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

  Widget _buildPictureBox() {
    return DashedBorderBox(
      borderColor: _borderColor,
      borderRadius: 12,
      onTap: _handlePictureTap,
      padding: EdgeInsets.zero,
      child: Container(
        height: 110,
        width: double.infinity,
        alignment: Alignment.center,
        child: widget.item.isLoading
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryTeal,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Extracting text...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              )
            : widget.item.hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          widget.item.image!,
                          width: double.infinity,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black.withValues(alpha: 0.25),
                        ),
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Retake',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 28,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(height: 6),
                      Text(
                        AppConstants.takePicture,
                        style: AppTypography.actionLabel,
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildInputDataBox() {
    return DashedBorderBox(
      borderColor: _borderColor,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppConstants.inputData,
            style: AppTypography.inputLabel,
          ),
          const SizedBox(height: 2),
          TextField(
            controller: _controller,
            enabled: !widget.item.isLoading,
            onChanged: widget.onTextChanged,
            style: AppTypography.inputText,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: InputBorder.none,
              hintText: AppConstants.inputDataHint,
              hintStyle: AppTypography.inputHint,
            ),
          ),
        ],
      ),
    );
  }
}
