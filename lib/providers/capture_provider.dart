import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../models/cng_reading_item.dart';

/// Stores the manually entered input data and captured pictures.
/// No OCR, text extraction, comparison, or difference calculation is used.
class CaptureProvider extends ChangeNotifier {
  final List<CngReadingItem> _cngItems = [
    CngReadingItem(type: CngReadingType.digitalMachine, title: AppConstants.meterLabel, isRequired: true, icon: Icons.speed_outlined),
    CngReadingItem(type: CngReadingType.manualData, title: AppConstants.manualData, isRequired: true, icon: Icons.description_outlined),
    CngReadingItem(type: CngReadingType.microMotion, title: AppConstants.microMotion, isRequired: false, icon: Icons.speed_outlined),
  ];

  PrimarySourceMode _primarySourceMode = PrimarySourceMode.meter;
  PrimarySourceMode get primarySourceMode => _primarySourceMode;
  List<CngReadingItem> get readingItems => List.unmodifiable(_cngItems);

  void setPrimarySourceMode(PrimarySourceMode mode) {
    if (mode == _primarySourceMode) return;
    _primarySourceMode = mode;
    for (final item in _cngItems) {
      item.reset();
    }
    if (mode == PrimarySourceMode.meter) {
      _cngItems[0].title = AppConstants.meterLabel;
      _cngItems[0].icon = Icons.speed_outlined;
      _cngItems[1].title = AppConstants.manualData;
      _cngItems[1].icon = Icons.description_outlined;
      _cngItems[2].title = AppConstants.microMotion;
      _cngItems[2].icon = Icons.speed_outlined;
    } else {
      _cngItems[0].title = 'VB1';
      _cngItems[0].icon = Icons.local_fire_department_outlined;
      _cngItems[1].title = 'VS1';
      _cngItems[1].icon = Icons.local_fire_department_outlined;
      _cngItems[2].title = 'R Flow';
      _cngItems[2].icon = Icons.local_fire_department_outlined;
    }
    notifyListeners();
  }

  CngReadingItem getItemByType(CngReadingType type) =>
      _cngItems.firstWhere((item) => item.type == type);

  File? getImage(int index) => index >= 0 && index < _cngItems.length ? _cngItems[index].image : null;

  List<File?> get images => _cngItems.map((item) => item.image).toList(growable: false);

  void setInputData(int index, String value) {
    if (index < 0 || index >= _cngItems.length) return;
    _cngItems[index].inputData = value;
    notifyListeners();
  }

  void setInputDataByType(CngReadingType type, String value) {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) setInputData(index, value);
  }

  Future<void> setImage(int index, File image) async {
    if (index < 0 || index >= _cngItems.length) return;
    _cngItems[index].image = image;
    notifyListeners();
  }

  Future<void> setImageByType(CngReadingType type, File image) async {
    final index = _cngItems.indexWhere((item) => item.type == type);
    if (index != -1) await setImage(index, image);
  }

  // Only required pictures are needed before viewing the result.
  // Input Data is optional and is never used to enable/disable the result.
  bool get requiredPicturesProvided =>
      _cngItems.where((item) => item.isRequired).every((item) => item.hasImage);

  bool get canViewResult => requiredPicturesProvided;

  void clearImage(int index) {
    if (index < 0 || index >= _cngItems.length) return;
    _cngItems[index].image = null;
    notifyListeners();
  }

  void clearAll() {
    for (final item in _cngItems) item.reset();
    notifyListeners();
  }
}
