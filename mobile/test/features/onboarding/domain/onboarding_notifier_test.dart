import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/certificado_circulacion_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  // Shorthand accessors
  OnboardingNotifier n() => container.read(onboardingProvider.notifier);
  OnboardingData s() => container.read(onboardingProvider);

  group('OnboardingData', () {
    test('initial state has all fields null/false', () {
      expect(s().idNumber, isNull);
      expect(s().firstName, isNull);
      expect(s().cedulaImage, isNull);
      expect(s().plate, isNull);
      expect(s().certificadoOcr, isNull);
      expect(s().vehiclePhoto, isNull);
      expect(s().urbanizacion, isNull);
      expect(s().consentRcv, isFalse);
      expect(s().consentVeracidad, isFalse);
      expect(s().consentAntifraude, isFalse);
      expect(s().consentPrivacidad, isFalse);
      expect(s().isLegalRepresentative, isFalse);
    });

    test('allConsentsGiven is false when any consent missing', () {
      expect(s().allConsentsGiven, isFalse);

      final partial = s().copyWith(
        consentRcv: true,
        consentVeracidad: true,
        consentAntifraude: true,
      );
      expect(partial.allConsentsGiven, isFalse);
    });

    test('allConsentsGiven is true when all four given', () {
      final full = s().copyWith(
        consentRcv: true,
        consentVeracidad: true,
        consentAntifraude: true,
        consentPrivacidad: true,
      );
      expect(full.allConsentsGiven, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      const base = OnboardingData(
        idType: 'V',
        idNumber: '12345678',
        firstName: 'Juan',
      );
      final updated = base.copyWith(lastName: 'Perez');
      expect(updated.idType, 'V');
      expect(updated.idNumber, '12345678');
      expect(updated.firstName, 'Juan');
      expect(updated.lastName, 'Perez');
    });

    test('copyWith replaces specified fields', () {
      const base = OnboardingData(idType: 'V', idNumber: '12345678');
      final updated = base.copyWith(idType: 'E', idNumber: '99999999');
      expect(updated.idType, 'E');
      expect(updated.idNumber, '99999999');
    });

    test('isMotorcycle returns true when vehicleType is null', () {
      expect(const OnboardingData().isMotorcycle, isTrue);
    });

    test('isMotorcycle returns true for MOTO type', () {
      expect(
        const OnboardingData(vehicleType: 'MOTO PARTICULAR').isMotorcycle,
        isTrue,
      );
    });

    test('isMotorcycle returns false for non-motorcycle', () {
      expect(
        const OnboardingData(vehicleType: 'AUTOMOVIL').isMotorcycle,
        isFalse,
      );
    });
  });

  group('OnboardingNotifier.updateCedula', () {
    test('sets OCR data and image', () {
      const ocr = CedulaParseResult(
        idType: 'V',
        idNumber: '12345678',
        firstName: 'JUAN',
        lastName: 'PEREZ',
        dateOfBirth: null,
        nationality: 'VENEZOLANO',
        sex: 'M',
        confidence: 0.9,
        fieldConfidences: {'idNumber': 0.95, 'firstName': 0.85},
      );
      final file = File('/tmp/cedula_test.jpg');

      n().updateCedula(ocr, file);

      expect(s().cedulaOcr, ocr);
      expect(s().cedulaImage, file);
      expect(s().idType, 'V');
      expect(s().idNumber, '12345678');
      expect(s().firstName, 'JUAN');
      expect(s().lastName, 'PEREZ');
      expect(s().nationality, 'VENEZOLANO');
      expect(s().sex, 'M');
    });

    test('maps dateOfBirth from OCR', () {
      final dob = DateTime(1990, 5, 15);
      final ocr = CedulaParseResult(
        idType: 'V',
        idNumber: '12345678',
        dateOfBirth: dob,
        confidence: 0.8,
      );
      n().updateCedula(ocr, File('/tmp/test.jpg'));
      expect(s().dateOfBirth, dob);
    });
  });

  group('OnboardingNotifier.confirmIdentity', () {
    test('overrides OCR fields with user-edited values', () {
      n().updateCedula(
        const CedulaParseResult(
          idType: 'V',
          idNumber: '12345678',
          firstName: 'JUNA',
          confidence: 0.7,
        ),
        File('/tmp/test.jpg'),
      );
      expect(s().firstName, 'JUNA'); // OCR typo

      n().confirmIdentity(
        idType: 'V',
        idNumber: '12345678',
        firstName: 'JUAN',
        lastName: 'PEREZ',
        dateOfBirth: DateTime(1990, 1, 1),
        nationality: 'VENEZOLANO',
        sex: 'M',
      );

      expect(s().firstName, 'JUAN');
      expect(s().lastName, 'PEREZ');
      expect(s().dateOfBirth, DateTime(1990, 1, 1));
    });

    test('sets emergency contact fields', () {
      n().confirmIdentity(
        idType: 'V',
        idNumber: '12345678',
        firstName: 'JUAN',
        lastName: 'PEREZ',
        emergencyContactName: 'Maria',
        emergencyContactPhone: '04121234567',
        emergencyContactRelation: 'Esposo/a',
      );

      expect(s().emergencyContactName, 'Maria');
      expect(s().emergencyContactPhone, '04121234567');
      expect(s().emergencyContactRelation, 'Esposo/a');
    });
  });

  group('OnboardingNotifier.updateCertificado', () {
    test('sets vehicle data from certificado OCR', () {
      const ocr = CertificadoParseResult(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        vehicleType: 'MOTO PARTICULAR',
        vehicleBodyType: 'DEPORTIVA',
        serialNiv: 'LBEP4E2F1E2000001',
        serialMotor: 'SK162FMJ12345',
        seats: 2,
        ownerName: 'JUAN PEREZ',
        ownerCedula: 'V12345678',
        confidence: 0.9,
      );
      final file = File('/tmp/certificado_test.jpg');

      n().updateCertificado(ocr, file);

      expect(s().certificadoOcr, ocr);
      expect(s().certificadoImage, file);
      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().model, 'BR150');
      expect(s().year, 2020);
      expect(s().vehicleType, 'MOTO PARTICULAR');
      expect(s().vehicleBodyType, 'DEPORTIVA');
      expect(s().serialNiv, 'LBEP4E2F1E2000001');
      expect(s().serialMotor, 'SK162FMJ12345');
      expect(s().seats, 2);
      expect(s().vehicleUse, 'particular');
    });

    test('sets vehicleUse to cargo when vehicleType contains CARGA', () {
      const ocr = CertificadoParseResult(
        plate: 'AB123CD',
        vehicleType: 'MOTO CARGA',
        confidence: 0.8,
      );
      n().updateCertificado(ocr, File('/tmp/test.jpg'));
      expect(s().vehicleUse, 'cargo');
    });

    test('defaults vehicleUse to particular when vehicleType is null', () {
      const ocr = CertificadoParseResult(plate: 'AB123CD', confidence: 0.5);
      n().updateCertificado(ocr, File('/tmp/test.jpg'));
      expect(s().vehicleUse, 'particular');
    });
  });

  group('OnboardingNotifier.confirmVehicle', () {
    test('sets confirmed vehicle fields with cross-validation', () {
      const cross = CrossValidationResult(
        nameMatch: true,
        cedulaMatch: true,
        overallMatch: true,
      );

      n().confirmVehicle(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        vehicleType: 'MOTO PARTICULAR',
        vehicleBodyType: 'DEPORTIVA',
        vehicleUse: 'particular',
        serialNiv: 'LBEP4E2F1E2000001',
        serialMotor: 'MOTOR123',
        seats: 2,
        crossValidation: cross,
        isLegalRepresentative: false,
      );

      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().year, 2020);
      expect(s().vehicleType, 'MOTO PARTICULAR');
      expect(s().serialNiv, 'LBEP4E2F1E2000001');
      expect(s().crossValidation?.overallMatch, isTrue);
      expect(s().isLegalRepresentative, isFalse);
    });

    test('sets isLegalRepresentative on mismatch', () {
      const cross = CrossValidationResult(
        nameMatch: false,
        cedulaMatch: true,
        overallMatch: false,
        mismatchDetails: 'Name mismatch',
      );

      n().confirmVehicle(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        vehicleUse: 'particular',
        crossValidation: cross,
        isLegalRepresentative: true,
      );

      expect(s().crossValidation?.overallMatch, isFalse);
      expect(s().isLegalRepresentative, isTrue);
    });
  });

  group('OnboardingNotifier.setVehiclePhoto', () {
    test('stores vehicle photo file', () {
      final file = File('/tmp/vehicle_photo.jpg');
      n().setVehiclePhoto(file);
      expect(s().vehiclePhoto, file);
    });
  });

  group('OnboardingNotifier.updateAddress', () {
    test('sets all address fields', () {
      n().updateAddress(
        urbanizacion: 'El Paraíso',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
        codigoPostal: '1010',
      );

      expect(s().urbanizacion, 'El Paraíso');
      expect(s().municipio, 'Libertador');
      expect(s().estado, 'Distrito Capital');
      expect(s().codigoPostal, '1010');
    });

    test('allows null codigoPostal', () {
      n().updateAddress(
        urbanizacion: 'Centro',
        municipio: 'Girardot',
        estado: 'Aragua',
      );

      expect(s().codigoPostal, isNull);
    });

    test('stores GPS coordinates when provided', () {
      n().updateAddress(
        urbanizacion: 'Las Mercedes',
        municipio: 'Baruta',
        estado: 'Miranda',
        latitude: 10.4922,
        longitude: -66.8577,
        addressFromGps: true,
      );

      expect(s().latitude, closeTo(10.4922, 0.0001));
      expect(s().longitude, closeTo(-66.8577, 0.0001));
      expect(s().addressFromGps, isTrue);
    });
  });

  group('OnboardingNotifier.updateConsents', () {
    test('toggles individual consents', () {
      n().updateConsents(rcv: true);
      expect(s().consentRcv, isTrue);
      expect(s().consentVeracidad, isFalse);

      n().updateConsents(veracidad: true);
      expect(s().consentRcv, isTrue);
      expect(s().consentVeracidad, isTrue);

      n().updateConsents(antifraude: true, privacidad: true);
      expect(s().allConsentsGiven, isTrue);
    });

    test('can untoggle a consent', () {
      n().updateConsents(
        rcv: true,
        veracidad: true,
        antifraude: true,
        privacidad: true,
      );
      expect(s().allConsentsGiven, isTrue);

      n().updateConsents(rcv: false);
      expect(s().consentRcv, isFalse);
      expect(s().allConsentsGiven, isFalse);
    });

    test('sets consentTimestamp when all consents given', () {
      final before = DateTime.now().toUtc();
      n().updateConsents(
        rcv: true,
        veracidad: true,
        antifraude: true,
        privacidad: true,
      );
      final after = DateTime.now().toUtc();

      expect(s().consentTimestamp, isNotNull);
      expect(
        s().consentTimestamp!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(s().consentTimestamp!.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });
  });

  group('OnboardingNotifier.reset', () {
    test('clears all state back to initial', () {
      n().updateCedula(
        const CedulaParseResult(
          idType: 'V',
          idNumber: '12345678',
          firstName: 'JUAN',
          confidence: 0.9,
        ),
        File('/tmp/test.jpg'),
      );
      n().updateAddress(
        urbanizacion: 'Centro',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
      );
      n().updateConsents(rcv: true, veracidad: true);

      expect(s().idNumber, isNotNull);
      expect(s().urbanizacion, isNotNull);

      n().reset();

      expect(s().idNumber, isNull);
      expect(s().firstName, isNull);
      expect(s().certificadoOcr, isNull);
      expect(s().urbanizacion, isNull);
      expect(s().consentRcv, isFalse);
      expect(s().allConsentsGiven, isFalse);
    });
  });

  group('Full onboarding flow (Sprint 4A — 2-step document scan)', () {
    test('completes all steps in sequence', () {
      // Step 1: Cédula scan + confirm
      n().updateCedula(
        const CedulaParseResult(
          idType: 'V',
          idNumber: '12345678',
          firstName: 'JUAN',
          lastName: 'PEREZ',
          confidence: 0.85,
        ),
        File('/tmp/cedula.jpg'),
      );
      n().confirmIdentity(
        idType: 'V',
        idNumber: '12345678',
        firstName: 'JUAN',
        lastName: 'PEREZ',
        dateOfBirth: DateTime(1990, 5, 15),
        nationality: 'VENEZOLANO',
        sex: 'M',
        emergencyContactName: 'Maria Perez',
        emergencyContactPhone: '04121234567',
        emergencyContactRelation: 'Esposo/a',
      );

      // Step 2: Certificado de circulación scan + confirm
      n().updateCertificado(
        const CertificadoParseResult(
          plate: 'AB123CD',
          brand: 'BERA',
          model: 'BR150',
          year: 2020,
          vehicleType: 'MOTO PARTICULAR',
          vehicleBodyType: 'DEPORTIVA',
          serialNiv: 'LBEP4E2F1E2000001',
          serialMotor: 'SK162FMJ12345',
          seats: 2,
          ownerName: 'JUAN PEREZ',
          ownerCedula: 'V12345678',
          confidence: 0.9,
        ),
        File('/tmp/certificado.jpg'),
      );
      n().confirmVehicle(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        vehicleType: 'MOTO PARTICULAR',
        vehicleBodyType: 'DEPORTIVA',
        vehicleUse: 'particular',
        serialNiv: 'LBEP4E2F1E2000001',
        serialMotor: 'SK162FMJ12345',
        seats: 2,
      );

      // Step 3: Address with GPS
      n().updateAddress(
        urbanizacion: 'El Paraíso',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
        codigoPostal: '1010',
        latitude: 10.4922,
        longitude: -66.8577,
        addressFromGps: true,
      );

      // Step 4: Consent
      n().updateConsents(
        rcv: true,
        veracidad: true,
        antifraude: true,
        privacidad: true,
      );

      // Verify final state
      expect(s().idNumber, '12345678');
      expect(s().firstName, 'JUAN');
      expect(s().emergencyContactName, 'Maria Perez');
      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().vehicleType, 'MOTO PARTICULAR');
      expect(s().serialNiv, 'LBEP4E2F1E2000001');
      expect(s().seats, 2);
      expect(s().certificadoImage, isNotNull);
      expect(s().urbanizacion, 'El Paraíso');
      expect(s().estado, 'Distrito Capital');
      expect(s().latitude, closeTo(10.4922, 0.0001));
      expect(s().addressFromGps, isTrue);
      expect(s().allConsentsGiven, isTrue);
      expect(s().consentTimestamp, isNotNull);
    });
  });
}
