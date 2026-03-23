import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';

class CrossValidationResult {
  final bool nameMatch;
  final bool cedulaMatch;
  final bool overallMatch;
  final String? mismatchDetails;
  final bool skipped; // true when carnet has no owner data to compare

  const CrossValidationResult({
    required this.nameMatch,
    required this.cedulaMatch,
    required this.overallMatch,
    this.mismatchDetails,
    this.skipped = false,
  });

  factory CrossValidationResult.skipped() => const CrossValidationResult(
        nameMatch: true,
        cedulaMatch: true,
        overallMatch: true,
        skipped: true,
      );
}

class CrossValidator {
  CrossValidator._();

  static CrossValidationResult validate(
    CedulaParseResult cedula,
    CarnetParseResult carnet,
  ) {
    // If carnet has no owner data, skip validation
    if (carnet.ownerName == null && carnet.ownerCedula == null) {
      return CrossValidationResult.skipped();
    }

    bool nameMatch = true;
    bool cedulaMatch = true;
    final mismatches = <String>[];

    // --- CI comparison ---
    if (carnet.ownerCedula != null && cedula.idNumber != null) {
      final carnetCi = _normalizeCi(carnet.ownerCedula!);
      final cedulaCi = _normalizeCi('${cedula.idType ?? "V"}${cedula.idNumber!}');
      cedulaMatch = carnetCi == cedulaCi;
      if (!cedulaMatch) {
        mismatches.add(
          'CI: cédula (${cedula.idType}${cedula.idNumber}) ≠ carnet ($carnetCi)',
        );
      }
    }

    // --- Name comparison ---
    if (carnet.ownerName != null) {
      final cedulaFullName =
          '${cedula.firstName ?? ""} ${cedula.lastName ?? ""}'.trim();
      if (cedulaFullName.isNotEmpty) {
        nameMatch = _fuzzyNameMatch(cedulaFullName, carnet.ownerName!);
        if (!nameMatch) {
          mismatches.add(
            'Nombre: "$cedulaFullName" ≠ "${carnet.ownerName}"',
          );
        }
      }
    }

    return CrossValidationResult(
      nameMatch: nameMatch,
      cedulaMatch: cedulaMatch,
      overallMatch: nameMatch && cedulaMatch,
      mismatchDetails: mismatches.isEmpty ? null : mismatches.join('; '),
    );
  }

  /// Normalizes a CI string: strip prefix punctuation, uppercase, no spaces.
  static String _normalizeCi(String raw) {
    return raw.replaceAll(RegExp(r'[.\s\-]'), '').toUpperCase();
  }

  /// Fuzzy name match: Levenshtein distance ≤ 2, case/accent insensitive.
  static bool _fuzzyNameMatch(String a, String b) {
    final na = _normalizeText(a);
    final nb = _normalizeText(b);
    if (na == nb) return true;
    // Also try matching substrings (partial name on carnet)
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
