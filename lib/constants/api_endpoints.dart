/// Centralized API Endpoints Configuration Template
///
/// Simply update these endpoint paths or customize them to match your backend specification.
class ApiEndpoints {
  ApiEndpoints._();

  // ==========================================
  // 1. Authentication & Session Endpoints
  // ==========================================

  /// POST: Admin login with email and password
  static const String adminLogin = '/api/v1/auth/adminlogin';

  /// POST: Super Admin login with email and password
  static const String superAdminLogin = '/api/v1/auth/superadminlogin';

  /// POST: Operator login with operator ID / email and password
  static const String operatorLogin = '/api/v1/auth/adminlogin';

  /// POST: Universal login endpoint (if unified)
  static const String login = '/api/v1/auth/login';

  /// POST: Logout and invalidate session/token
  static const String logout = '/api/v1/auth/logout';

  /// GET: Current authenticated user/admin profile
  static const String profile = '/api/v1/auth/profile';

  /// PUT / POST: Update password
  static const String changePassword = '/api/v1/auth/change-password';

  // ==========================================
  // 2. Station & Pump Management Endpoints
  // ==========================================

  /// GET: Fetch all registered pump stations
  /// POST: Register a new pump station
  static const String pumps = '/api/v1/pumps';

  /// GET: Aggregated pump metrics (total pumps, active units, etc.)
  static const String pumpStats = '/api/v1/pumps/stats';

  /// GET, PUT, DELETE: Station details by ID
  static String pumpDetail(String id) => '/api/v1/pumps/$id';

  // ==========================================
  // 3. Audit & Readings Submissions Endpoints
  // ==========================================

  /// GET: Fetch audit ledger records / activity feed
  /// POST: Multipart upload of real-time captured audit photos & readings
  static const String audits = '/api/v1/audits';

  /// GET: Dynamic MongoDB capture sessions history feed
  static const String captureHistory = '/api/v1/capture/history';

  /// GET: All capture history across all stations/operators for Super Admin / Admin
  static const String getAllCaptureHistory = '/api/v1/capture/getAllCaptureHistory';

  /// POST: Multipart upload of a single captured watermarked audit image
  /// Fields: mode, imageType (e.g. "vb1", "vs1", "digitalMachine", "counter"), readingType, readingValue, timestamp
  /// Files: image
  static const String captureImage = '/api/v1/capture/captureImage';

  /// POST: Mark an audit capture session as complete.
  /// Replaces :id with the session/capture ID returned from previous upload steps.
  static String captureComplete(String id) => '/api/v1/capture/complete/$id';

  /// GET: Active audit configuration (countdown duration, active nozzles, prompts)
  static const String auditConfig = '/api/v1/audits/config';

  /// GET: Detailed audit session inspection by ID
  static String auditDetail(String id) => '/api/v1/audits/$id';

  // ==========================================
  // 4. User & Staff Management Endpoints
  // ==========================================

  /// GET: Fetch all staff and operators
  /// POST: Register a new operator/supervisor
  static const String users = '/api/v1/users';

  /// GET, PUT, DELETE: User by ID
  static String userDetail(String id) => '/api/v1/users/$id';

  /// PATCH / PUT: Toggle user active status
  static String userStatus(String id) => '/api/v1/users/$id/status';
}
