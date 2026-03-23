import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CarnetParseResult {
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? serialMotor;
  final String? serialCarroceria;
  final String? vehicleUse; // 'particular' | 'cargo'
  final String? ownerName;
  final String? ownerCedula;
  final double confidence;
  final Map<String, double> fieldConfidences;

  const CarnetParseResult({
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.serialMotor,
    this.serialCarroceria,
    this.vehicleUse,
    this.ownerName,
    this.ownerCedula,
    required this.confidence,
    this.fieldConfidences = const {},
  });

  factory CarnetParseResult.empty() => const CarnetParseResult(confidence: 0.0);
}

class CarnetParser {
  CarnetParser._();

  // Venezuelan: ABC-123-DE (letters-digits-letters)
  static final _plateRegex = RegExp(
    r'\b([A-Z]{2,3})[\s\-]?(\d{2,3})[\s\-]?([A-Z]{2,3})\b',
    caseSensitive: false,
  );
  // Colombian: ABC 123 (3 letters + 3 digits, no trailing letters)
  static final _plateRegexCO = RegExp(
    r'\b([A-Z]{3})[\s\-]?(\d{3})\b(?![\s\-]?[A-Z])',
    caseSensitive: false,
  );
  static final _yearRegex = RegExp(r'\b(19[5-9]\d|20[0-2]\d)\b');
  static final _serialRegex = RegExp(r'\b([A-Z0-9]{8,20})\b', caseSensitive: false);
  static final _cedulaInCarnetRegex = RegExp(
    r'[VvEe][\s.\-]?(\d{6,9})',
    caseSensitive: false,
  );

  static const _knownBrands = [
    'BERA', 'EMPIRE', 'HONDA', 'YAMAHA', 'SUZUKI', 'KAWASAKI', 'BAJAJ',
    'ITALIKA', 'DAYUN', 'KYMCO', 'ROOCAT', 'TVS', 'HERO', 'LIFAN',
    'HAOJUE', 'SHINERAY', 'STORM', 'AKT', 'EUROMOT', 'UM',
  ];

  static const _spanishColors = {
    'ROJO': 'Rojo', 'AZUL': 'Azul', 'NEGRO': 'Negro', 'BLANCO': 'Blanco',
    'GRIS': 'Gris', 'PLATA': 'Plata', 'PLATEADO': 'Plata',
    'VERDE': 'Verde', 'AMARILLO': 'Amarillo', 'NARANJA': 'Naranja',
    'MARRON': 'Marrón', 'CAFE': 'Café', 'MORADO': 'Morado',
    'VIOLETA': 'Violeta', 'ROSA': 'Rosa', 'BEIGE': 'Beige',
  };

