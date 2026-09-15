import 'dart:io';
import 'package:flutter/material.dart';

class CngReadingType {
  final String value;
  const CngReadingType._(this.value);

  static const digitalMachine = CngReadingType._('digitalMachine');
  static const counter = CngReadingType._('counter');
  static const microMotion = CngReadingType._('microMotion');
  static const vb1 = CngReadingType._('vb1');
  static const vs1 = CngReadingType._('vs1');
  static const rFlow = CngReadingType._('rFlow');
  static const manualData = CngReadingType._('manualData');
  static const suiGas = CngReadingType._('suiGas');
}

enum PrimarySourceMode { nozzle, meter }

class CngReadingItem {
  final CngReadingType type;
  final bool isRequired;
  String title;
  IconData icon;
  File? image;

  CngReadingItem({
    required this.type,
    required this.title,
    required this.isRequired,
    required this.icon,
    this.image,
  });

  bool get hasImage => image != null;
  bool get isComplete => isRequired ? hasImage : true;

  void reset() {
    image = null;
  }
}
