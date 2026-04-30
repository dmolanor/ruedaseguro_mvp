import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:ruedaseguro/core/data/mock_data.dart';
import 'package:ruedaseguro/features/policy/domain/policy_detail_model.dart';

/// Optional supplementary data for the Cuadro-Póliza Recibo.
///
/// [PolicyDetailModel] only carries the fields persisted in the `policies`
/// table join. These extras — available from the onboarding state or auth —
/// are passed in when available and fall back to '—' when not.
class PolicyPdfExtras {
  final String? riderPhone;
  final String? riderEmail;
  final String? estado;
  final String? municipio;
  final String? serialNiv;
  final String? vehicleType;
  final String? paymentMethod;
  final DateTime? consentTimestamp;

  const PolicyPdfExtras({
    this.riderPhone,
    this.riderEmail,
    this.estado,
    this.municipio,
    this.serialNiv,
    this.vehicleType,
    this.paymentMethod,
    this.consentTimestamp,
  });
}

class PolicyPdfService {
  PolicyPdfService._();

  // ─── Carrier metadata lookup ─────────────────────────────────────
  // Keyed by carrier name as stored in the `carriers` table.
  // rif: Registro de Información Fiscal
  // sudeaseg: SUDEASEG registration number
  // code: SUDEASEG-approved document code for the Condiciones Generales
  static const _carrierMeta =
      <String, ({String rif, String sudeaseg, String code})>{
        'Seguros Caracas': (
          rif: 'J-00038923-3',
          sudeaseg: '13',
          code: 'CSUAI005-0-V1.0',
        ),
        'Seguros Pirámide': (
          rif: 'J-PENDIENTE',
          sudeaseg: 'TBD',
          code: 'RCV-PIR-V1.0',
        ),
        'Seguros Mercantil': (
          rif: 'J-PENDIENTE',
          sudeaseg: 'TBD',
          code: 'RCV-MER-V1.0',
        ),
      };

  // ─── Color palette ───────────────────────────────────────────────
  static const _primary = PdfColor.fromInt(0xFF0A1B2A);
  static const _accent = PdfColor.fromInt(0xFFFF6A1A);
  static const _provisional = PdfColor.fromInt(0xFFE65100);
  static const _surface = PdfColor.fromInt(0xFFF5F7FA);
  static const _border = PdfColor.fromInt(0xFFDDE2E9);
  static const _label = PdfColor.fromInt(0xFF8E9BAD);
  static const _divider = PdfColor.fromInt(0xFFCFD8E3);
  static const _green = PdfColor.fromInt(0xFF2E7D32);

  // ─── Public API (unchanged signatures) ───────────────────────────

