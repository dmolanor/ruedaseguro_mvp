import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CedulaParseResult {
  final String? idType; // 'V', 'E', or 'CC'
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
}

class CedulaParser {
  CedulaParser._();

  // Venezuelan cedula: V-12.345.678
  static final _cedulaRegex = RegExp(
    r'([VvEe])[.\-\s]?\s*(\d{1,3}[.,]?\d{3}[.,]?\d{0,3})',
    caseSensitive: false,
  );

  // Colombian CC detection
  static final _colombiaKeyword = RegExp(r'\bCOLOMBI', caseSensitive: false);

  // Colombian CC number: 1.127.577.617 (4 groups) or 12.345.678 (3 groups) or 1234567890
  // 4-group pattern listed FIRST so it matches before the shorter 3-group alternative.
  static final _ccNumberRegex = RegExp(
    r'\b(\d{1,2}[.,]\d{3}[.,]\d{3}[.,]\d{3}|\d{1,3}[.,]\d{3}[.,]\d{3,4}|\d{8,10})\b',
  );

  static final _dobRegex = RegExp(
    r'\b(\d{1,2})[\/\-.](\d{1,2})[\/\-.](\d{4})\b',
  );

  // Colombian CC back uses month abbreviation: 11-DIC-2003
  static final _dobMonthNameRegex = RegExp(
    r'\b(\d{1,2})[\/\-.]([A-Z]{3,4})[\/\-.](\d{4})\b',
    caseSensitive: false,
  );

  static final _sexRegex = RegExp(
    r'\b(MASCULINO|FEMENINO|MASC|FEM)\b|(?<!\w)([MF])(?!\w)',
    caseSensitive: false,
  );
  static final _nationalityRegex = RegExp(
    r'\b(VENEZOLAN[OA]|EXTRANJERO[A]?|COLOMBIAN[OA])\b',
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
    // Colombian CC labels
    'COLOMBIA', 'IDENTIFICACION', 'PERSONAL', 'CIUDADANIA', 'NUMERO',
    'FIRMA', 'ESTATURA', 'EXPEDICION', 'LUGAR', 'REGISTRADOR', 'NACIONAL',
    'INDICE', 'DERECHO',
  };

  /// Spanish month abbreviations for parsing dates like "11-DIC-2003".
  static const _monthAbbr = {
    'ENE': 1, 'FEB': 2, 'MAR': 3, 'ABR': 4, 'MAY': 5, 'JUN': 6,
    'JUL': 7, 'AGO': 8, 'SEP': 9, 'OCT': 10, 'NOV': 11, 'DIC': 12,
  };

