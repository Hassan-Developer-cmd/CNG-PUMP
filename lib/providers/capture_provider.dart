import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../config/app_dependencies.dart';
import '../models/audit_config_model.dart';
import '../models/capture_history_item.dart';
import '../models/capture_upload_result.dart';
import '../models/cng_reading_item.dart';
import '../repositories/audit_repository.dart';
import '../services/api/api_exception.dart';

export '../repositories/audit_repository.dart' show getBackendImageType;

class CaptureProvider extends ChangeNotifier {
  /// Maps card identifier and active mode to backend contract `imageType` value.
  ///
  /// - Meter mode: "vb1" | "vs1" (strictly lowercase)
  /// - Nozzle mode: "digitalMachine" (first card / meter) | "counter" (second card)
  static String getBackendImageType(String cardId, String mode) {
    final cleanId = cardId.toLowerCase().trim();
    final cleanMode = mode.toLowerCase().trim();
    if (cleanId.contains('vb1')) return 'vb1';
    if (cleanId.contains('vs1')) return 'vs1';
    if (cleanId.replaceAll(' ', '').contains('micromotion') ||
        cleanId.contains('motion')) {
      return 'microMotion';
    }
    if (cleanId.replaceAll(' ', '').contains('digitalmachine') ||
        cleanId.contains('digital') ||
        cleanId.contains('machine')) {
      return 'digitalMachine';
    }
    if (cleanId.contains('counter')) return 'counter';
    if (cleanMode.contains('nozzle') &&
        (cleanId.contains('meter') || cleanId.contains('nozzle') || cleanId == 'first' || cleanId == '1')) {
      return 'digitalMachine';
    }
    return cleanId;
  }

  final AuditRepository _repository;
  AuditConfigModel _auditConfig = const AuditConfigModel();

  static const int captureTimeoutSeconds = 120;
  final List<CngReadingItem> _cngItems = [];
  PrimarySourceMode _primarySourceMode = PrimarySourceMode.meter;

  File? _primaryCardImage;
  DateTime? _primaryCardCapturedAt;

  File? _meterImage;
  DateTime? _meterCapturedAt;

  File? _counterImage;
  DateTime? _counterCapturedAt;

  File? _microMotionImage;
  DateTime? _microMotionCapturedAt;

  Timer? _captureTimer;
  int _remainingSeconds = captureTimeoutSeconds;
  bool _isTimerRemoved = false;
  bool _isSubmitting = false;
  String? _submissionError;

  bool get isSubmitting => _isSubmitting;
  String? get submissionError => _submissionError;

  // -------------------------------------------------------
  // Active session ID — set when createSessionRecord() is called
  // -------------------------------------------------------
  String? _activeSessionId;

  /// The ID of the most recently created session record.
  /// Used as the `:id` parameter for POST /api/v1/capture/complete/:id.
  String? get activeSessionId => _activeSessionId;

  /// Sets or overrides the active session ID (e.g. from server upload or station session).
  void setActiveSessionId(String id) {
    _activeSessionId = id.trim();
    notifyListeners();
  }

  // -------------------------------------------------------
  // Completion state
  // -------------------------------------------------------
  bool _isCompleting = false;
  String? _completionError;

  /// True while the audit-complete API call is in flight.
  bool get isCompleting => _isCompleting;

  /// Non-null if the last completeSession() call failed.
  String? get completionError => _completionError;

  // -------------------------------------------------------
  // Per-card upload state  (keyed by CngReadingType.value)
  // -------------------------------------------------------
  final Map<String, bool> _cardUploading = {};
  final Map<String, String?> _cardUploadError = {};
  final Map<String, String?> _cardUploadedImageUrl = {};
  final Map<String, String?> _cardUploadedImageId = {};

  /// Returns true while the upload for [type] is in flight.
  bool isCardUploading(CngReadingType type) =>
      _cardUploading[type.value] == true;

  /// Returns the last upload error for [type], or null if clean.
  String? cardUploadError(CngReadingType type) =>
      _cardUploadError[type.value];

  /// Returns the server image URL returned after a successful upload for [type].
  String? cardUploadedImageUrl(CngReadingType type) =>
      _cardUploadedImageUrl[type.value];

  /// Returns the server image ID returned after a successful upload for [type].
  String? cardUploadedImageId(CngReadingType type) =>
      _cardUploadedImageId[type.value];

