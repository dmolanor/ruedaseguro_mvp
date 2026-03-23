import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/onboarding/domain/cedula_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/carnet_parser.dart';
import 'package:ruedaseguro/features/onboarding/domain/cross_validator.dart';
import 'package:ruedaseguro/features/onboarding/domain/licencia_parser.dart';
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
      expect(s().licenciaNumber, isNull);
      expect(s().licenciaCategories, isEmpty);
      expect(s().plate, isNull);
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

  group('OnboardingNotifier.updateLicencia', () {
    test('sets licencia OCR data', () {
      const ocr = LicenciaParseResult(
        licenciaNumber: '987654321',
        categories: ['1°', '2°'],
        expiryDate: null,
        bloodType: 'A+',
        holderCedula: 'V12345678',
        confidence: 0.85,
        fieldConfidences: {'licenciaNumber': 0.75, 'categories': 0.85},
      );
      final file = File('/tmp/licencia_test.jpg');

      n().updateLicencia(ocr, file);

      expect(s().licenciaOcr, ocr);
      expect(s().licenciaImage, file);
      expect(s().licenciaNumber, '987654321');
      expect(s().licenciaCategories, ['1°', '2°']);
      expect(s().bloodType, 'A+');
    });

    test('maps expiry date from OCR', () {
      final expiry = DateTime(2030, 6, 15);
      final ocr = LicenciaParseResult(
        categories: const ['2°'],
        expiryDate: expiry,
        confidence: 0.8,
      );
      n().updateLicencia(ocr, File('/tmp/test.jpg'));
      expect(s().licenciaExpiry, expiry);
    });
  });

  group('OnboardingNotifier.confirmLicencia', () {
    test('overrides licencia fields with user-edited values', () {
      n().updateLicencia(
        const LicenciaParseResult(
          licenciaNumber: '123',
          categories: ['1°'],
          bloodType: 'O+',
          confidence: 0.7,
        ),
        File('/tmp/test.jpg'),
      );

      n().confirmLicencia(
        licenciaNumber: '987654321',
        categories: ['1°', '2°', '3°'],
        expiryDate: DateTime(2030, 12, 31),
        bloodType: 'A-',
      );

      expect(s().licenciaNumber, '987654321');
      expect(s().licenciaCategories, ['1°', '2°', '3°']);
      expect(s().licenciaExpiry, DateTime(2030, 12, 31));
      expect(s().bloodType, 'A-');
    });
  });

  group('OnboardingNotifier.updateCarnet', () {
    test('sets vehicle data from OCR', () {
      const ocr = CarnetParseResult(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        color: 'AZUL',
        vehicleUse: 'particular',
        serialMotor: 'SK162FMJ12345',
        serialCarroceria: '8218MBCA1FD000647',
        ownerName: 'JUAN PEREZ',
        ownerCedula: 'V12345678',
        confidence: 0.9,
      );
      final file = File('/tmp/carnet_test.jpg');

      n().updateCarnet(ocr, file);

      expect(s().carnetOcr, ocr);
      expect(s().carnetImage, file);
      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().model, 'BR150');
      expect(s().year, 2020);
      expect(s().color, 'AZUL');
      expect(s().vehicleUse, 'particular');
      expect(s().serialMotor, 'SK162FMJ12345');
      expect(s().serialCarroceria, '8218MBCA1FD000647');
    });

    test('defaults vehicleUse to particular when null', () {
      const ocr = CarnetParseResult(plate: 'AB123CD', confidence: 0.5);
      n().updateCarnet(ocr, File('/tmp/test.jpg'));
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
        color: 'AZUL',
        vehicleUse: 'particular',
        serialMotor: 'MOTOR123',
        serialCarroceria: 'CARR456',
        crossValidation: cross,
        isLegalRepresentative: false,
      );

      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().year, 2020);
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
        ciudad: 'Caracas',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
        codigoPostal: '1010',
      );

      expect(s().urbanizacion, 'El Paraíso');
      expect(s().ciudad, 'Caracas');
      expect(s().municipio, 'Libertador');
      expect(s().estado, 'Distrito Capital');
      expect(s().codigoPostal, '1010');
    });

    test('allows null codigoPostal', () {
      n().updateAddress(
        urbanizacion: 'Centro',
        ciudad: 'Maracay',
        municipio: 'Girardot',
        estado: 'Aragua',
      );

      expect(s().codigoPostal, isNull);
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
        ciudad: 'Caracas',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
      );
      n().updateConsents(rcv: true, veracidad: true);

      expect(s().idNumber, isNotNull);
      expect(s().urbanizacion, isNotNull);

      n().reset();

      expect(s().idNumber, isNull);
      expect(s().firstName, isNull);
      expect(s().urbanizacion, isNull);
      expect(s().consentRcv, isFalse);
      expect(s().allConsentsGiven, isFalse);
      expect(s().licenciaCategories, isEmpty);
    });
  });

  group('Full onboarding flow', () {
    test('completes all 6 steps in sequence', () {
      // Step 1: Cédula
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
      );

      // Step 2: Licencia
      n().updateLicencia(
        const LicenciaParseResult(
          licenciaNumber: '987654321',
          categories: ['1°', '2°'],
          bloodType: 'A+',
          confidence: 0.8,
        ),
        File('/tmp/licencia.jpg'),
      );
      n().confirmLicencia(
        licenciaNumber: '987654321',
        categories: ['1°', '2°'],
        expiryDate: DateTime(2030, 6, 15),
        bloodType: 'A+',
      );

      // Step 3: Certificado de registro
      n().updateCarnet(
        const CarnetParseResult(
          plate: 'AB123CD',
          brand: 'BERA',
          model: 'BR150',
          year: 2020,
          confidence: 0.9,
        ),
        File('/tmp/carnet.jpg'),
      );
      n().confirmVehicle(
        plate: 'AB123CD',
        brand: 'BERA',
        model: 'BR150',
        year: 2020,
        vehicleUse: 'particular',
      );

      // Step 4: Vehicle photo
      n().setVehiclePhoto(File('/tmp/vehicle.jpg'));

      // Step 5: Address
      n().updateAddress(
        urbanizacion: 'El Paraíso',
        ciudad: 'Caracas',
        municipio: 'Libertador',
        estado: 'Distrito Capital',
        codigoPostal: '1010',
      );

      // Step 6: Consent
      n().updateConsents(
        rcv: true,
        veracidad: true,
        antifraude: true,
        privacidad: true,
      );

      // Verify final state
      expect(s().idNumber, '12345678');
      expect(s().firstName, 'JUAN');
      expect(s().licenciaNumber, '987654321');
      expect(s().licenciaCategories, ['1°', '2°']);
      expect(s().licenciaExpiry, DateTime(2030, 6, 15));
      expect(s().bloodType, 'A+');
      expect(s().plate, 'AB123CD');
      expect(s().brand, 'BERA');
      expect(s().vehiclePhoto, isNotNull);
      expect(s().urbanizacion, 'El Paraíso');
      expect(s().estado, 'Distrito Capital');
      expect(s().allConsentsGiven, isTrue);
    });
  });
}
