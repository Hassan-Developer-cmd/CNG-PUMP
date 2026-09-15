import 'dart:io';
import 'package:flutter/material.dart';

class CngReadingType {
  final String value;
  const CngReadingType._(this.value);

  static const digitalMachine = CngReadingType._('digitalMachine');
  static const manualData = CngReadingType._('manualData');
  static const microMotion = CngReadingType._('microMotion');
  static const suiGas = CngReadingType._('suiGas');
}

enum PrimarySourceMode { nozzle, meter }

class CngReadingItem {
  final CngReadingType type;
  final bool isRequired;
  String title;
  IconData icon;
  File? image;
  String inputData;

  CngReadingItem({
    required this.type,
    required this.title,
    required this.isRequired,
    required this.icon,
    this.image,
    this.inputData = '',
  });

  bool get hasImage => image != null;
  bool get hasInputData => inputData.trim().isNotEmpty;
  // Input Data is optional. A required item is complete once its picture is captured.
  bool get isComplete => isRequired ? hasImage : true;

  void reset() {
    image = null;
    inputData = '';
  }
}
