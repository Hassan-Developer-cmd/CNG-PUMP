class AppConstants {
  AppConstants._();

  static const String appName = 'CNG Hub';
  static const String appLogo = 'assets/images/app_logo.png';
  static const String resultTitle = 'Result';
  static const String scanMeterTitle = 'Scan Meter';
  static const String defaultUserName = 'Ali';

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
  static const String navInputCompare = 'Capture';
  static const String navHistory = 'History';

  // History
  static const String historyTitle = 'Capture History';
  static const String historySubtitle = 'Your recently captured pictures.';
  static const String loadMoreRecords = 'Load More Records';
  static const String noHistoryYet = 'No capture records yet.';
  static const String noHistorySubtitle =
      'Records will appear here after you capture pictures.';

  // Prompts & Labels
  static const String takePicture = 'Take Picture';
  static const String saveData = 'Save Data';
  static const String done = 'Done';
  static const String capturedPictures = 'CAPTURED PICTURES';
  static const String resultSubtitle =
      'Your captured pictures are shown below.';

  // Informational text
  static const String infoNoteText =
      'Capture the sources in order. After each required picture, the next required picture must be captured within 2 minutes. '
      'Micro Motion is optional.';

  static const String alignDisplayPrompt = 'Align display within frame';
}
