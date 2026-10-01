class AuditConfigModel {
  final String operatorName;
  final String operatorId;
  final String stationName;
  final int countdownDurationSeconds;
  final List<String> availableNozzles;
  final String operatorPromptTemplate;
  final String nozzleBottomNoteTemplate;
  final String suiGasBottomNote;

  const AuditConfigModel({
    this.operatorName = 'Ali',
    this.operatorId = '7890',
    this.stationName = 'Main CNG Station',
    this.countdownDurationSeconds = 120,
    this.availableNozzles = const ['Nozzle 1', 'Nozzle 2', 'Nozzle 3', 'Nozzle 4'],
    this.operatorPromptTemplate = 'Ali • Take this pic from {target}',
    this.nozzleBottomNoteTemplate =
        'Ali • Capture snapshot from {target}, Meter, Counter & Micro Motion within 2 minutes.',
    this.suiGasBottomNote =
        'Sui Gas reading requires snapshot of VB1 and VS1 within 2 minutes.',
  });

  factory AuditConfigModel.fromJson(Map<String, dynamic> json) {
    return AuditConfigModel(
      operatorName: json['operatorName'] as String? ?? '',
      operatorId: json['operatorId'] as String? ?? '',
      stationName: json['stationName'] as String? ?? '',
      countdownDurationSeconds:
          (json['countdownDurationSeconds'] as num?)?.toInt() ?? 120,
      availableNozzles: (json['availableNozzles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['Nozzle 1', 'Nozzle 2', 'Nozzle 3', 'Nozzle 4'],
      operatorPromptTemplate: json['operatorPromptTemplate'] as String? ??
          'Take this picture from {target}',
      nozzleBottomNoteTemplate: json['nozzleBottomNoteTemplate'] as String? ??
          'Capture snapshot from {target}, Meter, Counter & Micro Motion within 2 minutes.',
      suiGasBottomNote: json['suiGasBottomNote'] as String? ??
          'Sui Gas reading requires snapshot of VB1 and VS1 within 2 minutes.',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'operatorName': operatorName,
      'operatorId': operatorId,
      'stationName': stationName,
      'countdownDurationSeconds': countdownDurationSeconds,
      'availableNozzles': availableNozzles,
      'operatorPromptTemplate': operatorPromptTemplate,
      'nozzleBottomNoteTemplate': nozzleBottomNoteTemplate,
      'suiGasBottomNote': suiGasBottomNote,
    };
  }

  String formatPrompt(String target) {
    return operatorPromptTemplate.replaceAll('{target}', target);
  }

  String formatBottomNote(String target) {
    return nozzleBottomNoteTemplate.replaceAll('{target}', target);
  }
}
