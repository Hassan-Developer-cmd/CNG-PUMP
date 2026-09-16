import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/cng_reading_item.dart';

class CaptureProvider extends ChangeNotifier {
  static const int captureTimeoutSeconds = 120;
  final List<CngReadingItem> _cngItems = [];
  PrimarySourceMode _primarySourceMode = PrimarySourceMode.meter;

  Timer? _captureTimer;
  int _remainingSeconds = captureTimeoutSeconds;
  bool _isTimerRemoved = false;

  CaptureProvider() {
    _buildItemsForMode(_primarySourceMode);
  }

  PrimarySourceMode get primarySourceMode => _primarySourceMode;
  List<CngReadingItem> get readingItems => List.unmodifiable(_cngItems);
  int get remainingSeconds => _remainingSeconds;
  bool get timerActive => _captureTimer?.isActive ?? false;

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
    _cngItems
      ..clear()
      ..addAll(
        mode == PrimarySourceMode.meter
            ? [
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
              ]
            : [
                CngReadingItem(
                  type: CngReadingType.digitalMachine,
                  title: AppConstants.digitalMachine,
                  isRequired: true,
                  icon: Icons.speed_outlined,
                ),
                CngReadingItem(
                  type: CngReadingType.counter,
                  title: 'Counter',
                  isRequired: true,
                  icon: Icons.pin_outlined,
                ),
                CngReadingItem(
                  type: CngReadingType.microMotion,
                  title: AppConstants.microMotion,
                  isRequired: false,
                  icon: Icons.speed_outlined,
                ),
              ],
      );
  }

  void setPrimarySourceMode(PrimarySourceMode mode) {
    if (mode == _primarySourceMode) {
      return;
    }
    _stopTimer();
    _isTimerRemoved = false;
    _primarySourceMode = mode;
    _buildItemsForMode(mode);
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

    _cngItems[index].image = image;

    // Store the capture timestamp.
    _cngItems[index].capturedAt = capturedAt;

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
    }
  }

  // Returns true when both required pictures have been captured.
  bool get requiredPicturesProvided {
    return _cngItems
        .where((item) => item.isRequired)
        .every((item) => item.hasImage);
  }

  bool get canViewResult => requiredPicturesProvided;

  // Removes one picture and its timestamp.
  void clearImage(int index) {
    if (index < 0 || index >= _cngItems.length) {
      return;
    }

    _cngItems[index].image = null;
    _cngItems[index].capturedAt = null;

    final bool hasAnyImage = _cngItems.any((item) => item.hasImage);
    if (!hasAnyImage) {
      _stopTimer();
      _resetTimerValue();
      _isTimerRemoved = false;
    }
    notifyListeners();
  }

  /// Explicitly stops the countdown timer and removes it from the UI.
  /// Called when the user clicks 'Save Data'.
  void stopAndRemoveTimer() {
    _stopTimer();
    _isTimerRemoved = true;
    notifyListeners();
  }

  // Clears all pictures and timestamps.
  void clearAll() {
    _stopTimer();
    _isTimerRemoved = false;

    for (final item in _cngItems) {
      item.reset();
    }
    _resetTimerValue();
    notifyListeners();
  }

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
