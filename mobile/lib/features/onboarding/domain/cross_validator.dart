import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';

class CrossValidationResult {
  final bool nameMatch;
  final bool cedulaMatch;
  final bool vehicleTypeOk; // true if vehicleType == MOTO PARTICULAR (or unknown)
  final bool overallMatch;
  final String? mismatchDetails;
  final bool skipped; // true when certificado has no owner data to compare

  const CrossValidationResult({
    required this.nameMatch,
    required this.cedulaMatch,
    this.vehicleTypeOk = true,
    required this.overallMatch,
    this.mismatchDetails,
    this.skipped = false,
  });

  factory CrossValidationResult.skipped() => const CrossValidationResult(
        nameMatch: true,
        cedulaMatch: true,
        vehicleTypeOk: true,
        overallMatch: true,
        skipped: true,
      );
}

/// RS-077: Updated to use [CertificadoParseResult] instead of CarnetParseResult.
/// Also validates that the vehicle type is a motorcycle.
class CrossValidator {
  CrossValidator._();

  static CrossValidationResult validate(
    CedulaParseResult cedula,
    CertificadoParseResult certificado,
  ) {
    final mismatches = <String>[];

    // --- Vehicle type check ---
    bool vehicleTypeOk = true;
    if (certificado.vehicleType != null) {
      vehicleTypeOk =
          certificado.vehicleType!.toUpperCase().contains('MOTO');
      if (!vehicleTypeOk) {
        mismatches.add(
          'Tipo de vehículo: "${certificado.vehicleType}" no es una motocicleta',
        );
      }
    }

    // If certificado has no owner data, skip name/cedula comparison
    if (certificado.ownerName == null && certificado.ownerCedula == null) {
      return CrossValidationResult(
        nameMatch: true,
        cedulaMatch: true,
        vehicleTypeOk: vehicleTypeOk,
        overallMatch: vehicleTypeOk,
        mismatchDetails: mismatches.isEmpty ? null : mismatches.join('; '),
        skipped: certificado.ownerName == null && certificado.ownerCedula == null,
      );
    }

    bool nameMatch = true;
    bool cedulaMatch = true;

    // --- CI comparison ---
    if (certificado.ownerCedula != null && cedula.idNumber != null) {
      final certCi = _normalizeCi(certificado.ownerCedula!);
      final cedulaCi = _normalizeCi('${cedula.idType ?? "V"}${cedula.idNumber!}');
      cedulaMatch = certCi == cedulaCi;
      if (!cedulaMatch) {
        mismatches.add(
          'CI: cédula (${cedula.idType}${cedula.idNumber}) ≠ certificado ($certCi)',
        );
      }
    }

    // --- Name comparison ---
    if (certificado.ownerName != null) {
      final cedulaFullName =
          '${cedula.firstName ?? ""} ${cedula.lastName ?? ""}'.trim();
      if (cedulaFullName.isNotEmpty) {
        nameMatch = _fuzzyNameMatch(cedulaFullName, certificado.ownerName!);
        if (!nameMatch) {
          mismatches.add(
            'Nombre: "$cedulaFullName" ≠ "${certificado.ownerName}"',
          );
        }
      }
    }

    return CrossValidationResult(
      nameMatch: nameMatch,
      cedulaMatch: cedulaMatch,
      vehicleTypeOk: vehicleTypeOk,
      overallMatch: nameMatch && cedulaMatch && vehicleTypeOk,
      mismatchDetails: mismatches.isEmpty ? null : mismatches.join('; '),
    );
  }

  static String _normalizeCi(String raw) {
    return raw.replaceAll(RegExp(r'[.\s\-]'), '').toUpperCase();
  }

  static bool _fuzzyNameMatch(String a, String b) {
    final na = _normalizeText(a);
    final nb = _normalizeText(b);
    if (na == nb) return true;
    if (na.contains(nb) || nb.contains(na)) return true;
    return _levenshtein(na, nb) <= 2;
  }

  static String _normalizeText(String s) {
    return s
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static int _levenshtein(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    final dp = List.generate(
      a.length + 1,
      (i) => List.generate(b.length + 1, (j) => i == 0 ? j : (j == 0 ? i : 0)),
    );

    for (var i = 1; i <= a.length; i++) {
      for (var j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        dp[i][j] = [
          dp[i - 1][j] + 1,
          dp[i][j - 1] + 1,
          dp[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    return dp[a.length][b.length];
  }
}
