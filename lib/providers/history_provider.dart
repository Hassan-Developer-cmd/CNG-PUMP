import 'package:flutter/material.dart';
import '../models/capture_history_item.dart';

class HistoryProvider extends ChangeNotifier {
  final List<CaptureHistoryItem> _records = [];
  List<CaptureHistoryItem> get records => List.unmodifiable(_records);
  bool get isEmpty => _records.isEmpty;

  void addCapture({required List<CapturedImage> images}) {
    if (images.isEmpty) return;
    _records.insert(0, CaptureHistoryItem(dateTime: DateTime.now(), images: List.unmodifiable(images)));
    notifyListeners();
  }

  void clearAll() {
    _records.clear();
    notifyListeners();
  }
}