  static CedulaParseResult parse(String rawText, List<TextBlock> blocks) {
    final normalized = rawText.toUpperCase();
    final fieldConf = <String, double>{};

    // --- ID number ---
    String? idType;
    String? idNumber;

    // Detect Colombian document first (COLOMBIA keyword present, no V/E prefix)
    final isColombian = _colombiaKeyword.hasMatch(normalized) &&
        !_cedulaRegex.hasMatch(rawText);
    if (isColombian) {
      final ccMatch = _ccNumberRegex.firstMatch(rawText);
      if (ccMatch != null) {
        idType = 'CC';
        idNumber = ccMatch.group(0)!.replaceAll(RegExp(r'[.,\s]'), '');
        fieldConf['idType'] = 0.9;
        fieldConf['idNumber'] = 0.9;
      }
    } else {
      final cedulaMatch = _cedulaRegex.firstMatch(rawText);
      if (cedulaMatch != null) {
        idType = cedulaMatch.group(1)!.toUpperCase();
        idNumber = cedulaMatch.group(2)!.replaceAll(RegExp(r'[.,\s]'), '');
        fieldConf['idType'] = 0.95;
        fieldConf['idNumber'] = 0.95;
      }
    }

    // --- Date of birth ---
    DateTime? dob;
    // Try numeric format first (dd/mm/yyyy)
    final dobMatch = _dobRegex.firstMatch(rawText);
    if (dobMatch != null) {
      dob = _tryParseDate(
        int.tryParse(dobMatch.group(1)!),
        int.tryParse(dobMatch.group(2)!),
        int.tryParse(dobMatch.group(3)!),
      );
      if (dob != null) fieldConf['dateOfBirth'] = 0.85;
    }
    // Try month-name format (11-DIC-2003) — used on Colombian CC back
    if (dob == null) {
      final dobNameMatch = _dobMonthNameRegex.firstMatch(rawText);
      if (dobNameMatch != null) {
        final month = _monthAbbr[dobNameMatch.group(2)!.toUpperCase()];
        if (month != null) {
          dob = _tryParseDate(
            int.tryParse(dobNameMatch.group(1)!),
            month,
            int.tryParse(dobNameMatch.group(3)!),
          );
          if (dob != null) fieldConf['dateOfBirth'] = 0.85;
        }
      }
    }

    // --- Nationality ---
    String? nationality;
    final natMatch = _nationalityRegex.firstMatch(normalized);
    if (natMatch != null) {
      final raw = natMatch.group(0)!.toUpperCase();
      if (raw.contains('EXTRAN')) {
        nationality = 'EXTRANJERO';
      } else if (raw.contains('COLOMBI')) {
        nationality = 'COLOMBIANO';
      } else {
        nationality = 'VENEZOLANO';
      }
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

    // For Colombian CC, try label-based extraction first (more reliable).
    if (isColombian) {
      final names = _extractColombianNames(blocks);
      if (names.$1 != null) {
        lastName = _capitalizeWords(names.$1!);
        fieldConf['lastName'] = 0.85;
      }
      if (names.$2 != null) {
        firstName = _capitalizeWords(names.$2!);
        fieldConf['firstName'] = 0.85;
      }
    }

    // Fallback: generic uppercase-cluster extraction (Venezuelan or failed Colombian).
    if (firstName == null && lastName == null) {
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
            firstName = _capitalizeWords(parts.take(parts.length ~/ 2 + parts.length % 2).join(' '));
            lastName = _capitalizeWords(parts.skip(parts.length ~/ 2 + parts.length % 2).join(' '));
            fieldConf['firstName'] = 0.6;
            fieldConf['lastName'] = 0.6;
          }
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
  // Colombian CC label-based name extraction
  // ---------------------------------------------------------------------------

  /// Returns (lastName, firstName) extracted by looking for APELLIDOS / NOMBRES
  /// labels in the text blocks and reading the adjacent line.
  ///
  /// Colombian CC layout (front):
  ///   MOLANO ROA          ← value (large text)
  ///   APELLIDOS           ← label (small text below)
  ///   DIEGO ALEJANDRO     ← value (large text)
  ///   NOMBRES             ← label (small text below)
  static (String?, String?) _extractColombianNames(List<TextBlock> blocks) {
    String? lastName;
    String? firstName;

    for (final block in blocks) {
      for (var i = 0; i < block.lines.length; i++) {
        final lineUpper = _stripAccents(block.lines[i].text.trim().toUpperCase());

        // --- APELLIDOS label ---
        if (lineUpper.contains('APELLIDOS')) {
          // Value is typically the line BEFORE the label
          if (i > 0 && lastName == null) {
            final candidate = block.lines[i - 1].text.trim();
            if (_isNameCandidate(candidate)) {
              lastName = candidate.toUpperCase();
            }
          }
          // Or value embedded on the same line after the label
          if (lastName == null) {
            final afterLabel = lineUpper
                .replaceAll(RegExp(r'APELLIDOS\s*:?\s*'), '')
                .trim();
            if (afterLabel.length >= 2 && _isNameCandidate(afterLabel)) {
              lastName = afterLabel;
            }
          }
        }

        // --- NOMBRES label ---
        if (lineUpper.contains('NOMBRES') && !lineUpper.contains('APELLIDOS')) {
          if (i > 0 && firstName == null) {
            final candidate = block.lines[i - 1].text.trim();
            if (_isNameCandidate(candidate)) {
              firstName = candidate.toUpperCase();
            }
          }
          if (firstName == null) {
            final afterLabel = lineUpper
                .replaceAll(RegExp(r'NOMBRES\s*:?\s*'), '')
                .trim();
            if (afterLabel.length >= 2 && _isNameCandidate(afterLabel)) {
              firstName = afterLabel;
            }
          }
        }
      }
    }

    // Also try cross-block: label in one block, value in adjacent block position.
    if (lastName == null || firstName == null) {
      for (var b = 0; b < blocks.length; b++) {
        final blockText = _stripAccents(blocks[b].text.toUpperCase());
        if (blockText.contains('APELLIDOS') && lastName == null && b > 0) {
          final prevText = blocks[b - 1].text.trim();
          if (_isNameCandidate(prevText)) lastName = prevText.toUpperCase();
        }
        if (blockText.contains('NOMBRES') &&
            !blockText.contains('APELLIDOS') &&
            firstName == null &&
            b > 0) {
          final prevText = blocks[b - 1].text.trim();
          if (_isNameCandidate(prevText)) firstName = prevText.toUpperCase();
        }
      }
    }

    return (lastName, firstName);
  }

  /// Returns true if [text] looks like a person's name (all letters, no digits,
  /// no known labels/keywords).
  static bool _isNameCandidate(String text) {
    final upper = text.toUpperCase().trim();
    if (upper.length < 2 || upper.length > 40) return false;
    if (upper.contains(RegExp(r'\d'))) return false;
    if (!RegExp(r'^[A-ZÁÉÍÓÚÜÑ\s\-]+$').hasMatch(upper)) return false;
    final words = upper.split(RegExp(r'\s+'));
    if (words.any((w) => _nameExclusions.contains(_stripAccents(w)))) return false;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Generic name extraction (Venezuelan cedula / fallback)
  // ---------------------------------------------------------------------------

  static List<String> _extractNameLines(List<TextBlock> blocks, String rawText) {
    final candidates = <String>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim().toUpperCase();
        // Must be all-caps, reasonable length, no digits, not a keyword
        if (text.length < 3 || text.length > 40) continue;
        if (text.contains(RegExp(r'\d'))) continue;
        final words = text.split(RegExp(r'\s+'));
        // Strip accents before checking exclusions so "REPÚBLICA" matches "REPUBLICA"
        if (words.any((w) => _nameExclusions.contains(_stripAccents(w)))) continue;
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
    const to   = 'AEIOUUNaeiouun';
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
