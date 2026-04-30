import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';

/// Holds all data collected during the onboarding flow.
///
/// Sprint 4A (RS-078): Simplified flow — 2 document scans only.
/// - Removed: licenciaOcr, licenciaImage, licenciaNumber, licenciaCategories,
///   licenciaExpiry, bloodType.
/// - Renamed: carnetOcr → certificadoOcr, carnetImage → certificadoImage.
/// - Added: vehicleType, vehicleBodyType, serialNiv, seats, idIssuedDate,
///   idExpiryDate, latitude, longitude, addressFromGps.
///
/// Sprint 4B (RS-090): Plan-first + conductor habitual flow.
/// - Added: selectedPlan, premiumUsd (plan selection before documents).
/// - Replaced: isLegalRepresentative → isHabitualDriver + ownerCedula* fields.
class OnboardingData {
  // Step 1 — Cédula
  final CedulaParseResult? cedulaOcr;
  final File? cedulaImage;

  // Confirmed identity fields (user may edit OCR results)
  final String? idType; // 'V', 'E', 'CC'
  final String? idNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final DateTime? idIssuedDate; // fecha de expedición cédula
  final DateTime? idExpiryDate; // fecha de vencimiento cédula
  final String? nationality;
  final String? sex;

  // Emergency contact (single, temporary — RS-088 adds multi-contact table)
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  // Step 2 — Certificado de Circulación (replaces licencia + carnet)
  final CertificadoParseResult? certificadoOcr;
  final File? certificadoImage;

  // Confirmed vehicle fields
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? vehicleType; // e.g. 'MOTO PARTICULAR'
  final String? vehicleBodyType; // e.g. 'DEPORTIVA', 'SCOOTER'
  final String? vehicleUse; // 'particular' | 'cargo'
  final String? serialNiv; // Serial NIV (from certificado)
  final String? serialMotor;
  final String? serialCarroceria; // kept for backward compat; prefer serialNiv
  final int? seats;

  // Cross-validation result (cedula ↔ certificado)
  final CrossValidationResult? crossValidation;

  // Ownership: conductor habitual flow (RS-090)
  // When isHabitualDriver=true, owner fields must be populated before emission.
  // RCV covers the owner; accident coverage covers the rider.
  final bool isHabitualDriver;
  final CedulaParseResult? ownerCedulaOcr;
  final File? ownerCedulaImage;
  final String? ownerIdType;
  final String? ownerIdNumber;
  final String? ownerFirstName;
  final String? ownerLastName;

  // Optional vehicle extras (not extracted from certificado, user-editable)
  final String? color;
  final File? vehiclePhoto;

  // Step 0 — Plan selection (RS-090, must be chosen before document scan)
  final String?
  selectedPlan; // 'rcv_basico' | 'rcv_accidentes' | 'rcv_ampliada'
  final double? premiumUsd;

  // Step 3 — Address (RS-084/085)
  final String? urbanizacion;
  final String? ciudad; // city (kept for compatibility + direct entry)
  final String? municipio;
  final String? estado;
  final String? codigoPostal;
  final String? email; // optional — for post-emission document delivery
  final double? latitude;
  final double? longitude;
  final bool addressFromGps;

  // Step 4 — Consent
  final bool consentRcv;
  final bool consentVeracidad;
  final bool consentAntifraude;
  final bool consentPrivacidad;
  final DateTime? consentTimestamp;

  const OnboardingData({
    this.cedulaOcr,
    this.cedulaImage,
    this.idType,
    this.idNumber,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.idIssuedDate,
    this.idExpiryDate,
    this.nationality,
    this.sex,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.certificadoOcr,
    this.certificadoImage,
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.vehicleType,
    this.vehicleBodyType,
    this.vehicleUse,
    this.serialNiv,
    this.serialMotor,
    this.serialCarroceria,
    this.seats,
    this.crossValidation,
    this.isHabitualDriver = false,
    this.ownerCedulaOcr,
    this.ownerCedulaImage,
    this.ownerIdType,
    this.ownerIdNumber,
    this.ownerFirstName,
    this.ownerLastName,
    this.color,
    this.vehiclePhoto,
    this.selectedPlan,
    this.premiumUsd,
    this.urbanizacion,
    this.ciudad,
    this.municipio,
    this.estado,
    this.codigoPostal,
    this.email,
    this.latitude,
    this.longitude,
    this.addressFromGps = false,
    this.consentRcv = false,
    this.consentVeracidad = false,
    this.consentAntifraude = false,
    this.consentPrivacidad = false,
    this.consentTimestamp,
  });

