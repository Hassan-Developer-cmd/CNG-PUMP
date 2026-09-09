/// Strict CNG meter reading parser.
///
/// IMPORTANT: This parser never invents digits. It only returns numeric text
/// that ML Kit actually recognized. Ambiguous or low-quality candidates are
/// rejected instead of guessing.
class ReadingParser {
  ReadingParser._();

  static final RegExp _numberPattern = RegExp(
    r'\d{1,3}(?:,\d{3})+(?:\.\d+)?|\d+(?:\.\d+)?',
  );

  static final RegExp _allowedLinePattern = RegExp(
    r'^[\s\d.,:;\-_/()\[\]#]+(?:kg|k9|g|gal|gallons?|lit(?:re|er)s?|l)?[\s]*$',
    caseSensitive: false,
  );

  /// Extracts a reading only when the OCR line itself looks like a meter
  /// display. Returns null rather than selecting a random number.
  static String? extractMeterReading(
    String? rawText, {
    List<String>? recognizedLines,
  }) {
    final lines =
        recognizedLines?.where((e) => e.trim().isNotEmpty).toList() ??
        (rawText ?? '').split('\n').where((e) => e.trim().isNotEmpty).toList();

    final candidates = <_Candidate>[];

    for (final line in lines) {
      final candidate = _candidateFromLine(line);
      if (candidate != null) candidates.add(candidate);
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.score.compareTo(a.score));

    // Do not return a weak candidate just because it is the largest number.
    if (candidates.first.score < 70) return null;

    // If two strong candidates disagree, do not guess which one is real.
    final best = candidates.first;
    final strong = candidates.where((c) => c.score >= best.score - 8).toList();
    final distinct = strong.map((c) => c.cleaned).toSet();
    if (distinct.length > 1) return null;

    return best.cleaned;
  }

  static List<String> extractAllMeterReadings(List<String> recognizedLines) {
    final result = <String>[];
    final seen = <String>{};
    for (final line in recognizedLines) {
      final c = _candidateFromLine(line);
      if (c != null && seen.add(c.cleaned)) result.add(c.cleaned);
    }
    return result;
  }

  static _Candidate? _candidateFromLine(String line) {
    final text = line.trim();
    if (text.isEmpty) return null;

    final matches = _numberPattern.allMatches(text).toList();
    if (matches.isEmpty) return null;

    // A meter display line should be overwhelmingly numeric. This prevents
    // numbers from ordinary labels/surrounding text from being accepted.
    final compact = text.replaceAll(RegExp(r'\s+'), '');
    final numericChars = RegExp(r'[0-9]').allMatches(compact).length;
    final allowedChars = RegExp(
      r'[0-9.,:;\-_/()\[\]#a-zA-Z]',
    ).allMatches(compact).length;
    final digitRatio = numericChars / compact.length;

    final lower = text.toLowerCase();
    final hasUnit = RegExp(
      r'\bkg\b|\bgal(?:lons?)?\b|\blit(?:re|er)s?\b|\bl\b',
    ).hasMatch(lower);
    final hasLetters = RegExp(r'[a-zA-Z]').hasMatch(text);

    // Only known measurement units may accompany the number. Arbitrary OCR
    // words such as pump IDs, prices or labels are rejected.
    if (hasLetters && !hasUnit) return null;
    if (!_allowedLinePattern.hasMatch(text) && !hasUnit) return null;
    if (numericChars < 2) return null;
    if (digitRatio < 0.55) return null;
    if (allowedChars == 0) return null;

    // A real display reading normally consists of one main numeric token.
    // Multiple unrelated numbers in the same line are considered ambiguous.
    if (matches.length != 1) return null;

    final raw = matches.single.group(0)!;
    final cleaned = raw.replaceAll(',', '');
    final value = double.tryParse(cleaned);
    if (value == null || !value.isFinite) return null;

    // Reject obviously impossible OCR noise.
    if (value < 0 || value > 999999999) return null;

    var score = 0;
    score += (digitRatio * 60).round();
    score += numericChars.clamp(0, 12) * 3;
    if (cleaned.contains('.')) score += 10;
    if (hasUnit) score += 20;
    if (matches.single.start == 0) score += 5;
    if (matches.single.end == text.length ||
        text.substring(matches.single.end).trim().isEmpty ||
        hasUnit) {
      score += 10;
    }

    return _Candidate(cleaned: cleaned, score: score);
  }

  static double? parseNumeric(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final value = extractMeterReading(input);
    return value == null ? null : double.tryParse(value);
  }

  static String formatWeight(double? value, {String unit = 'KG'}) {
    if (value == null) return 'Not Provided';
    return '${value.toStringAsFixed(2)} $unit';
  }

  /// Returns the spread (max - min) across every reading that was actually
  /// provided. This always considers ALL of digitalMachine, manualData, and
  /// microMotion together — it does not special-case just the first two,
  /// so changing any one of the three readings affects the result.
  static double calculateDifference({
    double? digitalMachine,
    double? manualData,
    double? microMotion,
  }) {
    final values = [
      if (digitalMachine != null) digitalMachine,
      if (manualData != null) manualData,
      if (microMotion != null) microMotion,
    ];
    if (values.length < 2) return 0.0;
    return values.reduce((a, b) => a > b ? a : b) -
        values.reduce((a, b) => a < b ? a : b);
  }

  static String? extractValidInteger(
    String? input, {
    List<String>? recognizedLines,
  }) => extractMeterReading(input, recognizedLines: recognizedLines);
}

class _Candidate {
  final String cleaned;
  final int score;
  const _Candidate({required this.cleaned, required this.score});
}