  /// Whether the card for [type] has been successfully uploaded to the server.
  bool isCardVerified(CngReadingType type) =>
      _cardUploadedImageUrl[type.value] != null ||
      _cardUploadedImageId[type.value] != null;

  CaptureProvider({AuditRepository? repository})
      : _repository = repository ?? _resolveRepository() {
    _auditConfig = _repository.initialAuditConfig;
    _remainingSeconds = _auditConfig.countdownDurationSeconds;
    _buildItemsForMode(_primarySourceMode);
  }

  static AuditRepository _resolveRepository() {
    AppDependencies.ensureInitialized();
    return AppDependencies.auditRepository;
  }

  AuditConfigModel get auditConfig => _auditConfig;
  String get operatorName => _auditConfig.operatorName;
  String get operatorId => _auditConfig.operatorId;
  String get stationName => _auditConfig.stationName;
  List<String> get availableNozzles => _auditConfig.availableNozzles;
  String formatOperatorPrompt(String target) => _auditConfig.formatPrompt(target);
  String formatBottomNote(String target) => _auditConfig.formatBottomNote(target);
  String get suiGasBottomNote => _auditConfig.suiGasBottomNote;

  Future<void> fetchAuditConfig() async {
    try {
      _auditConfig = await _repository.getAuditConfig();
      notifyListeners();
    } catch (_) {}
  }

  PrimarySourceMode get primarySourceMode => _primarySourceMode;

  String get selectedMode {
    switch (_primarySourceMode) {
      case PrimarySourceMode.meter:
        return 'Meter';
      case PrimarySourceMode.nozzle1:
      case PrimarySourceMode.nozzle:
        return 'Nozzle 1';
      case PrimarySourceMode.nozzle2:
        return 'Nozzle 2';
      case PrimarySourceMode.nozzle3:
        return 'Nozzle 3';
      case PrimarySourceMode.nozzle4:
        return 'Nozzle 4';
    }
  }

  String get displayUserName => '$operatorName $selectedMode';

  List<CngReadingItem> get readingItems => List.unmodifiable(_cngItems);
  List<CngReadingItem> get currentReadingItems => readingItems;
  int get remainingSeconds => _remainingSeconds;
  bool get timerActive => _captureTimer?.isActive ?? false;

  File? get primaryCardImage => _primaryCardImage;
  DateTime? get primaryCardCapturedAt => _primaryCardCapturedAt;

  File? get meterImage => _primarySourceMode == PrimarySourceMode.meter
      ? _primaryCardImage
      : (_meterImage ?? getItemByType(CngReadingType.meter).image);
  DateTime? get meterCapturedAt =>
      _primarySourceMode == PrimarySourceMode.meter
          ? _primaryCardCapturedAt
          : (_meterCapturedAt ?? getItemByType(CngReadingType.meter).capturedAt);

  File? get counterImage =>
      _counterImage ?? getItemByType(CngReadingType.counter).image;
  DateTime? get counterCapturedAt =>
      _counterCapturedAt ?? getItemByType(CngReadingType.counter).capturedAt;

  File? get microMotionImage =>
      _microMotionImage ?? getItemByType(CngReadingType.microMotion).image;
  DateTime? get microMotionCapturedAt =>
      _microMotionCapturedAt ?? getItemByType(CngReadingType.microMotion).capturedAt;

  /// Returns the actual real-time captured images with their labels and timestamps.
  List<CapturedImage> getCapturedImages() {
    final isMeterMode = _primarySourceMode == PrimarySourceMode.meter;
    final List<CapturedImage> captured = [];

    if (isMeterMode) {
      for (final item in currentReadingItems) {
        if (item.hasImage && item.capturedAt != null) {
          captured.add(
            CapturedImage(
              label: item.title,
              image: item.image!,
              capturedAt: item.capturedAt!,
            ),
          );
        }
      }
    } else {
      if (meterImage != null && meterCapturedAt != null) {
        captured.add(
          CapturedImage(
            label: 'Meter',
            image: meterImage!,
            capturedAt: meterCapturedAt!,
          ),
        );
      }
      if (counterImage != null && counterCapturedAt != null) {
        captured.add(
          CapturedImage(
            label: 'Counter',
            image: counterImage!,
            capturedAt: counterCapturedAt!,
          ),
        );
      }
      if (microMotionImage != null && microMotionCapturedAt != null) {
        captured.add(
          CapturedImage(
            label: 'Micro Motion',
            image: microMotionImage!,
            capturedAt: microMotionCapturedAt!,
          ),
        );
      }
    }
    return captured;
  }

