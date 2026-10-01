class AppConstants {
  AppConstants._();

  static const String appName = 'CNG Hub';
  static const String appLogo = 'assets/image.jpg';
  static const String resultTitle = 'Result';
  static const String scanMeterTitle = 'Scan Meter';
  static const String defaultUserName = 'Ali';

  // Reading section names
  static const String digitalMachine = 'Digital Machine';
  static const String manualData = 'Manual Data';
  static const String microMotion = 'Micro Motion';
  static const String suiGas = 'Sui Gas';

  static const String nozzle1 = 'Nozzle 1';
  static const String nozzle2 = 'Nozzle 2';
  static const String nozzle3 = 'Nozzle 3';
  static const String nozzle4 = 'Nozzle 4';

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
      'Digital Machine, Micro Motion and Sui Gas Reading requires one snapshot each. Nozzle 1 & Nozzle 2 each snapshot within 2 minutes.';

  static const String alignDisplayPrompt = 'Align display within frame';

  // Admin Flow Constants
  static const String pumpAdminSubtitle = 'Pump Admin';
  static const String brandTagline = 'Secure • Reliable • CNG Solution';
  static const String navPumps = 'Pumps';
  static const String navSettings = 'Settings';
  static const String addNewPump = 'Add New Pump';
  static const String pumpInformation = 'Pump Information';
  static const String pumpAddedSuccessfully = 'Pump Added Successfully!';
  static const String pumpAddedSubtitle =
      'The new pump has been added to the system.';
  static const String viewPump = 'View Pump';
  static const String backToList = 'Back to List';

  // Station Categories
  static const String catFuelPump = 'Fuel Pump';
  static const String catVehicle = 'Vehicle';
  static const String catMeter = 'Meter';
  static const String catOther = 'Other';

  // History Filter Chips
  static const String filterAll = 'All';
  static const String filterToday = 'Today';
  static const String filterLast7Days = 'Last 7 Days';
  static const String filterLast30Days = 'Last 30 Days';

  // Auth Flow Constants
  static const String userLoginTitle = 'User Login';
  static const String userLoginSubtitle =
      'Sign in with your station operator or staff ID';
  static const String adminLoginTitle = 'Admin Login';
  static const String adminLoginSubtitle =
      'Station Administrator & Management Access';
  static const String loginAsAdmin = 'Login as Admin';
  static const String backToUserLogin = 'Back to User Login';
  static const String adminDashboardTitle = 'Admin Dashboard';
  static const String adminDashboardSubtitle =
      'Main Station - CNG Hub #01 Overview';
  static const String enterAdminDashboard = 'Enter Admin Dashboard';
  static const String userLoginButton = 'Login';
  static const String adminLoginButton = 'Login as Admin';
}

