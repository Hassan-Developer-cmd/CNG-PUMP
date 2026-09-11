import 'dart:io';
import 'package:flutter/material.dart';
import '../utils/reading_parser.dart';

enum CngReadingType {
  digitalMachine,
  manualData,
  microMotion,
  suiGas,
}

/// The two data-source modes for the first ("primary") reading card on the
/// Dashboard. Chosen via the "Select Nozzle" dropdown — switching modes
/// swaps that card's title/icon between a Nozzle (Digital Machine) reading
/// and a standalone Meter reading, per the design reference.
enum PrimarySourceMode { nozzle, meter }

class CngReadingItem {
  final CngReadingType type;
  final bool isRequired;

  // Mutable so the primary (first) card can be relabeled when the user
  // switches between Nozzle and Meter mode without changing its identity.
  String title;
  IconData icon;

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