  /// Binds the current real-time captured watermarked images into a new dynamic CaptureHistoryItem.
  CaptureHistoryItem createSessionRecord({
    String? stationName,
    String? operatorName,
  }) {
    final captured = getCapturedImages();
    final record = CaptureHistoryItem(
      dateTime: DateTime.now(),
      images: List.unmodifiable(captured),
      modeName: selectedMode,
      stationName: stationName ?? this.stationName,
      operatorName: operatorName ?? this.operatorName,
    );
    // Persist the session ID so completeSession() can reference it.
    _activeSessionId = record.id;
    return record;
  }

  /// Submits the real-time captured photos and reading session to the backend API
  Future<CaptureHistoryItem> submitAuditSession({
    String? stationName,
    String? operatorName,
  }) async {
    _isSubmitting = true;
    _submissionError = null;
    notifyListeners();

    final session = createSessionRecord(
      stationName: stationName,
      operatorName: operatorName,
    );

    try {
      await _repository.saveHistoryRecord(session);
      _isSubmitting = false;
      notifyListeners();
      return session;
    } catch (e) {
      _submissionError = e.toString();
      _isSubmitting = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Calls `POST /api/v1/capture/complete/:id` to mark the active audit session done.
  ///
  /// Transmits completion data via multipart form-data including the captured watermarked images.
  /// Returns true on success, false on failure (error available in [completionError]).
  Future<bool> completeSession({
    String? sessionId,
    String? difference,
    String? threshold,
    bool? hasCorruption,
    String? statusText,
    List<CapturedImage>? capturedImages,
    File? imageFile,
    String? imageType,
  }) async {
    final sid = (sessionId != null && sessionId.trim().isNotEmpty)
        ? sessionId.trim()
        : (_activeSessionId ?? 'aud_${DateTime.now().millisecondsSinceEpoch}');

    _isCompleting = true;
    _completionError = null;
    notifyListeners();

    // Use passed captured images or fallback to provider's captured images
    final images = capturedImages ?? getCapturedImages();

    // Collect all uploaded imageIds and imageUrls from per-card state
    final imageIds = _cardUploadedImageId.values
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toList();
    final imageUrls = _cardUploadedImageUrl.values
        .where((v) => v != null && v.isNotEmpty)
        .cast<String>()
        .toList();

    try {
      await _repository.completeAuditSession(
        sessionId: sid,
        mode: selectedMode,
        capturedImages: images,
        imageFile: imageFile,
        imageType: imageType,
        imageIds: imageIds,
        imageUrls: imageUrls,
        statusText: statusText,
        hasCorruption: hasCorruption ?? false,
        difference: difference,
        threshold: threshold,
        stationName: stationName,
        operatorName: operatorName,
      );
      _isCompleting = false;
      _completionError = null;
      notifyListeners();
      return true;
    } catch (e) {
      _isCompleting = false;
      final rawError = e is ApiException ? e.message : e.toString();
      _completionError = rawError.startsWith('Exception: ')
          ? rawError.substring(11)
          : rawError;
      notifyListeners();
      return false;
    }
  }

  // -------------------------------------------------------
  // Per-card image upload helpers
  // -------------------------------------------------------

  /// Maps a [CngReadingType] to its canonical readingType string for the API.
  static String _readingTypeApiKey(CngReadingType type) {
    if (type == CngReadingType.microMotion) return 'micro_motion';
    if (type == CngReadingType.rFlow) return 'r_flow';
    return type.value;
  }

  /// Uploads the captured image for a single card to
  /// `POST /api/v1/capture/captureImage`.
  ///
  /// Silently ignores if the card has no image captured yet.
  /// On success the server-returned [CaptureUploadResult.imageUrl] /
  /// [CaptureUploadResult.imageId] are persisted in provider state.
  /// On failure the error string is stored in [cardUploadError].
  Future<CaptureUploadResult?> uploadImageForType(
    CngReadingType type, {
    String? readingValue,
  }) async {
    File? imageFile;
    DateTime? capturedAt;

    // Find the image, timestamp, and readingType for this type
    final idx = _cngItems.indexWhere((i) => i.type == type);
    String readingTypeStr = _readingTypeApiKey(type);
    if (idx != -1) {
      imageFile = _cngItems[idx].image;
      capturedAt = _cngItems[idx].capturedAt;
      if (_cngItems[idx].title.isNotEmpty) {
        readingTypeStr = _cngItems[idx].title;
      }
    } else if (type == CngReadingType.meter) {
      imageFile = _meterImage;
      capturedAt = _meterCapturedAt;
      readingTypeStr = 'Meter';
    } else if (type == CngReadingType.counter) {
      imageFile = _counterImage;
      capturedAt = _counterCapturedAt;
      readingTypeStr = 'Counter';
    } else if (type == CngReadingType.microMotion) {
      imageFile = _microMotionImage;
      capturedAt = _microMotionCapturedAt;
      readingTypeStr = 'Micro Motion';
    } else {
      // Primary card (nozzle mode)
      imageFile = _primaryCardImage;
      capturedAt = _primaryCardCapturedAt;
      readingTypeStr = selectedMode;
    }

    if (imageFile == null || !imageFile.existsSync()) return null;

    final key = type.value;
    final readingItem = idx != -1 ? _cngItems[idx] : null;
    String mappedImageType = readingItem != null ? readingItem.id : key;

    if (mappedImageType.toLowerCase().replaceAll(' ', '').contains('micromotion') ||
        mappedImageType.toLowerCase().contains('motion')) {
      mappedImageType = 'microMotion';
    } else if (mappedImageType.toLowerCase().replaceAll(' ', '').contains('digitalmachine') ||
        mappedImageType.toLowerCase().contains('digital')) {
      mappedImageType = 'digitalMachine';
    } else if (mappedImageType.toLowerCase().contains('counter')) {
      mappedImageType = 'counter';
    } else {
      mappedImageType = getBackendImageType(mappedImageType, selectedMode);
    }

    _cardUploading[key] = true;
    _cardUploadError[key] = null;
    notifyListeners();

    try {
      final result = await _repository.uploadCapturedImage(
        mode: selectedMode,
        readingType: mappedImageType,
        imageType: mappedImageType,
        imageFile: imageFile,
        readingValue: readingValue,
        timestamp: capturedAt,
      );
      _cardUploading[key] = false;
      if (result.success) {
        _cardUploadedImageUrl[key] = result.imageUrl ??
            'uploaded_${DateTime.now().millisecondsSinceEpoch}';
        _cardUploadedImageId[key] = result.imageId ??
            'img_${DateTime.now().millisecondsSinceEpoch}';
        _cardUploadError[key] = null;
      } else {
        _cardUploadError[key] =
            result.message ?? 'Upload failed. Tap to retry.';
      }
      notifyListeners();
      return result;
    } catch (e) {
      _cardUploading[key] = false;
      final rawError = e is ApiException ? e.message : e.toString();
      _cardUploadError[key] = rawError.startsWith('Exception: ')
          ? rawError.substring(11)
          : rawError;
      notifyListeners();
      return null;
    }
  }

  /// Uploads all captured images that have not yet been successfully uploaded.
  ///
  /// Returns a map of CngReadingType.value → upload result (or null on error).
  Future<Map<String, CaptureUploadResult?>> batchUploadAll() async {
    final results = <String, CaptureUploadResult?>{};
    for (final item in _cngItems) {
      if (item.hasImage && !isCardVerified(item.type)) {
        results[item.type.value] = await uploadImageForType(item.type);
      }
    }
    // Also handle images stored outside _cngItems (nozzle mode primary card)
    if (_primarySourceMode != PrimarySourceMode.meter &&
        _primaryCardImage != null) {
      final nozzleType = _primarySourceMode == PrimarySourceMode.nozzle1 ||
              _primarySourceMode == PrimarySourceMode.nozzle
          ? CngReadingType.nozzle1
          : _primarySourceMode == PrimarySourceMode.nozzle2
              ? CngReadingType.nozzle2
              : _primarySourceMode == PrimarySourceMode.nozzle3
                  ? CngReadingType.nozzle3
                  : CngReadingType.nozzle4;
      final key = nozzleType.value;
      if (!isCardVerified(nozzleType)) {
        _cardUploading[key] = true;
        _cardUploadError[key] = null;
        notifyListeners();
        try {
          final mappedType = getBackendImageType('digitalMachine', selectedMode);
          final r = await _repository.uploadCapturedImage(
            mode: selectedMode,
            readingType: mappedType,
            imageType: mappedType,
            imageFile: _primaryCardImage!,
            timestamp: _primaryCardCapturedAt,
          );
          _cardUploading[key] = false;
          if (r.success) {
            _cardUploadedImageUrl[key] = r.imageUrl ??
                'uploaded_${DateTime.now().millisecondsSinceEpoch}';
            _cardUploadedImageId[key] = r.imageId ??
                'img_${DateTime.now().millisecondsSinceEpoch}';
            _cardUploadError[key] = null;
          } else {
            _cardUploadError[key] = r.message ?? 'Upload failed.';
          }
          results[key] = r;
          notifyListeners();
        } catch (e) {
          _cardUploading[key] = false;
          final rawError = e is ApiException ? e.message : e.toString();
          _cardUploadError[key] = rawError.startsWith('Exception: ')
              ? rawError.substring(11)
              : rawError;
          results[key] = null;
          notifyListeners();
        }
      }
    }
    return results;
  }

  /// Clears per-card upload state — called when the user clears an image
  /// so they can re-upload after retaking the photo.
  void clearCardUploadState(CngReadingType type) {
    final key = type.value;
    _cardUploading.remove(key);
    _cardUploadError.remove(key);
    _cardUploadedImageUrl.remove(key);
    _cardUploadedImageId.remove(key);
  }

  void setPrimaryCardImage(File file, DateTime at) {
    _primaryCardImage = file;
    _primaryCardCapturedAt = at;
    if (!timerActive && !_isTimerRemoved) _startTimer();
    notifyListeners();
  }

  void clearPrimaryCardImage() {
    _primaryCardImage = null;
    _primaryCardCapturedAt = null;
    _checkTimerAfterClear();
    notifyListeners();
  }

  void setMeterImage(File file, DateTime at) {
    if (_primarySourceMode == PrimarySourceMode.meter) {
      setPrimaryCardImage(file, at);
    } else {
      _meterImage = file;
      _meterCapturedAt = at;
      final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.meter);
      if (idx != -1) {
        _cngItems[idx].image = file;
        _cngItems[idx].capturedAt = at;
      }
      if (!timerActive && !_isTimerRemoved) _startTimer();
      notifyListeners();
    }
  }

  void clearMeterImage() {
    if (_primarySourceMode == PrimarySourceMode.meter) {
      clearPrimaryCardImage();
    } else {
      _meterImage = null;
      _meterCapturedAt = null;
      final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.meter);
      if (idx != -1) {
        _cngItems[idx].image = null;
        _cngItems[idx].capturedAt = null;
      }
      _checkTimerAfterClear();
      notifyListeners();
    }
  }

