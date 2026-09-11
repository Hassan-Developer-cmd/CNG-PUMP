import 'package:flutter/material.dart';

import '../models/comparison_history_item.dart';
import '../models/comparison_result_model.dart';

/// Holds the log of past comparisons shown on the History screen.
///
/// A new record is appended every time a comparison finishes on the
/// Comparing Data screen, newest first.
class HistoryProvider extends ChangeNotifier {
  final List<ComparisonHistoryItem> _records = [];

  List<ComparisonHistoryItem> get records => List.unmodifiable(_records);

  bool get isEmpty => _records.isEmpty;

  void addFromResult(ComparisonResultModel result) {
    _records.insert(0, ComparisonHistoryItem.fromResult(result));
    notifyListeners();
  }

  void clearAll() {
    _records.clear();
    notifyListeners();
  }
}
