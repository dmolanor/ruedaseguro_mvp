import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CedulaParseResult {
  final String? idType; // 'V' or 'E'
  final String? idNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? sex;
  final double confidence;
  final Map<String, double> fieldConfidences;

  const CedulaParseResult({
    this.idType,
    this.idNumber,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.nationality,
    this.sex,
    required this.confidence,
    this.fieldConfidences = const {},
  });

  factory CedulaParseResult.empty() => const CedulaParseResult(confidence: 0.0);

  CedulaParseResult copyWith({
    String? idType,
    String? idNumber,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? sex,
    double? confidence,
    Map<String, double>? fieldConfidences,
  }) {
    return CedulaParseResult(
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      confidence: confidence ?? this.confidence,
      fieldConfidences: fieldConfidences ?? this.fieldConfidences,
    );
  }
}

class CedulaParser {
  CedulaParser._();

  // Venezuelan cedula: V-12.345.678
  static final _cedulaRegex = RegExp(
    r'([VvEe])[.\-\s]?\s*(\d{1,3}[.,]?\d{3}[.,]?\d{0,3})',
    caseSensitive: false,
  );

  static final _dobRegex = RegExp(
    r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})\b',
  );

  static final _sexRegex = RegExp(
    r'\b(MASCULINO|FEMENINO|MASC|FEM)\b|(?<!\w)([MF])(?!\w)',
    caseSensitive: false,
  );
  static final _nationalityRegex = RegExp(
    r'\b(VENEZOLAN[OA]|EXTRANJERO[A]?)\b',
    caseSensitive: false,
  );

  /// Keywords to exclude from name extraction (all without accents — comparison
  /// strips accents before lookup).
  static const _nameExclusions = {
    'REPUBLICA', 'BOLIVARIANA', 'VENEZUELA', 'CEDULA', 'IDENTIDAD',
    'NOMBRES', 'APELLIDOS', 'FECHA', 'NACIMIENTO', 'SEXO', 'NATIONALITY',
    'NACIONALIDAD', 'MASCULINO', 'FEMENINO', 'EXPIRACION', 'EXPIRY',
    'MASC', 'FEM', 'VENEZOLANO', 'VENEZOLANA',
    // Venezuelan marital status
    'SOLTERO', 'SOLTERA', 'CASADO', 'CASADA', 'DIVORCIADO', 'DIVORCIADA',
    'VIUDO', 'VIUDA',
  };

  static CedulaParseResult parse(String rawText, List<TextBlock> blocks) {
    final normalized = rawText.toUpperCase();
    final fieldConf = <String, double>{};

    // --- ID number ---
    String? idType;
    String? idNumber;

    final cedulaMatch = _cedulaRegex.firstMatch(rawText);
    if (cedulaMatch != null) {
      idType = cedulaMatch.group(1)!.toUpperCase();
      idNumber = cedulaMatch.group(2)!.replaceAll(RegExp(r'[.,\s]'), '');
      fieldConf['idType'] = 0.95;
      fieldConf['idNumber'] = 0.95;
    }

    // --- Date of birth ---
    DateTime? dob;
    final dobMatch = _dobRegex.firstMatch(rawText);
    if (dobMatch != null) {
      dob = _tryParseDate(
        int.tryParse(dobMatch.group(1)!),
        int.tryParse(dobMatch.group(2)!),
        int.tryParse(dobMatch.group(3)!),
      );
      if (dob != null) fieldConf['dateOfBirth'] = 0.85;
    }

    // --- Nationality ---
    String? nationality;
    final natMatch = _nationalityRegex.firstMatch(normalized);
    if (natMatch != null) {
      final raw = natMatch.group(0)!.toUpperCase();
      nationality = raw.contains('EXTRAN') ? 'EXTRANJERO' : 'VENEZOLANO';
      fieldConf['nationality'] = 0.9;
    }

    // --- Sex ---
    String? sex;
    final sexMatch = _sexRegex.firstMatch(normalized);
    if (sexMatch != null) {
      final raw = (sexMatch.group(1) ?? sexMatch.group(2))!.toUpperCase();
      sex = (raw.startsWith('M')) ? 'M' : 'F';
      fieldConf['sex'] = 0.85;
    }

    // --- Name extraction ---
    String? firstName;
    String? lastName;

    final nameLines = _extractNameLines(blocks, rawText);
    if (nameLines.isNotEmpty) {
      if (nameLines.length >= 2) {
        firstName = _capitalizeWords(nameLines[0]);
        lastName = _capitalizeWords(nameLines[1]);
        fieldConf['firstName'] = 0.75;
        fieldConf['lastName'] = 0.75;
      } else if (nameLines.length == 1) {
        final parts = nameLines[0].trim().split(RegExp(r'\s+'));
        if (parts.length >= 2) {
          firstName = _capitalizeWords(
            parts.take(parts.length ~/ 2 + parts.length % 2).join(' '),
          );
          lastName = _capitalizeWords(
            parts.skip(parts.length ~/ 2 + parts.length % 2).join(' '),
          );
          fieldConf['firstName'] = 0.6;
          fieldConf['lastName'] = 0.6;
        }
      }
    }

    // Overall confidence
    final scores = fieldConf.values;
    final overall = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

    return CedulaParseResult(
      idType: idType,
      idNumber: idNumber,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dob,
      nationality: nationality,
      sex: sex,
      confidence: overall,
      fieldConfidences: fieldConf,
    );
  }

  // ---------------------------------------------------------------------------
  // Name extraction
  // ---------------------------------------------------------------------------

  static List<String> _extractNameLines(
    List<TextBlock> blocks,
    String rawText,
  ) {
    final candidates = <String>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim().toUpperCase();
        // Must be all-caps, reasonable length, no digits, not a keyword
        if (text.length < 3 || text.length > 40) continue;
        if (text.contains(RegExp(r'\d'))) continue;
        final words = text.split(RegExp(r'\s+'));
        // Strip accents before checking exclusions so "REPÚBLICA" matches "REPUBLICA"
        if (words.any((w) => _nameExclusions.contains(_stripAccents(w))))
          continue;
        // Looks like a name
        if (RegExp(r'^[A-ZÁÉÍÓÚÜÑ\s]+$').hasMatch(text)) {
          candidates.add(text);
        }
      }
    }
    return candidates;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime? _tryParseDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return null;
    if (year < 1900 || year > DateTime.now().year) return null;
    try {
      final candidate = DateTime(year, month, day);
      final age = DateTime.now().difference(candidate).inDays ~/ 365;
      if (age >= 16 && age <= 100) return candidate;
    } on Exception {
      // ignore
    }
    return null;
  }

  /// Strips diacritical marks so "REPÚBLICA" → "REPUBLICA", "CÉDULA" → "CEDULA".
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
