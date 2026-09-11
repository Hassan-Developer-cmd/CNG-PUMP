import '../constants/app_constants.dart';
import '../utils/reading_parser.dart';

class ComparisonResultModel {
  final double? digitalReading;
  final double? manualReading;
  final double? microMotionReading;
  final double? suiGasReading;
  final double difference;
  final double threshold;
  final bool isCorruptionDetected;
  final String rawDigitalText;
  final String rawManualText;
  final String rawMicroMotionText;
  final String rawSuiGasText;

  /// Label for the first ("primary") reading at the time of comparison —
  /// either "Digital Machine" (Nozzle mode) or "Meter" (Meter mode).
  final String primaryLabel;

  ComparisonResultModel({
    this.digitalReading,
    this.manualReading,
    this.microMotionReading,
    this.suiGasReading,
    required this.difference,
    this.threshold = AppConstants.defaultToleranceThreshold,
    required this.isCorruptionDetected,
    this.rawDigitalText = '',
    this.rawManualText = '',
    this.rawMicroMotionText = '',
    this.rawSuiGasText = '',
    this.primaryLabel = AppConstants.digitalMachine,
  });

  String get formattedDigital =>
      ReadingParser.formatWeight(digitalReading).replaceAll('KG', '').trim().isNotEmpty && digitalReading != null
          ? ReadingParser.formatWeight(digitalReading)
          : (rawDigitalText.isNotEmpty ? rawDigitalText : AppConstants.notProvided);

  String get formattedManual =>
      ReadingParser.formatWeight(manualReading).replaceAll('KG', '').trim().isNotEmpty && manualReading != null
          ? ReadingParser.formatWeight(manualReading)
          : (rawManualText.isNotEmpty ? rawManualText : AppConstants.notProvided);

  String get formattedMicroMotion =>
      ReadingParser.formatWeight(microMotionReading).replaceAll('KG', '').trim().isNotEmpty && microMotionReading != null
          ? ReadingParser.formatWeight(microMotionReading)
          : (rawMicroMotionText.isNotEmpty ? rawMicroMotionText : AppConstants.notProvided);

  String get formattedSuiGas =>
      ReadingParser.formatWeight(suiGasReading).replaceAll('KG', '').trim().isNotEmpty && suiGasReading != null
          ? ReadingParser.formatWeight(suiGasReading)
          : (rawSuiGasText.isNotEmpty ? rawSuiGasText : AppConstants.notProvided);

  String get formattedDifference =>
      '${difference.toStringAsFixed(2)} ${AppConstants.weightUnit}';

  String get formattedThreshold =>
      '${threshold.toStringAsFixed(0)} ${AppConstants.weightUnit}';

  String get alertTitle => isCorruptionDetected
      ? AppConstants.corruptionDetectedTitle
      : AppConstants.verifiedTitle;

  String get alertMessage => isCorruptionDetected
      ? AppConstants.corruptionDetectedMessage
      : AppConstants.verifiedMessage;
}