  bool get allConsentsGiven =>
      consentRcv && consentVeracidad && consentAntifraude && consentPrivacidad;

  bool get isMotorcycle =>
      vehicleType == null || vehicleType!.toUpperCase().contains('MOTO');

  OnboardingData copyWith({
    CedulaParseResult? cedulaOcr,
    File? cedulaImage,
    String? idType,
    String? idNumber,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    DateTime? idIssuedDate,
    DateTime? idExpiryDate,
    String? nationality,
    String? sex,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    CertificadoParseResult? certificadoOcr,
    File? certificadoImage,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? vehicleType,
    String? vehicleBodyType,
    String? vehicleUse,
    String? serialNiv,
    String? serialMotor,
    String? serialCarroceria,
    int? seats,
    CrossValidationResult? crossValidation,
    bool? isHabitualDriver,
    CedulaParseResult? ownerCedulaOcr,
    File? ownerCedulaImage,
    String? ownerIdType,
    String? ownerIdNumber,
    String? ownerFirstName,
    String? ownerLastName,
    String? color,
    File? vehiclePhoto,
    String? selectedPlan,
    double? premiumUsd,
    String? urbanizacion,
    String? ciudad,
    String? municipio,
    String? estado,
    String? codigoPostal,
    String? email,
    double? latitude,
    double? longitude,
    bool? addressFromGps,
    bool? consentRcv,
    bool? consentVeracidad,
    bool? consentAntifraude,
    bool? consentPrivacidad,
    DateTime? consentTimestamp,
  }) {
    return OnboardingData(
      cedulaOcr: cedulaOcr ?? this.cedulaOcr,
      cedulaImage: cedulaImage ?? this.cedulaImage,
      idType: idType ?? this.idType,
      idNumber: idNumber ?? this.idNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      idIssuedDate: idIssuedDate ?? this.idIssuedDate,
      idExpiryDate: idExpiryDate ?? this.idExpiryDate,
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation:
          emergencyContactRelation ?? this.emergencyContactRelation,
      certificadoOcr: certificadoOcr ?? this.certificadoOcr,
      certificadoImage: certificadoImage ?? this.certificadoImage,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleBodyType: vehicleBodyType ?? this.vehicleBodyType,
      vehicleUse: vehicleUse ?? this.vehicleUse,
      serialNiv: serialNiv ?? this.serialNiv,
      serialMotor: serialMotor ?? this.serialMotor,
      serialCarroceria: serialCarroceria ?? this.serialCarroceria,
      seats: seats ?? this.seats,
      crossValidation: crossValidation ?? this.crossValidation,
      isHabitualDriver: isHabitualDriver ?? this.isHabitualDriver,
      ownerCedulaOcr: ownerCedulaOcr ?? this.ownerCedulaOcr,
      ownerCedulaImage: ownerCedulaImage ?? this.ownerCedulaImage,
      ownerIdType: ownerIdType ?? this.ownerIdType,
      ownerIdNumber: ownerIdNumber ?? this.ownerIdNumber,
      ownerFirstName: ownerFirstName ?? this.ownerFirstName,
      ownerLastName: ownerLastName ?? this.ownerLastName,
      color: color ?? this.color,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
      selectedPlan: selectedPlan ?? this.selectedPlan,
      premiumUsd: premiumUsd ?? this.premiumUsd,
      urbanizacion: urbanizacion ?? this.urbanizacion,
      ciudad: ciudad ?? this.ciudad,
      municipio: municipio ?? this.municipio,
      estado: estado ?? this.estado,
      codigoPostal: codigoPostal ?? this.codigoPostal,
      email: email ?? this.email,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      addressFromGps: addressFromGps ?? this.addressFromGps,
      consentRcv: consentRcv ?? this.consentRcv,
      consentVeracidad: consentVeracidad ?? this.consentVeracidad,
      consentAntifraude: consentAntifraude ?? this.consentAntifraude,
      consentPrivacidad: consentPrivacidad ?? this.consentPrivacidad,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
    );
  }
}

class OnboardingNotifier extends Notifier<OnboardingData> {
  @override
  OnboardingData build() => const OnboardingData();

