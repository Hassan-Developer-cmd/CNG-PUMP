import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/cng_reading_item.dart';

/// Manages the capture sequence for Meter and Nozzle sources.
/// There is no OCR, text extraction, comparison, or numerical calculation.
class CaptureProvider extends ChangeNotifier {
  static const int captureTimeoutSeconds = 120;

  final List<CngReadingItem> _cngItems = [];
  PrimarySourceMode _primarySourceMode = PrimarySourceMode.meter;
  Timer? _captureTimer;
  int _remainingSeconds = captureTimeoutSeconds;

  CaptureProvider() {
    _buildItemsForMode(_primarySourceMode);
  }

  PrimarySourceMode get primarySourceMode => _primarySourceMode;
  List<CngReadingItem> get readingItems => List.unmodifiable(_cngItems);
  int get remainingSeconds => _remainingSeconds;
  bool get timerActive => _captureTimer?.isActive ?? false;

  String get formattedRemainingTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// The next card in the capture sequence. The third card is optional.
  int get nextCaptureIndex {
    for (int i = 0; i < _cngItems.length; i++) {
      if (_cngItems[i].isRequired && !_cngItems[i].hasImage) return i;
    }
    return -1;
  }

  bool canCapture(int index) {
    if (index < 0 || index >= _cngItems.length) return false;
    if (_cngItems[index].hasImage) return true; // Retake is allowed.
    if (index == nextCaptureIndex) return true;
    // Once both required pictures are captured, the optional third picture is available.
    return index == 2 && _cngItems[0].hasImage && _cngItems[1].hasImage;
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
    if (mode == _primarySourceMode) return;
    _stopTimer();
    _primarySourceMode = mode;
    _buildItemsForMode(mode);
    _resetTimerValue();
    notifyListeners();
  }

  CngReadingItem getItemByType(CngReadingType type) =>
      _cngItems.firstWhere((item) => item.type == type);

  File? getImage(int index) =>
      index >= 0 && index < _cngItems.length ? _cngItems[index].image : null;

  List<File?> get images =>
      _cngItems.map((item) => item.image).toList(growable: false);

  Future<void> setImage(int index, File image) async {
    if (index < 0 || index >= _cngItems.length) return;
    if (!canCapture(index)) return;

    final bool wasEmpty = !_cngItems[index].hasImage;
    _cngItems[index].image = image;

    // The two-minute countdown starts after a new required picture and waits
    // for the next required picture. It does not apply after the final
    // required picture because the third card is optional.
    if (wasEmpty && _cngItems[index].isRequired) {
      final int nextRequired = nextCaptureIndex;
      if (nextRequired != -1) {
        _startTimer();
      } else {
        _stopTimer();
      }
    }

    notifyListeners();
  }

  Future<void> setImageByType(CngReadingType type, File image) async {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) await setImage(index, image);
  }

  bool get requiredPicturesProvided =>
      _cngItems.where((item) => item.isRequired).every((item) => item.hasImage);

  bool get canViewResult => requiredPicturesProvided;

  void clearImage(int index) {
    if (index < 0 || index >= _cngItems.length) return;
    _cngItems[index].image = null;
    _stopTimer();
    _resetTimerValue();

    // If a required picture is removed while an earlier required picture
    // still exists, give the user two minutes to continue the sequence.
    if (index > 0 && _cngItems[index - 1].hasImage && _cngItems[index].isRequired) {
      _startTimer();
    }
    notifyListeners();
  }

  void clearAll() {
    _stopTimer();
    for (final item in _cngItems) item.reset();
    _resetTimerValue();
    notifyListeners();
  }

  void _startTimer() {
    _captureTimer?.cancel();
    _remainingSeconds = captureTimeoutSeconds;
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
    // If the next required picture was not taken within two minutes,
    // restart the sequence so the previous picture also disappears.
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
