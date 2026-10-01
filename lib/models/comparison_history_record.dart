class ComparisonHistoryRecord {
  final String dateTitle;
  final bool hasCorruption;
  final String statusText;
  final Map<String, String> sources;
  final String difference;
  final bool isNegativeDifference;

  const ComparisonHistoryRecord({
    required this.dateTitle,
    required this.hasCorruption,
    required this.statusText,
    required this.sources,
    required this.difference,
    this.isNegativeDifference = false,
  });

  factory ComparisonHistoryRecord.fromJson(Map<String, dynamic> json) {
    return ComparisonHistoryRecord(
      dateTitle: json['dateTitle'] as String? ?? '',
      hasCorruption: json['hasCorruption'] as bool? ?? false,
      statusText: json['statusText'] as String? ?? '',
      sources: (json['sources'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          const {},
      difference: json['difference'] as String? ?? '+0.00 KG',
      isNegativeDifference: json['isNegativeDifference'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateTitle': dateTitle,
      'hasCorruption': hasCorruption,
      'statusText': statusText,
      'sources': sources,
      'difference': difference,
      'isNegativeDifference': isNegativeDifference,
    };
  }
}
