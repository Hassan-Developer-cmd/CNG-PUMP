import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../constants/app_typography.dart';
import '../../models/comparison_result_model.dart';
import 'difference_highlight_box.dart';

class ComparisonDetailsCard extends StatelessWidget {
  final ComparisonResultModel result;

  const ComparisonDetailsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.headerGray,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Text(
              AppConstants.comparisonDetails,
              style: AppTypography.cardHeader,
            ),
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Digital Machine & Manual Data
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildItem(
                        label: result.primaryLabel,
                        value: result.formattedDigital,
                        isProvided:
                            result.formattedDigital != AppConstants.notProvided,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildItem(
                        label: AppConstants.manualData,
                        value: result.formattedManual,
                        isProvided:
                            result.formattedManual != AppConstants.notProvided,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Row 2: Micro Motion & Sui Gas
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildItem(
                        label: AppConstants.microMotion,
                        value: result.formattedMicroMotion,
                        isProvided:
                            result.formattedMicroMotion !=
                            AppConstants.notProvided,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildItem(
                        label: AppConstants.suiGas,
                        value: result.formattedSuiGas,
                        isProvided:
                            result.formattedSuiGas != AppConstants.notProvided,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                // Difference Highlight Box
                DifferenceHighlightBox(
                  formattedDifference: result.formattedDifference,
                  isCorrupted: result.isCorruptionDetected,
                ),

                const SizedBox(height: 14),

                // Threshold Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppConstants.threshold,
                      style: AppTypography.detailLabel,
                    ),
                    Text(
                      result.formattedThreshold,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required String value,
    required bool isProvided,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.detailLabel),
        const SizedBox(height: 4),
        Text(
          value,
          style: isProvided
              ? AppTypography.detailValue
              : AppTypography.detailLabel.copyWith(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  fontStyle: FontStyle.normal,
                ),
        ),
      ],
    );
  }
}