  void setCounterImage(File file, DateTime at) {
    _counterImage = file;
    _counterCapturedAt = at;
    final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.counter);
    if (idx != -1) {
      _cngItems[idx].image = file;
      _cngItems[idx].capturedAt = at;
    }
    if (!timerActive && !_isTimerRemoved) _startTimer();
    notifyListeners();
  }

  void clearCounterImage() {
    _counterImage = null;
    _counterCapturedAt = null;
    final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.counter);
    if (idx != -1) {
      _cngItems[idx].image = null;
      _cngItems[idx].capturedAt = null;
    }
    _checkTimerAfterClear();
    notifyListeners();
  }

  void setMicroMotionImage(File file, DateTime at) {
    _microMotionImage = file;
    _microMotionCapturedAt = at;
    final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.microMotion);
    if (idx != -1) {
      _cngItems[idx].image = file;
      _cngItems[idx].capturedAt = at;
    }
    if (!timerActive && !_isTimerRemoved) _startTimer();
    notifyListeners();
  }

  void clearMicroMotionImage() {
    _microMotionImage = null;
    _microMotionCapturedAt = null;
    final int idx = _cngItems.indexWhere((item) => item.type == CngReadingType.microMotion);
    if (idx != -1) {
      _cngItems[idx].image = null;
      _cngItems[idx].capturedAt = null;
    }
    _checkTimerAfterClear();
    notifyListeners();
  }


  /// Returns true if the timer is actively running and has not been stopped/removed by Save Data.
  bool get isTimerVisible => timerActive && !_isTimerRemoved;

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  int get nextCaptureIndex {
    for (int i = 0; i < _cngItems.length; i++) {
      if (_cngItems[i].isRequired && !_cngItems[i].hasImage) {
        return i;
      }
    }

    return -1;
  }

  bool canCapture(int index) {
    return index >= 0 && index < _cngItems.length;
  }

  void _buildItemsForMode(PrimarySourceMode mode) {
    _cngItems.clear();
    switch (mode) {
      case PrimarySourceMode.meter:
        _cngItems.addAll([
          CngReadingItem(
            type: CngReadingType.vb1,
            title: 'VB1',
            isRequired: true,
            icon: Icons.speed_outlined,
          ),
          CngReadingItem(
            type: CngReadingType.vs1,
            title: 'VS1',
            isRequired: true,
            icon: Icons.speed_outlined,
          ),
          CngReadingItem(
            type: CngReadingType.rFlow,
            title: 'R Flow',
            isRequired: false,
            icon: Icons.waterfall_chart_outlined,
          ),
        ]);
        break;
      case PrimarySourceMode.nozzle1:
      case PrimarySourceMode.nozzle2:
      case PrimarySourceMode.nozzle3:
      case PrimarySourceMode.nozzle4:
      case PrimarySourceMode.nozzle:
        _cngItems.addAll([
          CngReadingItem(
            type: CngReadingType.meter,
            title: 'Meter',
            isRequired: true,
            icon: Icons.speed_outlined,
          ),
          CngReadingItem(
            type: CngReadingType.counter,
            title: 'Counter',
            isRequired: true,
            icon: Icons.av_timer_outlined,
          ),
          CngReadingItem(
            type: CngReadingType.microMotion,
            title: 'Micro Motion',
            isRequired: false,
            icon: Icons.graphic_eq_rounded,
          ),
        ]);
        break;
    }
  }

  void setPrimarySourceMode(PrimarySourceMode mode) {
    if (mode == _primarySourceMode) {
      return;
    }
    _stopTimer();
    _isTimerRemoved = false;
    _primarySourceMode = mode;
    _buildItemsForMode(mode);
    _primaryCardImage = null;
    _primaryCardCapturedAt = null;
    _meterImage = null;
    _meterCapturedAt = null;
    _counterImage = null;
    _counterCapturedAt = null;
    _microMotionImage = null;
    _microMotionCapturedAt = null;
    _resetTimerValue();
    notifyListeners();
  }

  CngReadingItem getItemByType(CngReadingType type) {
    return _cngItems.firstWhere(
      (item) => item.type == type,
      orElse: () => CngReadingItem(
        type: type,
        title: type.value,
        isRequired: false,
        icon: Icons.speed_outlined,
      ),
    );
  }

  File? getImage(int index) {
    if (index < 0 || index >= _cngItems.length) {
      return null;
    }
    return _cngItems[index].image;
  }

  List<File?> get images {
    return _cngItems.map((item) => item.image).toList(growable: false);
  }

  Future<void> setImage(int index, File image, DateTime capturedAt) async {
    if (index < 0 || index >= _cngItems.length) {
      return;
    }

    final item = _cngItems[index];
    item.image = image;
    item.capturedAt = capturedAt;

    if (item.type == CngReadingType.meter) {
      _meterImage = image;
      _meterCapturedAt = capturedAt;
      if (_primarySourceMode == PrimarySourceMode.meter) {
        _primaryCardImage = image;
        _primaryCardCapturedAt = capturedAt;
      }
    } else if (item.type == CngReadingType.counter) {
      _counterImage = image;
      _counterCapturedAt = capturedAt;
    } else if (item.type == CngReadingType.microMotion) {
      _microMotionImage = image;
      _microMotionCapturedAt = capturedAt;
    } else if (item.type == CngReadingType.vb1) {
      _primaryCardImage = image;
      _primaryCardCapturedAt = capturedAt;
    }

    // Start timer on capture process start if not already active and not saved.
    // The timer continues counting down continuously until Save Data is clicked.
    if (!timerActive && !_isTimerRemoved) {
      _startTimer();
    }
    notifyListeners();
  }

  // Saves an image and timestamp using its reading type.
  Future<void> setImageByType(
    CngReadingType type,
    File image,
    DateTime capturedAt,
  ) async {
    final int index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) {
      await setImage(index, image, capturedAt);
    } else {
      if (type == CngReadingType.meter) {
        setMeterImage(image, capturedAt);
      } else if (type == CngReadingType.counter) {
        setCounterImage(image, capturedAt);
      } else if (type == CngReadingType.microMotion) {
        setMicroMotionImage(image, capturedAt);
      } else if (type == CngReadingType.digitalMachine ||
          type == CngReadingType.nozzle1 ||
          type == CngReadingType.nozzle2 ||
          type == CngReadingType.nozzle3 ||
          type == CngReadingType.nozzle4) {
        setPrimaryCardImage(image, capturedAt);
      }
    }
  }

  // Returns true when all required pictures have been captured.
  bool get requiredPicturesProvided {
    return _cngItems
        .where((item) => item.isRequired)
        .every((item) => item.hasImage);
  }

  bool get isComplete => requiredPicturesProvided;

  bool get canViewResult => isComplete;

  // Removes one picture and its timestamp.
  void clearImage(int index) {
    if (index < 0 || index >= _cngItems.length) {
      return;
    }

    final item = _cngItems[index];
    item.image = null;
    item.capturedAt = null;

    if (item.type == CngReadingType.meter) {
      _meterImage = null;
      _meterCapturedAt = null;
      if (_primarySourceMode == PrimarySourceMode.meter) {
        _primaryCardImage = null;
        _primaryCardCapturedAt = null;
      }
    } else if (item.type == CngReadingType.counter) {
      _counterImage = null;
      _counterCapturedAt = null;
    } else if (item.type == CngReadingType.microMotion) {
      _microMotionImage = null;
      _microMotionCapturedAt = null;
    } else if (item.type == CngReadingType.vb1) {
      _primaryCardImage = null;
      _primaryCardCapturedAt = null;
    }

    // Also reset the card's server-upload state so a retake triggers a fresh upload.
    clearCardUploadState(item.type);

    _checkTimerAfterClear();
    notifyListeners();
  }

  void _checkTimerAfterClear() {
    final bool hasAnyImage = _cngItems.any((item) => item.hasImage) ||
        _meterImage != null ||
        _counterImage != null ||
        _microMotionImage != null ||
        _primaryCardImage != null;
    if (!hasAnyImage) {
      _stopTimer();
      _resetTimerValue();
      _isTimerRemoved = false;
    }
  }

  /// Explicitly stops the countdown timer and removes it from the UI.
  /// Called when the user clicks 'Save Data'.
  void stopAndRemoveTimer() {
    _stopTimer();
    _isTimerRemoved = true;
    notifyListeners();
  }

  // Clears all pictures, timestamps, and server-upload state.
  void clearAll() {
    _stopTimer();
    _isTimerRemoved = false;

    _primaryCardImage = null;
    _primaryCardCapturedAt = null;
    _meterImage = null;
    _meterCapturedAt = null;
    _counterImage = null;
    _counterCapturedAt = null;
    _microMotionImage = null;
    _microMotionCapturedAt = null;

    for (final item in _cngItems) {
      item.reset();
    }

    // Reset all per-card upload tracking
    _cardUploading.clear();
    _cardUploadError.clear();
    _cardUploadedImageUrl.clear();
    _cardUploadedImageId.clear();

    _activeSessionId = null;
    _isCompleting = false;
    _completionError = null;

    _resetTimerValue();
    notifyListeners();
  }

  /// Safely resets the entire local audit session, photos, and timer.
  void resetSession() => clearAll();

  void _startTimer() {
    _captureTimer?.cancel();
    _remainingSeconds = captureTimeoutSeconds;
    _isTimerRemoved = false;
    _captureTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        _remainingSeconds = 0;
        _clearExpiredCapture();
        return;
      }
      _remainingSeconds--;
      notifyListeners();
    });
    notifyListeners();
  }

  void _clearExpiredCapture() {
    _isTimerRemoved = false;
    for (final item in _cngItems) {
      item.reset();
    }
    _resetTimerValue();
    notifyListeners();
  }

  void _stopTimer() {
    _captureTimer?.cancel();
    _captureTimer = null;
  }

  void _resetTimerValue() {
    _remainingSeconds = captureTimeoutSeconds;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
