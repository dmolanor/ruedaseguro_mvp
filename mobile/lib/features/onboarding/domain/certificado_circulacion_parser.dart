import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum CertificadoFormat { reciente, antiguo, unknown }

class CertificadoParseResult {
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? vehicleType; // 'MOTO PARTICULAR', 'MOTO CARGA', etc.
  final String? vehicleBodyType; // 'DEPORTIVA', 'SCOOTER', 'PASEO', etc.
  final String? serialNiv; // Número de Identificación Vehicular
  final String? serialMotor;
  final int? seats;
  final String? ownerName;
  final String? ownerCedula;
  final DateTime? issuedDate;
  final CertificadoFormat format;
  final double confidence;
  final Map<String, double> fieldConfidences;

  const CertificadoParseResult({
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.vehicleType,
    this.vehicleBodyType,
    this.serialNiv,
    this.serialMotor,
    this.seats,
    this.ownerName,
    this.ownerCedula,
    this.issuedDate,
    this.format = CertificadoFormat.unknown,
    required this.confidence,
    this.fieldConfidences = const {},
  });

  factory CertificadoParseResult.empty() =>
      const CertificadoParseResult(confidence: 0.0);
}

/// Parses Venezuelan INTT Certificado de Circulación.
///
/// Supports two physical formats:
/// - **Reciente**: Portrait, "CERTIFICADO DE CIRCULACIÓN" on right border
///   (rotated), guilloché background, tricolor strip at bottom. Data presented
///   WITHOUT printed field labels — values appear in a fixed grid.
/// - **Antiguo**: Landscape, INTT pattern background. Has a "Placa:" label in
///   the body whose value is EMPTY (the plate actually appears at top-right
///   unlabeled). Includes a long trámite ID at the top that must be ignored.
///
/// Fields extracted: plate, brand, model, year, vehicleType, vehicleBodyType,
/// serialNiv, serialMotor, seats, ownerName, ownerCedula, issuedDate.
///
/// Fields intentionally NOT extracted: color, peso, número de ejes, trámite ID.
class CertificadoCirculacionParser {
  CertificadoCirculacionParser._();

  // Venezuelan plate: ABC-123-DE
  static final _plateVE = RegExp(
    r'\b([A-Z]{2,3})[\s\-]?(\d{2,3})[\s\-]?([A-Z]{2,3})\b',
    caseSensitive: false,
  );

  // Year 1960-2030
  static final _yearRegex = RegExp(r'\b(19[6-9]\d|20[0-3]\d)\b');

  // NIV / Serial Carrocería — 8 to 17 alphanumeric chars (standard VIN-like)
  static final _nivRegex = RegExp(r'\b([A-Z0-9]{8,17})\b', caseSensitive: false);

  // Owner cedula inside document
  static final _cedulaRegex = RegExp(
    r'[VvEe][\s.\-]?(\d{6,9})',
    caseSensitive: false,
  );

  // Date: dd/mm/yyyy or dd-mm-yyyy
  static final _dateRegex = RegExp(
    r'\b(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})\b',
  );

  // Seats: look for 1-3 digit number near "PUESTOS" or "ASIENTOS"
  static final _seatsRegex = RegExp(r'\b([1-9]\d?)\b');

  // Trámite ID pattern (antiguo): long alphanumeric 15+ chars — must be ignored
  static final _tramiteIdRegex = RegExp(r'\b[A-Z0-9]{15,}\b', caseSensitive: false);

  static const _knownBrands = [
    'BERA', 'EMPIRE', 'HONDA', 'YAMAHA', 'SUZUKI', 'KAWASAKI', 'BAJAJ',
    'ITALIKA', 'DAYUN', 'KYMCO', 'ROOCAT', 'TVS', 'HERO', 'LIFAN',
    'HAOJUE', 'SHINERAY', 'STORM', 'AKT', 'EUROMOT', 'UM', 'LONCIN',
    'ZONGSHEN', 'BENELLI', 'ROYAL ENFIELD', 'KTM', 'PIAGGIO', 'VESPA',
    'SYM', 'CFMOTO', 'QLINK', 'KEEWAY', 'FORZA', 'DAYTONA',
  ];

