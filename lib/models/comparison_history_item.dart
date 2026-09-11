import '../constants/app_constants.dart';
import 'comparison_result_model.dart';

/// A single saved record shown on the History screen, built from a
/// [ComparisonResultModel] at the moment a comparison was run.
class ComparisonHistoryItem {
  final String id;
  final DateTime timestamp;
  final ComparisonResultModel result;

  ComparisonHistoryItem({
    required this.id,
    required this.timestamp,
    required this.result,
  });

  factory ComparisonHistoryItem.fromResult(ComparisonResultModel result) {
    return ComparisonHistoryItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      result: result,
    );
  }

  bool get isCorrupted => result.isCorruptionDetected;

  /// Signed variance for display (e.g. "+0.45 KG" / "-1.35 KG"), derived
  /// from the primary (Digital Machine) reading against Manual Data.
  double get signedVariance {
    final digital = result.digitalReading;
    final manual = result.manualReading;
    if (digital != null && manual != null) {
      return digital - manual;
    }
    return result.isCorruptionDetected ? result.difference : -result.difference;
  }

  String get formattedVariance {
    final v = signedVariance;
    final sign = v >= 0 ? '+' : '-';
    return '$sign${v.abs().toStringAsFixed(2)} ${AppConstants.weightUnit}';
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String get formattedDateTime {
    final month = _months[timestamp.month - 1];
    final hour24 = timestamp.hour;
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$month ${timestamp.day}, ${timestamp.year} • '
        '${hour12.toString().padLeft(2, '0')}:$minute';
  }
}
