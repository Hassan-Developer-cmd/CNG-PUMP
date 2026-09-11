class AppConstants {
  AppConstants._();

  static const String appName = 'CNG Hub';
  static const String appLogo = 'assets/images/app_logo.png';
  static const String comparisonResultTitle = 'Comparison Result';
  static const String scanMeterTitle = 'Scan Meter';
  static const String defaultUserName = 'Ali';

  // Units & Thresholds
  static const String weightUnit = 'KG';
  static const double defaultToleranceThreshold = 1.0; // 1 KG

  // Reading section names
  static const String digitalMachine = 'Digital Machine';
  static const String manualData = 'Manual Data';
  static const String microMotion = 'Micro Motion';
  static const String suiGas = 'Sui Gas';

  // Nozzle / Meter primary-source toggle
  static const String nozzleLabel = 'Nozzle';
  static const String meterLabel = 'Meter';
  static const String selectSourceLabel = 'Select Nozzle';

  // Badges
  static const String requiredBadge = 'REQUIRED';
  static const String optionalBadge = 'OPTIONAL';

  // Bottom navigation
  static const String navInputCompare = 'Input & Compare';
  static const String navHistory = 'History';

  // History screen
  static const String historyTitle = 'Comparison History';
  static const String historySubtitle = 'Recent diagnostic comparison logs.';
  static const String loadMoreRecords = 'Load More Records';
  static const String noCorruption = 'NO CORRUPTION';
  static const String corruptionDetected = 'CORRUPTION DETECTED';
  static const String variance = 'Variance';
  static const String noHistoryYet = 'No comparison records yet.';
  static const String noHistorySubtitle =
      'Records will appear here after you compare readings.';

  // Comparing (progress) screen
  static const String comparingDataTitle = 'Comparing Data';
  static const String comparingYourData = 'Comparing Your Data';
  static const String comparingSubtitle =
      'Please wait while we compare the submitted readings.';
  static const String processingSources = 'PROCESSING SOURCES';
  static const String includedIfProvided = 'Included if provided';

  // Prompts & Labels
  static const String takePicture = 'Take Picture';
  static const String inputData = 'Input Data';
  static const String inputDataHint = 'Type Your Data.........';
  static const String compareData = 'Compare Data';
  static const String done = 'Done';
  static const String comparisonDetails = 'COMPARISON DETAILS';
  static const String difference = 'Difference';
  static const String threshold = 'Threshold';
  static const String notProvided = 'Not Provided';

  // Informational text
  static const String infoNoteText =
      'Digital Machine, Manual Data and Micro Motion are required inputs. '
      'Sui Gas is optional based on current operational phase. '
      'Ensure pictures are clear before submitting.';

  static const String alignDisplayPrompt = 'Align display within frame';

  // Alerts
  static const String corruptionDetectedTitle = 'Corruption Detected';
  static const String corruptionDetectedMessage =
      'The difference between the compared readings is more than 1 KG.';

  static const String verifiedTitle = 'Readings Verified';
  static const String verifiedMessage =
      'The difference between the compared readings is within the 1 KG threshold.';
}
