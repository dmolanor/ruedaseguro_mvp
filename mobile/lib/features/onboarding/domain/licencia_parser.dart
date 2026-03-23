import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class LicenciaParseResult {
  final String? licenciaNumber;
  final List<String> categories; // e.g. ['1°', '2°'] — grados authorized
  final DateTime? expiryDate;
  final String? bloodType; // e.g. 'A+', 'O-', 'AB+'
  final String? holderCedula; // V12345678 — for cross-validation
  final String? holderName;
  final double confidence;
  final Map<String, double> fieldConfidences;

  const LicenciaParseResult({
    this.licenciaNumber,
    this.categories = const [],
    this.expiryDate,
    this.bloodType,
    this.holderCedula,
    this.holderName,
    required this.confidence,
    this.fieldConfidences = const {},
  });

  factory LicenciaParseResult.empty() =>
      const LicenciaParseResult(confidence: 0.0);

  /// Whether the license authorizes motorcycle driving (1° grado).
  bool get authorizedForMotorcycle => categories.any((c) => c.contains('1'));
}

class LicenciaParser {
  LicenciaParser._();

  // Venezuelan cédula embedded in the license text
  static final _cedulaRegex = RegExp(
    r'[VvEe][\s.\-]?\s*(\d{1,3}[.,]?\d{3}[.,]?\d{0,3})',
    caseSensitive: false,
  );

  // Grado categories: 1°, 2°, 3°, 4°, 5° or GRADO 1, GRADO 2, etc.
  static final _gradoRegex = RegExp(
    r'([1-5])\s*[°ºo]|\bGRADO\s*([1-5])\b',
    caseSensitive: false,
  );

  // Dates in dd/mm/yyyy or dd-mm-yyyy format
  static final _dateRegex = RegExp(
    r'\b(\d{1,2})[\/\-.]\s*(\d{1,2})[\/\-.]\s*(\d{4})\b',
  );

  // Blood type: A+, A-, B+, B-, AB+, AB-, O+, O-
  static final _bloodTypeRegex = RegExp(
    r'\b(AB|[ABO])\s*([+-])',
    caseSensitive: false,
  );

  // License number: long alphanumeric string (8+ chars), often near LICENCIA label
  static final _licNumRegex = RegExp(
    r'\b(\d{6,12})\b',
  );

  // Keywords that indicate this is a driver's license document
  static final _licenciaKeyword = RegExp(
    r'LICENCIA|CONDUCIR|TRANSPORTE\s*TERRESTRE',
    caseSensitive: false,
  );

  /// Keywords to exclude from name extraction.
  static const _nameExclusions = {
    'REPUBLICA', 'BOLIVARIANA', 'VENEZUELA', 'INSTITUTO', 'NACIONAL',
    'TRANSPORTE', 'TERRESTRE', 'LICENCIA', 'CONDUCIR', 'GRADO',
    'FECHA', 'EMISION', 'VENCIMIENTO', 'NACIMIENTO', 'SANGRE',
    'GRUPO', 'SANGUINEO', 'RESTRICCIONES', 'CATEGORIA', 'TIPO',
    'PARA', 'INTT', 'FIRMA', 'TITULAR', 'PORTADOR',
  };

