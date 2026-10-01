import 'dart:io';
import 'package:flutter/material.dart';

class CngReadingType {
  final String value;
  const CngReadingType._(this.value);

  static const meter = CngReadingType._('meter');
  static const digitalMachine = CngReadingType._('digitalMachine');
  static const counter = CngReadingType._('counter');
  static const microMotion = CngReadingType._('microMotion');
  static const vb1 = CngReadingType._('vb1');
  static const vs1 = CngReadingType._('vs1');
  static const rFlow = CngReadingType._('rFlow');
  static const manualData = CngReadingType._('manualData');
  static const suiGas = CngReadingType._('suiGas');
  static const nozzle1 = CngReadingType._('nozzle1');
  static const nozzle2 = CngReadingType._('nozzle2');
  static const nozzle3 = CngReadingType._('nozzle3');
  static const nozzle4 = CngReadingType._('nozzle4');

  static CngReadingType fromString(String? val) {
    switch (val) {
      case 'meter':
        return meter;
      case 'digitalMachine':
        return digitalMachine;
      case 'counter':
        return counter;
      case 'microMotion':
        return microMotion;
      case 'vb1':
        return vb1;
      case 'vs1':
        return vs1;
      case 'rFlow':
        return rFlow;
      case 'manualData':
        return manualData;
      case 'suiGas':
        return suiGas;
      case 'nozzle1':
        return nozzle1;
      case 'nozzle2':
        return nozzle2;
      case 'nozzle3':
        return nozzle3;
      case 'nozzle4':
        return nozzle4;
      default:
        return meter;
    }
  }
}

enum PrimarySourceMode {
  meter,
  nozzle,
  nozzle1,
  nozzle2,
  nozzle3,
  nozzle4;

  String get value => name;

  static PrimarySourceMode fromString(String? val) {
    if (val == null) return PrimarySourceMode.meter;
    for (final mode in PrimarySourceMode.values) {
      if (mode.name.toLowerCase() == val.toLowerCase()) {
        return mode;
      }
    }
    return PrimarySourceMode.meter;
  }
}

class CngReadingItem {
  final CngReadingType type;
  final bool isRequired;

  String title;
  IconData icon;

  File? image;

  // Date and time when this picture was captured.
  DateTime? capturedAt;

  CngReadingItem({
    required this.type,
    required this.title,
    required this.isRequired,
    required this.icon,
    this.image,
    this.capturedAt,
  });

  /// Identifier for card, e.g. 'vb1', 'vs1', 'meter', 'counter'
  String get id => type.value;

  bool get hasImage => image != null;

  bool get isComplete => isRequired ? hasImage : true;

  factory CngReadingItem.fromJson(Map<String, dynamic> json) {
    return CngReadingItem(
      type: CngReadingType.fromString(json['type'] as String?),
      title: json['title'] as String? ?? '',
      isRequired: json['isRequired'] as bool? ?? true,
      icon: Icons.speed_outlined,
      image: json['imagePath'] != null
          ? File(json['imagePath'] as String)
          : null,
      capturedAt: json['capturedAt'] != null
          ? DateTime.tryParse(json['capturedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'title': title,
      'isRequired': isRequired,
      'imagePath': image?.path,
      'capturedAt': capturedAt?.toIso8601String(),
    };
  }

  void reset() {
    image = null;
    capturedAt = null;
  }
}