  void updateCedula(CedulaParseResult ocr, File image) {
    state = state.copyWith(
      cedulaOcr: ocr,
      cedulaImage: image,
      idType: ocr.idType,
      idNumber: ocr.idNumber,
      firstName: ocr.firstName,
      lastName: ocr.lastName,
      dateOfBirth: ocr.dateOfBirth,
      nationality: ocr.nationality,
      sex: ocr.sex,
    );
  }

  void confirmIdentity({
    required String idType,
    required String idNumber,
    required String firstName,
    required String lastName,
    DateTime? dateOfBirth,
    DateTime? idIssuedDate,
    DateTime? idExpiryDate,
    String? nationality,
    String? sex,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
  }) {
    state = state.copyWith(
      idType: idType,
      idNumber: idNumber,
      firstName: firstName,
      lastName: lastName,
      dateOfBirth: dateOfBirth,
      idIssuedDate: idIssuedDate,
      idExpiryDate: idExpiryDate,
      nationality: nationality,
      sex: sex,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation,
    );
  }

  void updateCertificado(CertificadoParseResult ocr, File image) {
    state = state.copyWith(
      certificadoOcr: ocr,
      certificadoImage: image,
      plate: ocr.plate,
      brand: ocr.brand,
      model: ocr.model,
      year: ocr.year,
      vehicleType: ocr.vehicleType,
      vehicleBodyType: ocr.vehicleBodyType,
      vehicleUse: (ocr.vehicleType?.contains('CARGA') ?? false)
          ? 'cargo'
          : 'particular',
      serialNiv: ocr.serialNiv,
      serialMotor: ocr.serialMotor,
      seats: ocr.seats,
    );
  }

  void confirmVehicle({
    required String plate,
    required String brand,
    required String model,
    required int year,
    String? vehicleType,
    String? vehicleBodyType,
    required String vehicleUse,
    String? serialNiv,
    String? serialMotor,
    String? serialCarroceria,
    int? seats,
    CrossValidationResult? crossValidation,
  }) {
    state = state.copyWith(
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      vehicleType: vehicleType,
      vehicleBodyType: vehicleBodyType,
      vehicleUse: vehicleUse,
      serialNiv: serialNiv,
      serialMotor: serialMotor,
      serialCarroceria: serialCarroceria,
      seats: seats,
      crossValidation: crossValidation,
    );
  }

  /// Plan selection (RS-090) — must be called before cédula scan.
  void selectPlan(String planCode, double premium) {
    state = state.copyWith(selectedPlan: planCode, premiumUsd: premium);
  }

  /// Owner identity for conductor habitual path (RS-090).
  /// Stores owner's cédula data WITHOUT overwriting the rider's own identity.
  void setOwnerIdentity(CedulaParseResult ocr, File image) {
    state = state.copyWith(
      isHabitualDriver: true,
      ownerCedulaOcr: ocr,
      ownerCedulaImage: image,
      ownerIdType: ocr.idType,
      ownerIdNumber: ocr.idNumber,
      ownerFirstName: ocr.firstName,
      ownerLastName: ocr.lastName,
    );
  }

  /// Marks the user as the vehicle owner (no mismatch or user claims ownership).
  void setAsOwner() {
    state = state.copyWith(isHabitualDriver: false);
  }

  void updateAddress({
    required String urbanizacion,
    required String municipio,
    required String estado,
    String? codigoPostal,
    String? email,
    double? latitude,
    double? longitude,
    bool addressFromGps = false,
  }) {
    state = state.copyWith(
      urbanizacion: urbanizacion,
      municipio: municipio,
      estado: estado,
      codigoPostal: codigoPostal,
      email: email,
      latitude: latitude,
      longitude: longitude,
      addressFromGps: addressFromGps,
    );
  }

  void updateConsents({
    bool? rcv,
    bool? veracidad,
    bool? antifraude,
    bool? privacidad,
  }) {
    final updated = state.copyWith(
      consentRcv: rcv ?? state.consentRcv,
      consentVeracidad: veracidad ?? state.consentVeracidad,
      consentAntifraude: antifraude ?? state.consentAntifraude,
      consentPrivacidad: privacidad ?? state.consentPrivacidad,
    );
    state = updated.allConsentsGiven && state.consentTimestamp == null
        ? updated.copyWith(consentTimestamp: DateTime.now().toUtc())
        : updated;
  }

  void setVehiclePhoto(File photo) {
    state = state.copyWith(vehiclePhoto: photo);
  }

  void reset() => state = const OnboardingData();
}

final onboardingProvider = NotifierProvider<OnboardingNotifier, OnboardingData>(
  OnboardingNotifier.new,
);
