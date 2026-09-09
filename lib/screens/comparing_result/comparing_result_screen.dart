import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../providers/text_comparison_provider.dart';
import '../../widgets/shared_widgets/custom_app_bar.dart';
import '../../widgets/shared_widgets/custom_primary_button.dart';
import '../../widgets/comparison/comparison_details_card.dart';
import '../../widgets/comparison/corruption_alert_banner.dart';

class ComparingResultScreen extends StatelessWidget {
  const ComparingResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TextComparisonProvider>(
      builder: (context, provider, child) {
        final result = provider.comparisonResult;

        return Scaffold(
          backgroundColor: AppColors.scaffoldBackground,
          appBar: CustomCurvedAppBar(
            title: AppConstants.comparisonResultTitle,
            showBackButton: true,
            onBackPressed: () => Navigator.of(context).pop(),
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Alert Banner (Corruption Detected / Verified)
                      CorruptionAlertBanner(
                        isCorrupted: result.isCorruptionDetected,
                        title: result.alertTitle,
                        message: result.alertMessage,
                      ),
                      const SizedBox(height: 20),

                      // Comparison Details Card
                      ComparisonDetailsCard(result: result),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom Sticky "Done" Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: CustomPrimaryButton(
                    text: AppConstants.done,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
