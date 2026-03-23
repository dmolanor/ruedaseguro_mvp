import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/licencia_parser.dart';

/// Holds all data collected during the onboarding flow.
/// Lives as a Riverpod StateNotifier so any screen can read/write it.
class OnboardingData {
  // Step 1 — Cédula
  final CedulaParseResult? cedulaOcr;
  final File? cedulaImage;

  // Confirmed identity fields (user may edit OCR results)
  final String? idType;
  final String? idNumber;
  final String? firstName;
  final String? lastName;
  final DateTime? dateOfBirth;
  final String? nationality;
  final String? sex;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? emergencyContactRelation;

  // Step 2 — Licencia de conducir
  final LicenciaParseResult? licenciaOcr;
  final File? licenciaImage;
  final String? licenciaNumber;
  final List<String> licenciaCategories;
  final DateTime? licenciaExpiry;
  final String? bloodType;

  // Step 3 — Certificado de registro de vehículo
  final CarnetParseResult? carnetOcr;
  final File? carnetImage;

  // Confirmed vehicle fields
  final String? plate;
  final String? brand;
  final String? model;
  final int? year;
  final String? color;
  final String? vehicleUse;
  final String? serialMotor;
  final String? serialCarroceria;

  // Step 4 — Vehicle rear photo
  final File? vehiclePhoto;

  // Cross-validation result
  final CrossValidationResult? crossValidation;
  final bool isLegalRepresentative;

  // Step 5 — Address
  final String? urbanizacion;
  final String? ciudad;
  final String? municipio;
  final String? estado;
  final String? codigoPostal;

