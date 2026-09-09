import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';

class DifferenceHighlightBox extends StatelessWidget {
  final String formattedDifference;
  final bool isCorrupted;

  const DifferenceHighlightBox({
    super.key,
    required this.formattedDifference,
    required this.isCorrupted,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        isCorrupted ? const Color(0xFFFFF0F0) : const Color(0xFFF1F8E9);
    final Color borderColor =
        isCorrupted ? AppColors.alertRedBorder : AppColors.successGreenBorder;
    final Color valueColor =
        isCorrupted ? AppColors.alertRedTitle : AppColors.successGreenTitle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            AppConstants.difference,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            formattedDifference,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
