import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/reading_parser.dart';

enum CngReadingType {
  digitalMachine,
  manualData,
  microMotion,
  suiGas,
}

class CngReadingItem {
  final CngReadingType type;
  final String title;
  final bool isRequired;
  final IconData icon;

  File? image;
  String extractedText;
  bool isLoading;
  String? error;

  CngReadingItem({
    required this.type,
    required this.title,
    required this.isRequired,
    required this.icon,
    this.image,
    this.extractedText = '',
    this.isLoading = false,
    this.error,
  });

  bool get hasImage => image != null;
  bool get hasText => extractedText.trim().isNotEmpty;
  bool get isComplete => isRequired ? (hasImage || hasText) : true;

  double? get numericValue => ReadingParser.parseNumeric(extractedText);

  String get formattedDisplayValue {
    final double? num = numericValue;
    if (num != null) {
      return ReadingParser.formatWeight(num);
    }
    if (extractedText.trim().isNotEmpty) {
      return extractedText.trim();
    }
    return 'Not Provided';
  }

  void reset() {
    image = null;
    extractedText = '';
    isLoading = false;
    error = null;
  }
}