  static LicenciaParseResult parse(String rawText, List<TextBlock> blocks) {
    if (rawText.trim().isEmpty) return LicenciaParseResult.empty();

    final upper = rawText.toUpperCase();
    final fieldConf = <String, double>{};

    // Verify this looks like a license document
    final isLicencia = _licenciaKeyword.hasMatch(upper);
    if (!isLicencia && blocks.isEmpty) {
      return LicenciaParseResult.empty();
    }

    // --- Holder cédula ---
    String? holderCedula;
    final cedulaMatch = _cedulaRegex.firstMatch(rawText);
    if (cedulaMatch != null) {
      holderCedula = cedulaMatch
          .group(0)!
          .replaceAll(RegExp(r'[.,\s\-]'), '')
          .toUpperCase();
      fieldConf['holderCedula'] = 0.9;
    }

    // --- Categories (grados) ---
    final categories = <String>{};
    for (final m in _gradoRegex.allMatches(rawText)) {
      final grado = m.group(1) ?? m.group(2);
      if (grado != null) categories.add('$grado°');
    }
    if (categories.isNotEmpty) {
      fieldConf['categories'] = 0.85;
    }

    // --- Blood type ---
    String? bloodType;
    // Look near GS / GRUPO / SANGRE label
    final bloodMatch = _bloodTypeRegex.firstMatch(rawText);
    if (bloodMatch != null) {
      bloodType = '${bloodMatch.group(1)!.toUpperCase()}${bloodMatch.group(2)}';
      fieldConf['bloodType'] = 0.85;
    }

    // --- Dates: find all dates, determine which is expiry ---
    DateTime? expiryDate;
    final dates = <DateTime>[];
    for (final m in _dateRegex.allMatches(rawText)) {
      final d = _tryParseDate(
        int.tryParse(m.group(1)!),
        int.tryParse(m.group(2)!),
        int.tryParse(m.group(3)!),
      );
      if (d != null) dates.add(d);
    }
    if (dates.isNotEmpty) {
      // Expiry is typically the latest future date; issue date is in the past
      dates.sort();
      // Pick the latest date as expiry (it's usually in the future or recent past)
      expiryDate = dates.last;
      fieldConf['expiryDate'] = 0.8;
    }

    // --- License number ---
    // Look for a long numeric string that isn't the cédula number
    String? licenciaNumber;
    final cedulaDigits =
        holderCedula?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    for (final m in _licNumRegex.allMatches(rawText)) {
      final num = m.group(1)!;
      // Skip if it matches the cédula digits or a year
      if (num == cedulaDigits) continue;
      if (num.length == 4 && int.tryParse(num)! >= 1950 && int.tryParse(num)! <= 2030) {
        continue;
      }
      // Prefer longer numbers (license numbers are typically 8-12 digits)
      if (licenciaNumber == null || num.length > licenciaNumber.length) {
        licenciaNumber = num;
      }
    }
    if (licenciaNumber != null) {
      fieldConf['licenciaNumber'] = 0.75;
    }

    // --- Holder name ---
    String? holderName;
    final nameLines = _extractNameLines(blocks, upper);
    if (nameLines.isNotEmpty) {
      holderName = _capitalizeWords(nameLines.first);
      fieldConf['holderName'] = 0.7;
    }

    // Overall confidence
    final scores = fieldConf.values;
    final overall = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

    return LicenciaParseResult(
      licenciaNumber: licenciaNumber,
      categories: categories.toList()..sort(),
      expiryDate: expiryDate,
      bloodType: bloodType,
      holderCedula: holderCedula,
      holderName: holderName,
      confidence: overall,
      fieldConfidences: fieldConf,
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime? _tryParseDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return null;
    if (year < 1990 || year > 2040) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } on Exception {
      return null;
    }
  }

  static List<String> _extractNameLines(
      List<TextBlock> blocks, String upper) {
    final candidates = <String>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim().toUpperCase();
        if (text.length < 3 || text.length > 40) continue;
        if (text.contains(RegExp(r'\d'))) continue;
        final words = text.split(RegExp(r'\s+'));
        if (words.any((w) => _nameExclusions.contains(_stripAccents(w)))) {
          continue;
        }
        if (RegExp(r'^[A-ZÁÉÍÓÚÜÑ\s]+$').hasMatch(text)) {
          candidates.add(text);
        }
      }
    }
    return candidates;
  }

  static String _stripAccents(String s) {
    const from = 'ÁÉÍÓÚÜÑáéíóúüñ';
    const to = 'AEIOUUNaeiouun';
    var result = s;
    for (var i = 0; i < from.length; i++) {
      result = result.replaceAll(from[i], to[i]);
    }
    return result;
  }

  static String _capitalizeWords(String s) {
    return s
        .toLowerCase()
        .split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}