  static const _bodyTypeKeywords = {
    'DEPORTIVA': 'DEPORTIVA',
    'SPORT': 'DEPORTIVA',
    'SCOOTER': 'SCOOTER',
    'ESCOOTER': 'SCOOTER',
    'PASEO': 'PASEO',
    'TOURING': 'PASEO',
    'DOBLE PROPOSITO': 'DOBLE PROPÓSITO',
    'DOBLE PROPÓSITO': 'DOBLE PROPÓSITO',
    'TRAIL': 'DOBLE PROPÓSITO',
    'ENDURO': 'DOBLE PROPÓSITO',
    'CARGO': 'CARGA',
    'CARGA': 'CARGA',
    'ELECTRICA': 'ELÉCTRICA',
    'ELÉCTRICA': 'ELÉCTRICA',
    'CHOPPER': 'CHOPPER',
    'CUSTOM': 'CHOPPER',
  };

  static const _nameExclusions = {
    'REPUBLICA', 'BOLIVARIANA', 'VENEZUELA', 'CERTIFICADO', 'CIRCULACION',
    'CIRCULACIÓN', 'TRANSPORTE', 'TERRESTRE', 'INTT', 'MINISTERIO',
    'INFRAESTRUCTURA', 'REGISTRO', 'NACIONAL', 'VEHICULOS', 'VEHÍCULOS',
    'TITULAR', 'PROPIETARIO', 'NOMBRES', 'APELLIDOS', 'PLACA', 'SERIAL',
    'MOTOR', 'CARROCERIA', 'CARROCERÍA', 'MARCA', 'MODELO', 'COLOR',
    'PARTICULAR', 'CARGA', 'USO', 'TIPO', 'PUESTOS', 'PESO',
    'EXPEDICION', 'EXPEDICIÓN', 'VIGENCIA', 'FECHA', 'MOTO',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  static CertificadoParseResult parse(String rawText, List<TextBlock> blocks) {
    final upper = rawText.toUpperCase();
    final fieldConf = <String, double>{};

    // 1. Detect format
    final format = _detectFormat(upper);

    // 2. Extract plate — same logic for both formats.
    //    In antiguo, "Placa:" label is empty, so we search globally.
    final plate = _extractPlate(rawText, upper, fieldConf);

    // 3. Vehicle type
    final vehicleType = _extractVehicleType(upper, fieldConf);

    // 4. Vehicle body type
    final vehicleBodyType = _extractBodyType(upper, fieldConf);

    // 5. Brand
    final brand = _extractBrand(upper, fieldConf);

    // 6. Year
    final year = _extractYear(rawText, fieldConf);

    // 7. Model — rough heuristic after brand
    final model = _extractModel(upper, brand, plate, year, fieldConf);

    // 8. Serial NIV
    final serialNiv = _extractNiv(rawText, upper, plate, format, fieldConf);

    // 9. Serial Motor
    final serialMotor = _extractSerialMotor(rawText, upper, serialNiv, plate, fieldConf);

    // 10. Seats
    final seats = _extractSeats(rawText, upper, fieldConf);

    // 11. Owner cedula
    final ownerCedula = _extractOwnerCedula(rawText, upper, fieldConf);

    // 12. Owner name
    final ownerName = _extractOwnerName(blocks, upper, fieldConf);

    // 13. Issued date
    final issuedDate = _extractIssuedDate(rawText, upper, fieldConf);

    // Overall confidence
    final scores = fieldConf.values;
    final overall =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    return CertificadoParseResult(
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      vehicleType: vehicleType,
      vehicleBodyType: vehicleBodyType,
      serialNiv: serialNiv,
      serialMotor: serialMotor,
      seats: seats,
      ownerName: ownerName,
      ownerCedula: ownerCedula,
      issuedDate: issuedDate,
      format: format,
      confidence: overall,
      fieldConfidences: fieldConf,
    );
  }

  // ---------------------------------------------------------------------------
  // Format detection
  // ---------------------------------------------------------------------------

  static CertificadoFormat _detectFormat(String upper) {
    // Antiguo: "Placa:" label printed in body (value is empty) OR has INTT text
    if (upper.contains('PLACA:') ||
        upper.contains('INSTITUTO NACIONAL') ||
        upper.contains('INTT')) {
      return CertificadoFormat.antiguo;
    }
    // Reciente: "CERTIFICADO DE CIRCULACION" on the rotated right border
    if (upper.contains('CERTIFICADO DE CIRCULACION') ||
        upper.contains('CERTIFICADO DE CIRCULACIÓN') ||
        upper.contains('CERTIF DE CIRCULAC')) {
      return CertificadoFormat.reciente;
    }
    return CertificadoFormat.unknown;
  }

  // ---------------------------------------------------------------------------
  // Field extractors
  // ---------------------------------------------------------------------------

  static String? _extractPlate(
      String rawText, String upper, Map<String, double> fieldConf) {
    final m = _plateVE.firstMatch(rawText);
    if (m != null) {
      final plate = '${m.group(1)!.toUpperCase()}-'
          '${m.group(2)}-'
          '${m.group(3)!.toUpperCase()}';
      fieldConf['plate'] = 0.95;
      return plate;
    }
    return null;
  }

  static String? _extractVehicleType(
      String upper, Map<String, double> fieldConf) {
    if (upper.contains('MOTO PARTICULAR') || upper.contains('MOTOCICLETA PARTICULAR')) {
      fieldConf['vehicleType'] = 0.95;
      return 'MOTO PARTICULAR';
    }
    if (upper.contains('MOTO CARGA') || upper.contains('MOTOCICLETA CARGA')) {
      fieldConf['vehicleType'] = 0.95;
      return 'MOTO CARGA';
    }
    if (upper.contains('PARTICULAR')) {
      fieldConf['vehicleType'] = 0.80;
      return 'MOTO PARTICULAR';
    }
    if (upper.contains('MOTO') || upper.contains('MOTOCICLETA')) {
      fieldConf['vehicleType'] = 0.70;
      return 'MOTO PARTICULAR';
    }
    return null;
  }

  static String? _extractBodyType(
      String upper, Map<String, double> fieldConf) {
    for (final entry in _bodyTypeKeywords.entries) {
      if (upper.contains(entry.key)) {
        fieldConf['vehicleBodyType'] = 0.85;
        return entry.value;
      }
    }
    return null;
  }

  static String? _extractBrand(
      String upper, Map<String, double> fieldConf) {
    for (final b in _knownBrands) {
      if (upper.contains(b)) {
        fieldConf['brand'] = 0.90;
        return b[0] + b.substring(1).toLowerCase();
      }
    }
    return null;
  }

  static int? _extractYear(String rawText, Map<String, double> fieldConf) {
    for (final m in _yearRegex.allMatches(rawText)) {
      final y = int.tryParse(m.group(0)!);
      if (y != null && y >= 1960 && y <= DateTime.now().year + 1) {
        fieldConf['year'] = 0.90;
        return y;
      }
    }
    return null;
  }

  static String? _extractModel(
    String upper,
    String? brand,
    String? plate,
    int? year,
    Map<String, double> fieldConf,
  ) {
    if (brand == null) return null;
    final brandUpper = brand.toUpperCase();
    final brandIdx = upper.indexOf(brandUpper);
    if (brandIdx < 0) return null;
    final end = (brandIdx + brandUpper.length + 60).clamp(0, upper.length);
    final after = upper.substring(brandIdx + brandUpper.length, end);
    // Short alphanumeric string that's not year, plate, or body-type keyword
    final modelMatch = RegExp(r'\b([A-Z0-9][A-Z0-9\s\-]{1,15})\b').firstMatch(after);
    if (modelMatch != null) {
      final candidate = modelMatch.group(0)!.trim();
      if (candidate.length >= 2 &&
          !_isExcludedWord(candidate.split(' ').first) &&
          !_yearRegex.hasMatch(candidate)) {
        fieldConf['model'] = 0.65;
        return _capitalizeWords(candidate);
      }
    }
    return null;
  }

  /// Extracts NIV / Serial Carrocería.
  ///
  /// In the **reciente** format, looks for text after "NIV" or "CARROCER" label.
  /// In the **antiguo** format, looks for "(SERIAL NIV)" or similar label.
  /// Falls back to searching for VIN-length strings that aren't trámite IDs,
  /// plates, or motor serials.
  static String? _extractNiv(
    String rawText,
    String upper,
    String? plate,
    CertificadoFormat format,
    Map<String, double> fieldConf,
  ) {
    // Try label-based extraction first
    final labels = ['SERIAL NIV', 'NIV', 'CARROCERIA', 'CARROCERÍA'];
    for (final label in labels) {
      final idx = upper.indexOf(label);
      if (idx < 0) continue;
      final searchArea = rawText.substring(
          idx + label.length, (idx + label.length + 80).clamp(0, rawText.length));
      for (final m in _nivRegex.allMatches(searchArea)) {
        final candidate = m.group(0)!.toUpperCase();
        if (_isValidSerial(candidate, plate)) {
          fieldConf['serialNiv'] = 0.88;
          return candidate;
        }
      }
    }

    // Fallback: find first 17-char VIN-like string (standard VIN length)
    for (final m in RegExp(r'\b([A-Z0-9]{17})\b', caseSensitive: false)
        .allMatches(rawText)) {
      final candidate = m.group(0)!.toUpperCase();
      if (_isValidSerial(candidate, plate) && !_tramiteIdRegex.hasMatch(candidate)) {
        fieldConf['serialNiv'] = 0.70;
        return candidate;
      }
    }

    // Fallback: 10-16 char candidate
    for (final m in _nivRegex.allMatches(rawText)) {
      final candidate = m.group(0)!.toUpperCase();
      if (candidate.length >= 10 && _isValidSerial(candidate, plate) &&
          !_tramiteIdRegex.hasMatch(candidate)) {
        fieldConf['serialNiv'] = 0.55;
        return candidate;
      }
    }

    return null;
  }

  static String? _extractSerialMotor(
    String rawText,
    String upper,
    String? niv,
    String? plate,
    Map<String, double> fieldConf,
  ) {
    const motorLabels = ['MOTOR', 'SERIAL MOTOR', 'No. MOTOR'];
    for (final label in motorLabels) {
      final idx = upper.indexOf(label);
      if (idx < 0) continue;
      final searchArea = rawText.substring(
          idx + label.length, (idx + label.length + 80).clamp(0, rawText.length));
      for (final m in _nivRegex.allMatches(searchArea)) {
        final candidate = m.group(0)!.toUpperCase();
        if (_isValidSerial(candidate, plate) && candidate != niv) {
          fieldConf['serialMotor'] = 0.85;
          return candidate;
        }
      }
    }
    return null;
  }

  static int? _extractSeats(
      String rawText, String upper, Map<String, double> fieldConf) {
    const labels = ['PUESTOS', 'N° PUESTOS', 'No. PUESTOS', 'ASIENTOS'];
    for (final label in labels) {
      final idx = upper.indexOf(label);
      if (idx < 0) continue;
      // Look for digit immediately before or after the label
      final before =
          rawText.substring((idx - 10).clamp(0, idx), idx);
      final after = rawText.substring(
          idx + label.length,
          (idx + label.length + 10).clamp(0, rawText.length));
      for (final area in [after, before]) {
        final m = _seatsRegex.firstMatch(area);
        if (m != null) {
          final n = int.tryParse(m.group(0)!);
          if (n != null && n >= 1 && n <= 4) {
            fieldConf['seats'] = 0.85;
            return n;
          }
        }
      }
    }
    return null;
  }

  static String? _extractOwnerCedula(
      String rawText, String upper, Map<String, double> fieldConf) {
    final m = _cedulaRegex.firstMatch(rawText);
    if (m != null) {
      final raw = m.group(0)!.replaceAll(RegExp(r'[.\s\-]'), '').toUpperCase();
      fieldConf['ownerCedula'] = 0.85;
      return raw;
    }
    return null;
  }

  static String? _extractOwnerName(
    List<TextBlock> blocks,
    String upper,
    Map<String, double> fieldConf,
  ) {
    const markers = [
      'PROPIETARIO', 'TITULAR', 'NOMBRE DEL PROPIETARIO', 'NOMBRES Y APELLIDOS',
    ];
    for (final block in blocks) {
      for (var i = 0; i < block.lines.length; i++) {
        final line = block.lines[i].text.toUpperCase();
        if (markers.any(line.contains)) {
          // Value may be on same line (after colon) or next line
          final afterColon = block.lines[i].text.split(':').skip(1).join(':').trim();
          if (afterColon.isNotEmpty && _isNameCandidate(afterColon)) {
            fieldConf['ownerName'] = 0.80;
            return _capitalizeWords(afterColon.toUpperCase());
          }
          if (i + 1 < block.lines.length) {
            final nextLine = block.lines[i + 1].text.trim();
            if (_isNameCandidate(nextLine)) {
              fieldConf['ownerName'] = 0.78;
              return _capitalizeWords(nextLine.toUpperCase());
            }
          }
        }
      }
    }

    // Fallback: uppercase name-like line that's not a label
    for (final block in blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.length < 5 || text.length > 50) continue;
        if (text.contains(RegExp(r'\d'))) continue;
        final words = text.split(RegExp(r'\s+'));
        if (words.length >= 2 &&
            words.every((w) =>
                w.isNotEmpty &&
                RegExp(r'^[A-ZÁÉÍÓÚÜÑ]+$', caseSensitive: false).hasMatch(w)) &&
            !words.any((w) => _isExcludedWord(w.toUpperCase()))) {
          fieldConf['ownerName'] = 0.60;
          return _capitalizeWords(text.toUpperCase());
        }
      }
    }
    return null;
  }

  static DateTime? _extractIssuedDate(
      String rawText, String upper, Map<String, double> fieldConf) {
    // Prefer date after "EXPEDICION" or "EMISION" label
    const labels = ['EXPEDICION', 'EXPEDICIÓN', 'EMISIÓN', 'EMISION', 'FECHA'];
    for (final label in labels) {
      final idx = upper.indexOf(label);
      if (idx < 0) continue;
      final searchArea = rawText.substring(
          idx, (idx + 60).clamp(0, rawText.length));
      final m = _dateRegex.firstMatch(searchArea);
      if (m != null) {
        final d = _tryParseDate(
          int.tryParse(m.group(1)!),
          int.tryParse(m.group(2)!),
          int.tryParse(m.group(3)!),
        );
        if (d != null) {
          fieldConf['issuedDate'] = 0.85;
          return d;
        }
      }
    }

    // Fallback: first valid date in document
    final m = _dateRegex.firstMatch(rawText);
    if (m != null) {
      final d = _tryParseDate(
        int.tryParse(m.group(1)!),
        int.tryParse(m.group(2)!),
        int.tryParse(m.group(3)!),
      );
      if (d != null) {
        fieldConf['issuedDate'] = 0.60;
        return d;
      }
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Returns true if [raw] looks like a valid serial number and is not the plate.
  static bool _isValidSerial(String raw, String? plate) {
    if (raw.length < 8) return false;
    if (plate != null && raw.replaceAll('-', '') == plate.replaceAll('-', '')) {
      return false;
    }
    // Must contain at least one letter and one digit (not all-digit = year)
    final hasLetter = raw.contains(RegExp(r'[A-Z]', caseSensitive: false));
    final hasDigit = raw.contains(RegExp(r'\d'));
    return hasLetter && hasDigit;
  }

  static bool _isNameCandidate(String text) {
    final upper = text.toUpperCase().trim();
    if (upper.length < 4 || upper.length > 50) return false;
    if (upper.contains(RegExp(r'\d'))) return false;
    if (!RegExp(r'^[A-ZÁÉÍÓÚÜÑ\s\-]+$').hasMatch(upper)) return false;
    final words = upper.split(RegExp(r'\s+'));
    return !words.any((w) => _isExcludedWord(w));
  }

  static bool _isExcludedWord(String word) {
    return _nameExclusions.contains(_stripAccents(word));
  }

  static DateTime? _tryParseDate(int? day, int? month, int? year) {
    if (day == null || month == null || year == null) return null;
    if (year < 1950 || year > DateTime.now().year + 1) return null;
    if (month < 1 || month > 12) return null;
    if (day < 1 || day > 31) return null;
    try {
      return DateTime(year, month, day);
    } on Exception {
      return null;
    }
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