  static CarnetParseResult parse(String rawText, List<TextBlock> blocks) {
    final upper = rawText.toUpperCase();
    final fieldConf = <String, double>{};

    // --- Plate ---
    String? plate;
    final plateMatch = _plateRegex.firstMatch(rawText);
    if (plateMatch != null) {
      // Venezuelan format: ABC-123-DE
      plate = '${plateMatch.group(1)!.toUpperCase()}-'
          '${plateMatch.group(2)}-'
          '${plateMatch.group(3)!.toUpperCase()}';
      fieldConf['plate'] = 0.95;
    } else {
      // Colombian format: ABC-123
      final plateMatchCO = _plateRegexCO.firstMatch(rawText);
      if (plateMatchCO != null) {
        plate = '${plateMatchCO.group(1)!.toUpperCase()}-'
            '${plateMatchCO.group(2)}';
        fieldConf['plate'] = 0.9;
      }
    }

    // --- Year ---
    int? year;
    final yearMatches = _yearRegex.allMatches(rawText);
    for (final m in yearMatches) {
      final y = int.tryParse(m.group(0)!);
      if (y != null && y >= 1960 && y <= DateTime.now().year + 1) {
        year = y;
        fieldConf['year'] = 0.9;
        break;
      }
    }

    // --- Brand ---
    String? brand;
    for (final b in _knownBrands) {
      if (upper.contains(b)) {
        brand = b[0] + b.substring(1).toLowerCase();
        fieldConf['brand'] = 0.9;
        break;
      }
    }

    // --- Color ---
    String? color;
    for (final entry in _spanishColors.entries) {
      if (upper.contains(entry.key)) {
        color = entry.value;
        fieldConf['color'] = 0.85;
        break;
      }
    }

    // --- Vehicle use ---
    String? vehicleUse;
    if (upper.contains('PARTICULAR')) {
      vehicleUse = 'particular';
      fieldConf['vehicleUse'] = 0.9;
    } else if (upper.contains('CARGA') || upper.contains('COMERCIAL')) {
      vehicleUse = 'cargo';
      fieldConf['vehicleUse'] = 0.9;
    }

    // --- Serial numbers: look for long alphanumeric strings (8-20 chars) ---
    String? serialMotor;
    String? serialCarroceria;
    final serialMatches = _serialRegex.allMatches(rawText).toList();
    // Filter out year, plate-like strings, and other noise
    final serials = serialMatches
        .map((m) => m.group(0)!)
        .where((s) =>
            s.length >= 8 &&
            !_yearRegex.hasMatch(s) &&
            !_plateRegex.hasMatch(s) &&
            s != plate)
        .toList();

    // Heuristic: use first 2 long serials as motor/carroceria
    if (serials.isNotEmpty) {
      // Look for MOTOR / CARROCERIA labels nearby in text
      final motorIdx = upper.indexOf('MOTOR');
      final carrIdx = upper.indexOf('CARROCER');
      if (motorIdx >= 0 && carrIdx >= 0) {
        // Find first serial after "MOTOR" keyword
        for (final s in serials) {
          final idx = rawText.toUpperCase().indexOf(s.toUpperCase());
          if (serialMotor == null && idx > motorIdx) {
            serialMotor = s;
            fieldConf['serialMotor'] = 0.8;
          } else if (serialCarroceria == null && idx > carrIdx) {
            serialCarroceria = s;
            fieldConf['serialCarroceria'] = 0.8;
          }
        }
      } else if (serials.length >= 2) {
        serialMotor = serials[0];
        serialCarroceria = serials[1];
        fieldConf['serialMotor'] = 0.6;
        fieldConf['serialCarroceria'] = 0.6;
      } else if (serials.length == 1) {
        serialMotor = serials[0];
        fieldConf['serialMotor'] = 0.6;
      }
    }

    // --- Owner cedula (for cross-validation) ---
    String? ownerCedula;
    final cedulaMatch = _cedulaInCarnetRegex.firstMatch(rawText);
    if (cedulaMatch != null) {
      ownerCedula = cedulaMatch.group(0)!.replaceAll(RegExp(r'[.\s\-]'), '').toUpperCase();
      fieldConf['ownerCedula'] = 0.85;
    }

    // --- Owner name (look for uppercase name-like lines) ---
    String? ownerName;
    final nameLine = _extractOwnerName(blocks, upper);
    if (nameLine != null) {
      ownerName = nameLine;
      fieldConf['ownerName'] = 0.7;
    }

    // --- Model: anything that is not brand, plate, serial, year, color ---
    // Rough heuristic: short alphanumeric string following brand
    String? model;
    if (brand != null) {
      final brandIdx = upper.indexOf(brand.toUpperCase());
      if (brandIdx >= 0 && brandIdx + brand.length + 50 < upper.length) {
        final after = upper.substring(brandIdx + brand.length, brandIdx + brand.length + 50);
        final modelMatch = RegExp(r'\b([A-Z0-9]{2,10})\b').firstMatch(after);
        if (modelMatch != null) {
          model = modelMatch.group(0);
          fieldConf['model'] = 0.6;
        }
      }
    }

    final scores = fieldConf.values;
    final overall =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    return CarnetParseResult(
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      color: color,
      serialMotor: serialMotor,
      serialCarroceria: serialCarroceria,
      vehicleUse: vehicleUse,
      ownerName: ownerName,
      ownerCedula: ownerCedula,
      confidence: overall,
      fieldConfidences: fieldConf,
    );
  }

  static String? _extractOwnerName(List<TextBlock> blocks, String upper) {
    // Look for lines that follow "PROPIETARIO" or "TITULAR" label
    const markers = ['PROPIETARIO', 'TITULAR', 'NOMBRE'];
    for (final block in blocks) {
      for (var i = 0; i < block.lines.length - 1; i++) {
        final line = block.lines[i].text.toUpperCase();
        if (markers.any(line.contains)) {
          final nextLine = block.lines[i + 1].text.trim();
          if (nextLine.length > 3 &&
              !nextLine.contains(RegExp(r'\d')) &&
              RegExp(r'^[A-ZÁÉÍÓÚÜÑ\s]+$', caseSensitive: false).hasMatch(nextLine)) {
            return nextLine;
          }
        }
      }
    }
    return null;
  }
}
