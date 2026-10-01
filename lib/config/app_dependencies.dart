import '../constants/api_constants.dart';
import '../repositories/repositories.dart';
import '../services/api/api_client.dart';

/// Centralized Dependency Injection & Production API Backend Configuration
///
/// Defaults to live Remote REST API (`useMock = false`).
class AppDependencies {
  AppDependencies._();

  // Flag to toggle between simulated Mock data and live Remote API
  static bool useMock = false;

  static late AuthRepository authRepository;
  static late PumpRepository pumpRepository;
  static late UserRepository userRepository;
  static late AuditRepository auditRepository;
  static late ApiClient apiClient;

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Initialize all application repositories and network services.
  static void initialize({
    bool useMock = false,
    AuthRepository? authRepo,
    PumpRepository? pumpRepo,
    UserRepository? userRepo,
    AuditRepository? auditRepo,
    ApiClient? client,
    String? apiBaseUrl,
  }) {
    AppDependencies.useMock = useMock;

    if (apiBaseUrl != null && apiBaseUrl.trim().isNotEmpty) {
      ApiConstants.setBaseUrl(apiBaseUrl);
    }

    apiClient = client ?? ApiClient.instance;

    authRepository = authRepo ??
        (useMock
            ? MockAuthRepository()
            : RemoteAuthRepository(client: apiClient));

    pumpRepository = pumpRepo ??
        (useMock
            ? MockPumpRepository()
            : RemotePumpRepository(client: apiClient));

    userRepository = userRepo ??
        (useMock
            ? MockUserRepository()
            : RemoteUserRepository(client: apiClient));

    auditRepository = auditRepo ??
        (useMock
            ? MockAuditRepository()
            : RemoteAuditRepository(client: apiClient));

    _isInitialized = true;
  }

  /// Ensure repositories are initialized with safe defaults if accessed before explicit init
  static void ensureInitialized() {
    if (!_isInitialized) {
      initialize(useMock: false);
    }
  }
}