  /// Generates the Cuadro-Póliza Recibo and opens the system share sheet.
  /// [extras] provides supplementary fields not in [PolicyDetailModel].
  static Future<void> shareProvisionalPdf(
    PolicyDetailModel? policy, {
    PolicyPdfExtras? extras,
  }) async {
    final bytes = await _build(policy, extras: extras);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'RuedaSeguro-${_shortId(policy)}.pdf',
    );
  }

  /// Returns the raw PDF bytes (for upload / cache).
  static Future<Uint8List> generateBytes(
    PolicyDetailModel? policy, {
    PolicyPdfExtras? extras,
  }) => _build(policy, extras: extras);

  // ─── Internal builder ────────────────────────────────────────────

  static Future<Uint8List> _build(
    PolicyDetailModel? policy, {
    PolicyPdfExtras? extras,
  }) async {
    final doc = pw.Document(
      title: 'Cuadro-Póliza RCV — RuedaSeguro',
      author: 'RuedaSeguro',
    );

    // ── Resolve data — real or mock ───────────────────────────────
    final carrierName = policy?.carrierName ?? MockPolicy.carrier;
    final meta = _carrierMeta[carrierName];
    final carrierRif = meta?.rif ?? 'J-PENDIENTE';
    final carrierSudeaseg = meta?.sudeaseg ?? 'TBD';
    final condicionesCode = meta?.code ?? 'RCV-V1.0';

    final isProvisional = policy?.isProvisional ?? false;
    final displayNumber = policy?.displayNumber ?? MockPolicy.number;
    final planName = policy?.planName ?? MockPolicy.type;
    final tier = policy?.tier ?? MockPolicy.tier;

    final riderName = policy?.riderFullName ?? MockRider.fullName;
    final riderId =
        '${policy?.riderIdType ?? MockRider.idType}-${policy?.riderIdNumber ?? MockRider.idNumber}';
    final riderPhone = extras?.riderPhone ?? '—';
    final riderEmail = extras?.riderEmail ?? '—';

    final vehicleStr =
        '${policy?.vehicleBrand ?? MockVehicle.brand} ${policy?.vehicleModel ?? MockVehicle.model} ${policy?.vehicleYear ?? MockVehicle.year}';
    final plate = policy?.vehiclePlate ?? MockVehicle.plate;
    final vehicleColor = policy?.vehicleColor ?? '';
    final serialNiv = extras?.serialNiv ?? '—';
    final vehicleType = extras?.vehicleType ?? 'Moto Particular';

    final estado = extras?.estado ?? '—';
    final municipio = extras?.municipio ?? '—';

    final startDate = policy?.formattedStartDate ?? MockPolicy.issueDate;
    final endDate = policy?.formattedEndDate ?? MockPolicy.expiryDate;
    final premiumUsd = (policy?.premiumUsd ?? MockPolicy.premiumUsd)
        .toStringAsFixed(2);
    final premiumVes = policy != null
        ? NumberFormat('#,##0.00', 'es').format(policy.premiumVes)
        : '—';
    final exchangeRate = policy != null
        ? NumberFormat('#,##0.00', 'es').format(policy.exchangeRate)
        : '—';
    final paymentMethod = _humanPayment(
      extras?.paymentMethod ?? 'pago_movil_p2p',
    );

    final consentTs = extras?.consentTimestamp ?? DateTime.now().toUtc();
    final consentStr = DateFormat(
      "dd/MM/yyyy 'a las' HH:mm 'UTC'",
      'es',
    ).format(consentTs);
    final hashStr = _computeHash(policy);
    final generatedAt = DateFormat(
      'dd/MM/yyyy HH:mm',
      'es',
    ).format(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(40, 36, 40, 36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // ── Page header ──────────────────────────────────────
            _pageHeader(
              carrierName: carrierName,
              carrierRif: carrierRif,
              carrierSudeaseg: carrierSudeaseg,
              isProvisional: isProvisional,
            ),
            pw.SizedBox(height: 10),

            // ── Document title band ──────────────────────────────
            _titleBand(displayNumber),
            pw.SizedBox(height: 12),

            // ── Two-column: Empresa de Seguros | Tomador ─────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _infoBox(
                    title: 'EMPRESA DE SEGUROS',
                    rows: [
                      ('Nombre', carrierName),
                      ('RIF', carrierRif),
                      ('SUDEASEG Reg.', 'N° $carrierSudeaseg'),
                      ('Intermediario', 'RuedaSeguro C.A.'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _infoBox(
                    title: 'TOMADOR / ASEGURADO',
                    rows: [
                      ('Nombre', riderName),
                      ('Cédula', riderId),
                      ('Teléfono', riderPhone),
                      ('Correo', riderEmail),
                      ('Domicilio', '$municipio, $estado'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Vehicle ──────────────────────────────────────────
            _infoBox(
              title: 'VEHÍCULO ASEGURADO',
              rows: [
                ('Marca / Modelo / Año', vehicleStr),
                ('Placa', plate),
                ('Color', vehicleColor.isEmpty ? '—' : vehicleColor),
                ('Serial NIV', serialNiv),
                ('Tipo', vehicleType),
              ],
              horizontal: true,
            ),
            pw.SizedBox(height: 10),

            // ── Vigencia + Prima ─────────────────────────────────
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Expanded(
                  child: _infoBox(
                    title: 'VIGENCIA DE COBERTURA',
                    rows: [
                      ('Inicio', startDate),
                      ('Vencimiento', endDate),
                      ('Duración', '1 año'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: _infoBox(
                    title: 'PRIMA',
                    rows: [
                      ('Monto USD', '\$$premiumUsd'),
                      ('Equivalente Bs.', 'Bs. $premiumVes'),
                      ('Tasa BCV', 'Bs. $exchangeRate / USD'),
                      ('Forma de pago', paymentMethod),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 10),

            // ── Coverages ────────────────────────────────────────
            _coveragesBox(tier, planName),
            pw.SizedBox(height: 10),

            // ── Condiciones Generales reference ──────────────────
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _border),
                borderRadius: pw.BorderRadius.circular(5),
              ),
              child: pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(
                      text: 'CONDICIONES GENERALES: ',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: _primary,
                      ),
                    ),
                    pw.TextSpan(
                      text:
                          'Esta póliza se rige por las Condiciones Generales $condicionesCode, '
                          'aprobadas por la Superintendencia de la Actividad Aseguradora (SUDEASEG) '
                          'mediante Providencia Nº 00866 del 20 de octubre de 2003, '
                          'publicada en Gaceta Oficial Nº 37.829 del 01/12/2003.',
                      style: const pw.TextStyle(fontSize: 8, color: _label),
                    ),
                  ],
                ),
              ),
            ),
            pw.SizedBox(height: 10),

            // ── Acceptance block ─────────────────────────────────
            _acceptanceBlock(
              riderName: riderName,
              riderId: riderId,
              consentStr: consentStr,
              hashStr: hashStr,
            ),

            pw.Spacer(),

            // ── Signature line ───────────────────────────────────
            _signatureLine(carrierName: carrierName, riderName: riderName),
            pw.SizedBox(height: 8),

            // ── Footer ───────────────────────────────────────────
            pw.Divider(color: _divider, thickness: 0.5),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'SHA-256: $hashStr',
                  style: const pw.TextStyle(fontSize: 6.5, color: _label),
                ),
                pw.Text(
                  'Generado: $generatedAt  |  RuedaSeguro C.A.',
                  style: const pw.TextStyle(fontSize: 6.5, color: _label),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return doc.save();
  }

  // ─── Widget builders ─────────────────────────────────────────────

  static pw.Widget _pageHeader({
    required String carrierName,
    required String carrierRif,
    required String carrierSudeaseg,
    required bool isProvisional,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Left: carrier identity
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              carrierName.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 13,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
            pw.Text(
              'RIF: $carrierRif  |  SUDEASEG Reg. Nº $carrierSudeaseg',
              style: const pw.TextStyle(fontSize: 7.5, color: _label),
            ),
            pw.Text(
              'Distribuido por RuedaSeguro C.A.',
              style: const pw.TextStyle(fontSize: 7.5, color: _label),
            ),
          ],
        ),
        // Right: status badge + RCV label
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: pw.BoxDecoration(
                color: isProvisional ? _provisional : _primary,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                isProvisional ? 'PÓLIZA PROVISIONAL' : 'PÓLIZA ACTIVA',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Responsabilidad Civil Vehicular (RCV)',
              style: const pw.TextStyle(fontSize: 7.5, color: _label),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _titleBand(String policyNumber) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: _primary,
        borderRadius: pw.BorderRadius.circular(5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'CUADRO-PÓLIZA RECIBO',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            'N° $policyNumber',
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _infoBox({
    required String title,
    required List<(String, String)> rows,
    bool horizontal = false,
  }) {
    final content = horizontal
        ? pw.Wrap(
            spacing: 24,
            runSpacing: 4,
            children: rows.map((r) => _labelValue(r.$1, r.$2)).toList(),
          )
        : pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: rows.map((r) => _labelValue(r.$1, r.$2)).toList(),
          );

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 6),
          content,
        ],
      ),
    );
  }

  static pw.Widget _labelValue(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: const pw.TextStyle(fontSize: 7.5, color: _label),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _coveragesBox(String tier, String planName) {
    final rows = _coveragesForTier(tier);
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: _surface,
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _border),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'COBERTURAS Y SUMAS ASEGURADAS',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                'Plan: ${planName.toUpperCase()}',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _accent,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          ...rows.map(
            (r) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Row(
                children: [
                  pw.Text(
                    '✓  ',
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: _green,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      r.$1,
                      style: const pw.TextStyle(fontSize: 7.5, color: _primary),
                    ),
                  ),
                  pw.Text(
                    r.$2,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _acceptanceBlock({
    required String riderName,
    required String riderId,
    required String consentStr,
    required String hashStr,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF0F4F8),
        borderRadius: pw.BorderRadius.circular(5),
        border: pw.Border.all(color: _divider),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ACEPTACIÓN DIGITAL DEL TOMADOR',
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _primary,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            '$riderName, Cédula $riderId, declara haber leído y acepta los términos y '
            'condiciones de la presente Póliza de Responsabilidad Civil Vehicular, '
            'incluyendo sus Condiciones Generales.',
            style: const pw.TextStyle(fontSize: 7.5, color: _primary),
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'Fecha de aceptación: ',
                style: const pw.TextStyle(fontSize: 7.5, color: _label),
              ),
              pw.Text(
                consentStr,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureLine({
    required String carrierName,
    required String riderName,
  }) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 28,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _primary, width: 0.8),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Por El Asegurador',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                '$carrierName / RuedaSeguro C.A.',
                style: const pw.TextStyle(fontSize: 7, color: _label),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                height: 28,
                decoration: const pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: _primary, width: 0.8),
                  ),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Por El Tomador',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _primary,
                ),
              ),
              pw.Text(
                riderName,
                style: const pw.TextStyle(fontSize: 7, color: _label),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Coverage table by tier ───────────────────────────────────────
  // Returns (cobertura_label, suma_asegurada_label) tuples.
  static List<(String, String)> _coveragesForTier(String tier) {
    final rows = <(String, String)>[
      ('RC Daños Materiales a Terceros', 'Hasta el límite legal'),
      ('RC Lesiones Corporales a Terceros', 'Hasta el límite legal'),
      ('Defensa Legal y Penal', 'Incluida'),
    ];
    if (tier == 'plus' || tier == 'ampliada') {
      rows.add(('Asistencia en Grúa 24/7', 'Incluida'));
      rows.add(('Asistencia Vial en Carretera', 'Incluida'));
    }
    if (tier == 'ampliada') {
      rows.add(('Gastos Médicos para el Conductor', 'Hasta \$2,000 USD'));
      rows.add(('Muerte Accidental del Conductor', 'Incluida'));
    }
    return rows;
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static String _humanPayment(String method) {
    return switch (method) {
      'pago_movil_p2p' => 'Pago Móvil P2P',
      'bank_transfer' => 'Transferencia Bancaria',
      'debito_inmediato' => 'Débito Inmediato',
      _ => 'Pago Electrónico',
    };
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
