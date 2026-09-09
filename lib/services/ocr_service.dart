import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // Letters we treat as garbled digits on 7-segment / dot-matrix displays.
  static const _digitLikeLetters = {
    'O',
    'o',
    'I',
    'l',
    '|',
    'S',
    's',
    'B',
    'Z',
  };

  static final RegExp _numberRunRegex = RegExp(r'\d+(?:[.,]\d+)?');

  /// How close (as a fraction of element height) two elements' vertical
  /// centers need to be before we treat them as "the same row". This is
  /// what lets a large integer part and a smaller decimal-fraction part
  /// (a very common layout on digital meters, e.g. big "858" + small
  /// ".11") get merged back into one reading, even though ML Kit reports
  /// them as separate lines because of the font-size difference.
  static const double _rowMergeTolerance = 0.9;

  Future<String> extractText(File imageFile, {bool digitsOnly = false}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _recognizer.processImage(inputImage);

      // Flatten every element from every line/block into one list, keeping
      // its raw text and bounding box.
      final elements = <_Elem>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          for (final element in line.elements) {
            elements.add(_Elem(text: element.text, box: element.boundingBox));
          }
        }
      }

      if (elements.isEmpty) {
        // ignore: avoid_print
        print('[OCR-DEBUG] No text elements detected at all.');
        return 'Unable to read meter';
      }

      final rows = _clusterIntoRows(elements);

      final candidates = <_NumberCandidate>[];

      for (final row in rows) {
        // Sort left-to-right so digits/decimal fragments concatenate in
        // the correct reading order.
        row.elems.sort((a, b) => a.box.left.compareTo(b.box.left));

        final rawRow = row.elems.map((e) => e.text).join(' ');

        final hasUnexpectedLetter = rawRow
            .split('')
            .any((ch) => _isLetter(ch) && !_digitLikeLetters.contains(ch));

        // ignore: avoid_print
        print(
          '[OCR-DEBUG] row="$rawRow" hasUnexpectedLetter=$hasUnexpectedLetter '
          'top=${row.top}',
        );

        if (hasUnexpectedLetter) continue;

        final cleaned = _cleanText(rawRow).replaceAll(RegExp(r'\s+'), '');
        if (cleaned.isEmpty) continue;

        final matches = _numberRunRegex.allMatches(cleaned).toList();
        if (matches.isEmpty) continue;

        matches.sort(
          (a, b) => b.group(0)!.length.compareTo(a.group(0)!.length),
        );
        final bestMatchOnRow = matches.first.group(0)!;

        final digitCount = bestMatchOnRow
            .replaceAll(RegExp(r'[^0-9]'), '')
            .length;
        if (digitCount < 2) continue;

        // ignore: avoid_print
        print('[OCR-DEBUG]   -> candidate="$bestMatchOnRow" top=${row.top}');

        candidates.add(
          _NumberCandidate(
            value: bestMatchOnRow.replaceAll(',', '.'),
            top: row.top,
          ),
        );
      }

      if (candidates.isEmpty) {
        // ignore: avoid_print
        print('[OCR-DEBUG] No candidates passed filtering.');
        return 'Unable to read meter';
      }

      // Main reading = topmost merged row.
      candidates.sort((a, b) => a.top.compareTo(b.top));
      final best = candidates.first;

      return digitsOnly
          ? best.value.replaceAll(RegExp(r'[^0-9]'), '')
          : best.value;
    } catch (e) {
      return 'Unable to read meter';
    }
  }

  /// Groups elements into rows based on vertical proximity, so that a big
  /// integer part and a small decimal-fraction part sitting next to each
  /// other are treated as one reading even if ML Kit split them into
  /// separate "lines" because of the font-size difference.
  List<_Row> _clusterIntoRows(List<_Elem> elements) {
    // Process top-to-bottom so rows form in a stable, predictable order.
    final sorted = [...elements]
      ..sort((a, b) => a.box.top.compareTo(b.box.top));

    final rows = <_Row>[];

    for (final elem in sorted) {
      final elemCenter = (elem.box.top + elem.box.bottom) / 2;
      final elemHeight = elem.box.height;

      _Row? target;
      for (final row in rows) {
        final rowCenter = (row.top + row.bottom) / 2;
        final maxHeight = [
          elemHeight,
          row.bottom - row.top,
        ].reduce((a, b) => a > b ? a : b);
        final tolerance = maxHeight * _rowMergeTolerance;

        if ((elemCenter - rowCenter).abs() <= tolerance) {
          target = row;
          break;
        }
      }

      if (target != null) {
        target.elems.add(elem);
        target.top = target.top < elem.box.top ? target.top : elem.box.top;
        target.bottom = target.bottom > elem.box.bottom
            ? target.bottom
            : elem.box.bottom;
      } else {
        rows.add(
          _Row(top: elem.box.top, bottom: elem.box.bottom, elems: [elem]),
        );
      }
    }

    return rows;
  }

  bool _isLetter(String ch) {
    if (ch.isEmpty) return false;
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  String _cleanText(String text) {
    return text
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('|', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2');
  }

  Future<void> dispose() async {
    await _recognizer.close();
  }
}

class _Elem {
  final String text;
  final Rect box;

  const _Elem({required this.text, required this.box});
}

class _Row {
  double top;
  double bottom;
  final List<_Elem> elems;

  _Row({required this.top, required this.bottom, required this.elems});
}

class _NumberCandidate {
  final String value;
  final double top;

  const _NumberCandidate({required this.value, required this.top});
}
