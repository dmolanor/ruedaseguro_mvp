import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';

class PolicyPdfService {
  PolicyPdfService._();

  // ─── Public entry point ──────────────────────────────────────────

  /// Generates the provisional PDF and opens the system share/print sheet.
  /// If [policy] is null, generates a demo PDF using mock data.
  static Future<void> shareProvisionalPdf(PolicyDetailModel? policy) async {
    final bytes = await _build(policy);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'RuedaSeguro-${_shortId(policy)}.pdf',
    );
  }

  /// Returns the raw PDF bytes (for upload / cache).
  static Future<Uint8List> generateBytes(PolicyDetailModel? policy) =>
      _build(policy);

  // ─── Internal builder ────────────────────────────────────────────

  static Future<Uint8List> _build(PolicyDetailModel? policy) async {
    final doc = pw.Document(
      title: 'Póliza RuedaSeguro',
      author: 'RuedaSeguro',
    );

    // Resolve data — real or mock
    final planName = policy?.planName ?? MockPolicy.type;
    final isProvisional = policy?.isProvisional ?? false;
    final displayNumber = policy?.displayNumber ?? MockPolicy.number;
    final riderName = policy?.riderFullName ?? MockRider.fullName;
    final riderId =
        '${policy?.riderIdType ?? MockRider.idType}-${policy?.riderIdNumber ?? MockRider.idNumber}';
    final vehicleStr = policy != null
        ? '${policy.vehicleBrand} ${policy.vehicleModel} ${policy.vehicleYear}'
        : '${MockVehicle.brand} ${MockVehicle.model} ${MockVehicle.year}';
    final plate = policy?.vehiclePlate ?? MockVehicle.plate;
    final startDate = policy?.formattedStartDate ?? MockPolicy.issueDate;
    final endDate = policy?.formattedEndDate ?? MockPolicy.expiryDate;
    final premiumUsd =
        (policy?.premiumUsd ?? MockPolicy.premiumUsd).toStringAsFixed(2);
    final carrierName = policy?.carrierName ?? MockPolicy.carrier;
    final hashStr = _computeHash(policy);
    final generatedAt =
        DateFormat('dd/MM/yyyy HH:mm', 'es').format(DateTime.now());

    // Color palette
    const primaryColor = PdfColor.fromInt(0xFF1A237E);
    const accentColor = PdfColor.fromInt(0xFFFF6D00);
    const provisionalColor = PdfColor.fromInt(0xFFE65100);
    const surfaceColor = PdfColor.fromInt(0xFFF5F5F5);
    const borderColor = PdfColor.fromInt(0xFFE0E0E0);
    const textSecondary = PdfColor.fromInt(0xFF757575);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'RuedaSeguro',
                      style: pw.TextStyle(
                        fontSize: 22,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.Text(
                      'Responsabilidad Civil Vehicular',
                      style: pw.TextStyle(
                          fontSize: 10, color: textSecondary),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: isProvisional ? provisionalColor : primaryColor,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    isProvisional ? 'PÓLIZA PROVISIONAL' : 'PÓLIZA ACTIVA',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 4),
            pw.Divider(color: primaryColor, thickness: 2),
            pw.SizedBox(height: 16),

            // ── Provisional notice ───────────────────────────────
            if (isProvisional) ...[
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFFFF3E0),
                  border: pw.Border.all(
                    color: provisionalColor,
                    width: 1,
                  ),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'Esta es una póliza PROVISIONAL emitida por RuedaSeguro '
                  'en lo que el sistema emisor de la aseguradora confirma la cobertura. '
                  'Tiene validez legal completa. Recibirá la póliza definitiva por correo.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    color: provisionalColor,
                  ),
                ),
              ),
              pw.SizedBox(height: 16),
            ],

            // ── Policy number block ──────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: surfaceColor,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('N° DE PÓLIZA',
                          style: pw.TextStyle(
                              fontSize: 8, color: textSecondary)),
                      pw.SizedBox(height: 4),
                      pw.Text(displayNumber,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          )),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('PLAN',
                          style: pw.TextStyle(
                              fontSize: 8, color: textSecondary)),
                      pw.SizedBox(height: 4),
                      pw.Text(planName.toUpperCase(),
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: accentColor,
                          )),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 20),

            // ── Two column: Rider + Vehicle ──────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Rider column
                pw.Expanded(
                  child: _section(
                    title: 'ASEGURADO',
                    rows: [
                      ('Nombre', riderName),
                      ('Cédula', riderId),
                    ],
                    primaryColor: primaryColor,
                    textSecondary: textSecondary,
                  ),
                ),
                pw.SizedBox(width: 16),
                // Vehicle column
                pw.Expanded(
                  child: _section(
                    title: 'VEHÍCULO',
                    rows: [
                      ('Marca / Modelo', vehicleStr),
                      ('Placa', plate),
                    ],
                    primaryColor: primaryColor,
                    textSecondary: textSecondary,
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // ── Validity + carrier ───────────────────────────────
            _section(
              title: 'VIGENCIA Y COBERTURA',
              rows: [
                ('Aseguradora', carrierName),
                ('Desde', startDate),
                ('Hasta', endDate),
                ('Prima anual', '\$ $premiumUsd USD'),
              ],
              primaryColor: primaryColor,
              textSecondary: textSecondary,
            ),

            pw.SizedBox(height: 16),

            // ── Coverages ────────────────────────────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: surfaceColor,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('COBERTURAS INCLUIDAS',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      )),
                  pw.SizedBox(height: 8),
                  ..._coveragesForTier(policy?.tier ?? MockPolicy.tier)
                      .map((c) => pw.Padding(
                            padding: const pw.EdgeInsets.only(bottom: 4),
                            child: pw.Row(children: [
                              pw.Text('✓ ',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    color: const PdfColor.fromInt(0xFF2E7D32),
                                    fontWeight: pw.FontWeight.bold,
                                  )),
                              pw.Text(c,
                                  style: pw.TextStyle(
                                      fontSize: 9)),
                            ]),
                          )),
                ],
              ),
            ),

            pw.Spacer(),

            // ── Footer: hash + generation date ───────────────────
            pw.Divider(color: borderColor),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('SHA-256: $hashStr',
                    style: pw.TextStyle(
                        fontSize: 7, color: textSecondary)),
                pw.Text('Generado: $generatedAt',
                    style: pw.TextStyle(
                        fontSize: 7, color: textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static pw.Widget _section({
    required String title,
    required List<(String, String)> rows,
    required PdfColor primaryColor,
    required PdfColor textSecondary,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF5F5F5),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE0E0E0)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              )),
          pw.SizedBox(height: 8),
          ...rows.map((r) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(r.$1,
                        style: pw.TextStyle(
                            fontSize: 8, color: textSecondary)),
                    pw.Text(r.$2,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        )),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  static List<String> _coveragesForTier(String tier) {
    final base = [
      'Responsabilidad Civil Vehicular (RCV) — SUDEASEG obligatorio',
      'Daños materiales a terceros',
      'Lesiones corporales a terceros',
      'Defensa legal y penal',
    ];
    if (tier == 'plus' || tier == 'ampliada') {
      base.add('Asistencia en grúa 24/7');
      base.add('Asistencia vial en carretera');
    }
    if (tier == 'ampliada') {
      base.add('Gastos médicos para el conductor — hasta \$2,000 USD');
      base.add('Muerte accidental del conductor');
    }
    return base;
  }

  static String _shortId(PolicyDetailModel? policy) {
    if (policy == null) return 'DEMO';
    return policy.displayNumber.replaceAll(' ', '-');
  }

  static String _computeHash(PolicyDetailModel? policy) {
    if (policy == null) return MockPolicy.sha256Hash;
    final input = '${policy.id}|${policy.startDate}|${policy.endDate}';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes).toString();
    return '${digest.substring(0, 12)}...${digest.substring(digest.length - 12)}';
  }
}