  // Step 6 — Consent
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
    this.nationality,
    this.sex,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelation,
    this.licenciaOcr,
    this.licenciaImage,
    this.licenciaNumber,
    this.licenciaCategories = const [],
    this.licenciaExpiry,
    this.bloodType,
    this.carnetOcr,
    this.carnetImage,
    this.plate,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.vehicleUse,
    this.serialMotor,
    this.serialCarroceria,
    this.vehiclePhoto,
    this.crossValidation,
    this.isLegalRepresentative = false,
    this.urbanizacion,
    this.ciudad,
    this.municipio,
    this.estado,
    this.codigoPostal,
    this.consentRcv = false,
    this.consentVeracidad = false,
    this.consentAntifraude = false,
    this.consentPrivacidad = false,
    this.consentTimestamp,
  });

  bool get allConsentsGiven =>
      consentRcv && consentVeracidad && consentAntifraude && consentPrivacidad;

  OnboardingData copyWith({
    CedulaParseResult? cedulaOcr,
    File? cedulaImage,
    String? idType,
    String? idNumber,
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? nationality,
    String? sex,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelation,
    LicenciaParseResult? licenciaOcr,
    File? licenciaImage,
    String? licenciaNumber,
    List<String>? licenciaCategories,
    DateTime? licenciaExpiry,
    String? bloodType,
    CarnetParseResult? carnetOcr,
    File? carnetImage,
    String? plate,
    String? brand,
    String? model,
    int? year,
    String? color,
    String? vehicleUse,
    String? serialMotor,
    String? serialCarroceria,
    File? vehiclePhoto,
    CrossValidationResult? crossValidation,
    bool? isLegalRepresentative,
    String? urbanizacion,
    String? ciudad,
    String? municipio,
    String? estado,
    String? codigoPostal,
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
      nationality: nationality ?? this.nationality,
      sex: sex ?? this.sex,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation ?? this.emergencyContactRelation,
      licenciaOcr: licenciaOcr ?? this.licenciaOcr,
      licenciaImage: licenciaImage ?? this.licenciaImage,
      licenciaNumber: licenciaNumber ?? this.licenciaNumber,
      licenciaCategories: licenciaCategories ?? this.licenciaCategories,
      licenciaExpiry: licenciaExpiry ?? this.licenciaExpiry,
      bloodType: bloodType ?? this.bloodType,
      carnetOcr: carnetOcr ?? this.carnetOcr,
      carnetImage: carnetImage ?? this.carnetImage,
      plate: plate ?? this.plate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      vehicleUse: vehicleUse ?? this.vehicleUse,
      serialMotor: serialMotor ?? this.serialMotor,
      serialCarroceria: serialCarroceria ?? this.serialCarroceria,
      vehiclePhoto: vehiclePhoto ?? this.vehiclePhoto,
      crossValidation: crossValidation ?? this.crossValidation,
      isLegalRepresentative: isLegalRepresentative ?? this.isLegalRepresentative,
      urbanizacion: urbanizacion ?? this.urbanizacion,
      ciudad: ciudad ?? this.ciudad,
      municipio: municipio ?? this.municipio,
      estado: estado ?? this.estado,
      codigoPostal: codigoPostal ?? this.codigoPostal,
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
      nationality: nationality,
      sex: sex,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelation: emergencyContactRelation,
    );
  }

  void updateLicencia(LicenciaParseResult ocr, File image) {
    state = state.copyWith(
      licenciaOcr: ocr,
      licenciaImage: image,
      licenciaNumber: ocr.licenciaNumber,
      licenciaCategories: ocr.categories,
      licenciaExpiry: ocr.expiryDate,
      bloodType: ocr.bloodType,
    );
  }

  void confirmLicencia({
    required String licenciaNumber,
    required List<String> categories,
    DateTime? expiryDate,
    String? bloodType,
  }) {
    state = state.copyWith(
      licenciaNumber: licenciaNumber,
      licenciaCategories: categories,
      licenciaExpiry: expiryDate,
      bloodType: bloodType,
    );
  }

  void updateCarnet(CarnetParseResult ocr, File image) {
    state = state.copyWith(
      carnetOcr: ocr,
      carnetImage: image,
      plate: ocr.plate,
      brand: ocr.brand,
      model: ocr.model,
      year: ocr.year,
      color: ocr.color,
      vehicleUse: ocr.vehicleUse ?? 'particular',
      serialMotor: ocr.serialMotor,
      serialCarroceria: ocr.serialCarroceria,
    );
  }

  void confirmVehicle({
    required String plate,
    required String brand,
    required String model,
    required int year,
    String? color,
    required String vehicleUse,
    String? serialMotor,
    String? serialCarroceria,
    CrossValidationResult? crossValidation,
    bool isLegalRepresentative = false,
  }) {
    state = state.copyWith(
      plate: plate,
      brand: brand,
      model: model,
      year: year,
      color: color,
      vehicleUse: vehicleUse,
      serialMotor: serialMotor,
      serialCarroceria: serialCarroceria,
      crossValidation: crossValidation,
      isLegalRepresentative: isLegalRepresentative,
    );
  }

  void setVehiclePhoto(File photo) => state = state.copyWith(vehiclePhoto: photo);

  void updateAddress({
    required String urbanizacion,
    required String ciudad,
    required String municipio,
    required String estado,
    String? codigoPostal,
  }) {
    state = state.copyWith(
      urbanizacion: urbanizacion,
      ciudad: ciudad,
      municipio: municipio,
      estado: estado,
      codigoPostal: codigoPostal,
    );
  }

  void updateConsents({
    bool? rcv,
    bool? veracidad,
    bool? antifraude,
    bool? privacidad,
  }) {
    state = state.copyWith(
      consentRcv: rcv ?? state.consentRcv,
      consentVeracidad: veracidad ?? state.consentVeracidad,
      consentAntifraude: antifraude ?? state.consentAntifraude,
      consentPrivacidad: privacidad ?? state.consentPrivacidad,
    );
  }

  void reset() => state = const OnboardingData();
}

final onboardingProvider =
    NotifierProvider<OnboardingNotifier, OnboardingData>(OnboardingNotifier.new);
