import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_constants.dart';
import '../../models/pump_station_model.dart';

class PumpAddedSuccessScreen extends StatelessWidget {
  final PumpStation station;

  const PumpAddedSuccessScreen({
    super.key,
    required this.station,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // Celebration Graphic with Green Checkmark
              Stack(
                alignment: Alignment.center,
                children: [
                  // Outer subtle confetti ring
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.figmaEmerald.withValues(alpha: 0.08),
                    ),
                  ),
                  // Decorative confetti dots
                  Positioned(
                    top: 10,
                    left: 20,
                    child: _buildConfettiDot(Colors.amber, 8),
                  ),
                  Positioned(
                    top: 15,
                    right: 25,
                    child: _buildConfettiDot(Colors.blue, 7),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 25,
                    child: _buildConfettiDot(Colors.pinkAccent, 8),
                  ),
                  Positioned(
                    bottom: 25,
                    right: 20,
                    child: _buildConfettiDot(Colors.orange, 7),
                  ),
                  Positioned(
                    top: 60,
                    left: 5,
                    child: _buildConfettiDot(Colors.purpleAccent, 6),
                  ),
                  Positioned(
                    top: 65,
                    right: 8,
                    child: _buildConfettiDot(AppColors.figmaEmerald, 7),
                  ),

                  // Center Checkmark Circle
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.figmaEmerald,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // Headline
              const Text(
                AppConstants.pumpAddedSuccessfully,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),

              // Subtitle
              const Text(
                AppConstants.pumpAddedSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Station Preview Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.headerGray,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_gas_station_rounded,
                      size: 16,
                      color: AppColors.figmaEmerald,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${station.name} • ${station.location}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // CTA: View Pump
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    // Return back to list (Screen 5)
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.figmaPrimaryBtn,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    AppConstants.viewPump,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // CTA: Back to List
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.figmaPrimaryBtn,
                    side: const BorderSide(
                      color: AppColors.figmaPrimaryBtn,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    AppConstants.backToList,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.figmaPrimaryBtn,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfettiDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
