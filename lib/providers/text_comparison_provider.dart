import 'dart:io';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/cng_reading_item.dart';
import '../models/comparison_result_model.dart';
import '../models/image_text_model.dart';
import '../services/ocr_service.dart';
import '../utils/reading_parser.dart';

class TextComparisonProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService();

  // 4 CNG READING ITEMS MATCHING UI REQUIREMENTS
  final List<CngReadingItem> _cngItems = [
    CngReadingItem(
      type: CngReadingType.digitalMachine,
      title: AppConstants.digitalMachine,
      isRequired: true,
      icon: Icons.memory,
    ),
    CngReadingItem(
      type: CngReadingType.manualData,
      title: AppConstants.manualData,
      isRequired: true,
      icon: Icons.description_outlined,
    ),
    CngReadingItem(
      type: CngReadingType.microMotion,
      title: AppConstants.microMotion,
      isRequired: true,
      icon: Icons.speed_outlined,
    ),
    CngReadingItem(
      type: CngReadingType.suiGas,
      title: AppConstants.suiGas,
      isRequired: false,
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  // GENERATION COUNTERS TO PREVENT OCR RACE CONDITIONS
  final List<int> _ocrGeneration = [0, 0, 0, 0];

  double _toleranceThreshold = AppConstants.defaultToleranceThreshold;

  // PRIMARY SOURCE MODE (Nozzle vs Meter) — controls the first card only.
  PrimarySourceMode _primarySourceMode = PrimarySourceMode.nozzle;
  PrimarySourceMode get primarySourceMode => _primarySourceMode;

  /// Switches the first reading card between "Nozzle" (Digital Machine)
  /// and "Meter" mode. The two represent different physical data sources,
  /// so any previously captured image/text for that slot is cleared.
  void setPrimarySourceMode(PrimarySourceMode mode) {
    if (mode == _primarySourceMode) return;
    _primarySourceMode = mode;

    final primary = _cngItems[0];
    _ocrGeneration[0]++;
    primary.reset();
    if (mode == PrimarySourceMode.nozzle) {
      primary.title = AppConstants.digitalMachine;
      primary.icon = Icons.memory;
    } else {
      primary.title = AppConstants.meterLabel;
      primary.icon = Icons.speed_outlined;
    }
    notifyListeners();
  }

  // GETTERS
  List<CngReadingItem> get readingItems => List.unmodifiable(_cngItems);

  double get toleranceThreshold => _toleranceThreshold;
  set toleranceThreshold(double value) {
    _toleranceThreshold = value;
    notifyListeners();
  }

  CngReadingItem getItemByType(CngReadingType type) {
    return _cngItems.firstWhere((item) => item.type == type);
  }

  // BACKWARD COMPATIBLE GETTERS (Supporting index-based access)
  ImageTextModel getItem(int index) {
    if (index < 0 || index >= _cngItems.length) {
      return ImageTextModel(index: index);
    }
    final item = _cngItems[index];
    return ImageTextModel(
      index: index,
      image: item.image,
      extractedText: item.extractedText,
      isLoading: item.isLoading,
      error: item.error,
    );
  }

  List<ImageTextModel> get items {
    return List.generate(_cngItems.length, (i) => getItem(i));
  }

  File? getImage(int index) {
    if (index < 0 || index >= _cngItems.length) return null;
    return _cngItems[index].image;
  }

  String getText(int index) {
    if (index < 0 || index >= _cngItems.length) return '';
    return _cngItems[index].extractedText;
  }

  bool getLoading(int index) {
    if (index < 0 || index >= _cngItems.length) return false;
    return _cngItems[index].isLoading;
  }

  String? getError(int index) {
    if (index < 0 || index >= _cngItems.length) return null;
    return _cngItems[index].error;
  }

  List<String> get extractedTexts {
    return _cngItems.map((item) => item.extractedText).toList(growable: false);
  }

  List<File?> get images {
    return _cngItems.map((item) => item.image).toList(growable: false);
  }

  // SET TEXT
  void setText(int index, String text) {
    if (index < 0 || index >= _cngItems.length) return;

    _cngItems[index].extractedText = text;
    if (text.trim().isNotEmpty) {
      _cngItems[index].error = null;
    }
    notifyListeners();
  }

  void setTextByType(CngReadingType type, String text) {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) {
      setText(index, text);
    }
  }

  // SET IMAGE + RUN OCR
  Future<void> setImage(int index, File image) async {
    if (index < 0 || index >= _cngItems.length) return;

    final int generation = ++_ocrGeneration[index];
    final CngReadingItem item = _cngItems[index];

    item.image = image;
    item.extractedText = '';
    item.error = null;
    item.isLoading = true;

    notifyListeners();

    debugPrint(
      '[Provider] Starting OCR for ${item.title} (generation $generation)',
    );

    try {
      final String text = await _ocrService.extractText(image);

      if (_ocrGeneration[index] != generation) {
        debugPrint('[Provider] Discarding stale OCR result for ${item.title}');
        return;
      }

      if (text.isNotEmpty) {
        item.extractedText = text;
        item.error = null;
      } else {
        item.extractedText = '';
        item.error =
            'No meter reading detected. Ensure the display is clearly visible inside the frame.';
      }

      debugPrint('[Provider] OCR result for ${item.title}: "$text"');
    } catch (e) {
      if (_ocrGeneration[index] != generation) return;
      item.extractedText = '';
      item.error = 'No valid number detected';
      debugPrint('[Provider] OCR error for ${item.title}: $e');
    } finally {
      if (_ocrGeneration[index] == generation) {
        item.isLoading = false;
        notifyListeners();
      }
    }
  }

  // SET CONFIRMED READING (FROM CAMERA CONFIRMATION SCREEN)
  void setConfirmedReading(int index, File image, String confirmedValue) {
    if (index < 0 || index >= _cngItems.length) return;

    final CngReadingItem item = _cngItems[index];
    item.image = image;
    item.extractedText = confirmedValue;
    item.error = null;
    item.isLoading = false;

    debugPrint(
      '[Provider] Confirmed reading set for ${item.title}: "$confirmedValue"',
    );
    notifyListeners();
  }

  void setConfirmedReadingByType(
    CngReadingType type,
    File image,
    String confirmedValue,
  ) {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) {
      setConfirmedReading(index, image, confirmedValue);
    }
  }

  Future<void> setImageByType(CngReadingType type, File image) async {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) {
      await setImage(index, image);
    }
  }

  // OCR STATUS
  bool get isAnyLoading => _cngItems.any((item) => item.isLoading);

  bool get requiredInputsProvided {
    final requiredItems = _cngItems.where((i) => i.isRequired);
    return requiredItems.every((item) => item.extractedText.trim().isNotEmpty);
  }

  bool get canCompare => requiredInputsProvided && !isAnyLoading;

  // NUMERICAL & COMPARISON LOGIC
  //
  // Sui Gas (the optional 4th item) is intentionally excluded from both the
  // numeric corruption check AND the mismatch/allMatch check below. It is
  // shown to the user and its own raw text/numeric value is still exposed
  // via ComparisonResultModel for display, but it never affects whether the
  // reading is flagged as "corrupted" or "different".
  ComparisonResultModel get comparisonResult {
    final digital = getItemByType(CngReadingType.digitalMachine);
    final manual = getItemByType(CngReadingType.manualData);
    final micro = getItemByType(CngReadingType.microMotion);
    final sui = getItemByType(CngReadingType.suiGas);

    final double? digitalVal = digital.numericValue;
    final double? manualVal = manual.numericValue;
    final double? microVal = micro.numericValue;
    final double? suiVal = sui.numericValue; // display-only, not compared

    final double difference = ReadingParser.calculateDifference(
      digitalMachine: digitalVal,
      manualData: manualVal,
      microMotion: microVal,
    );

    final bool isCorrupted = difference > _toleranceThreshold;

    return ComparisonResultModel(
      digitalReading: digitalVal,
      manualReading: manualVal,
      microMotionReading: microVal,
      suiGasReading: suiVal,
      difference: difference,
      threshold: _toleranceThreshold,
      isCorruptionDetected: isCorrupted,
      rawDigitalText: digital.extractedText,
      rawManualText: manual.extractedText,
      rawMicroMotionText: micro.extractedText,
      rawSuiGasText: sui.extractedText,
      primaryLabel: digital.title,
    );
  }

  // REQUIRED-ONLY items, in a stable order, used by allMatch/differentIndexes
  // below so the optional Sui Gas entry can never trigger a mismatch flag.
  List<CngReadingItem> get _requiredItemsInOrder =>
      _cngItems.where((i) => i.isRequired).toList(growable: false);

  // TEXT-BASED COMPARISON METHODS (Maintained for backward compatibility)
  // Now compare on parsed NUMERIC value rather than raw text, so formatting
  // differences ("052.38" vs "52.38") don't produce false mismatches.
  bool get allMatch {
    if (!canCompare) return false;
    final values = _requiredItemsInOrder
        .map((item) => item.numericValue)
        .toList();
    if (values.isEmpty || values.any((v) => v == null)) return false;
    final first = values.first;
    return values.every((v) => v == first);
  }

  List<int> get differentIndexes {
    if (!canCompare) return [];

    final required = _requiredItemsInOrder;
    if (required.length < 2) return [];

    final double? base = required[0].numericValue;
    final List<int> different = [];

    for (int i = 0; i < _cngItems.length; i++) {
      final item = _cngItems[i];
      if (!item.isRequired) continue; // Sui Gas never flagged as different
      final value = item.numericValue;
      if (value != null && value != base) {
        different.add(i);
      }
    }
    return different;
  }

  String get differenceMessage {
    if (!canCompare) {
      return 'Please enter or capture data for all required inputs.';
    }

    if (comparisonResult.isCorruptionDetected) {
      return AppConstants.corruptionDetectedMessage;
    }

    return AppConstants.verifiedMessage;
  }

  // CLEAR ONE IMAGE
  void clearImage(int index) {
    if (index < 0 || index >= _cngItems.length) return;
    _ocrGeneration[index]++;
    _cngItems[index].reset();
    notifyListeners();
  }

  // CLEAR EVERYTHING
  void clearAll() {
    for (int i = 0; i < _cngItems.length; i++) {
      _ocrGeneration[i]++;
      _cngItems[i].reset();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
