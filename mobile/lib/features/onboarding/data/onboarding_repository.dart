import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/utils/hash_utils.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';

class OnboardingRepository {
  OnboardingRepository._();
  static final instance = OnboardingRepository._();

  final _uuid = const Uuid();

  Future<void> saveOnboardingData(OnboardingData data) async {
    final user = SupabaseService.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userId = user.id;

    // Upload documents first (fail fast if storage is down)
    String? cedulaUrl;
    String? licenciaUrl;
    String? carnetUrl;
    String? vehiclePhotoUrl;

    if (data.cedulaImage != null) {
      cedulaUrl = await _uploadDocument(
        file: data.cedulaImage!,
        userId: userId,
        docType: 'cedula',
      );
    }

    if (data.licenciaImage != null) {
      licenciaUrl = await _uploadDocument(
        file: data.licenciaImage!,
        userId: userId,
        docType: 'licencia',
      );
    }

    if (data.carnetImage != null) {
      carnetUrl = await _uploadDocument(
        file: data.carnetImage!,
        userId: userId,
        docType: 'carnet',
      );
    }

    if (data.vehiclePhoto != null) {
      vehiclePhotoUrl = await _uploadDocument(
        file: data.vehiclePhoto!,
        userId: userId,
        docType: 'vehicle_photo',
      );
    }

    // Create profile (upsert — safe to retry)
    await SupabaseService.client.from(SupabaseConstants.profiles).upsert({
      'id': userId,
      'id_type': data.idType ?? 'V',
      'id_number': data.idNumber,
      'first_name': data.firstName,
      'last_name': data.lastName,
      'date_of_birth': data.dateOfBirth?.toIso8601String(),
      'nationality': data.nationality,
      'sex': data.sex,
      'urbanizacion': data.urbanizacion,
      'ciudad': data.ciudad,
      'municipio': data.municipio,
      'estado': data.estado,
      'codigo_postal': data.codigoPostal,
      'emergency_contact_name': data.emergencyContactName,
      'emergency_contact_phone': data.emergencyContactPhone,
      'emergency_contact_relation': data.emergencyContactRelation,
      'licencia_number': data.licenciaNumber,
      'licencia_categories': data.licenciaCategories,
      'licencia_expiry': data.licenciaExpiry?.toIso8601String().split('T').first,
      'blood_type': data.bloodType,
      'consent_rcv': data.consentRcv,
      'consent_veracidad': data.consentVeracidad,
      'consent_antifraude': data.consentAntifraude,
      'consent_privacidad': data.consentPrivacidad,
      'consent_timestamp': data.consentTimestamp?.toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
    });

    // Create vehicle
    final vehicleId = _uuid.v4();
    await SupabaseService.client.from(SupabaseConstants.vehicles).upsert({
      'id': vehicleId,
      'profile_id': userId,
      'plate': data.plate,
      'brand': data.brand,
      'model': data.model,
      'year': data.year,
      'color': data.color,
      'vehicle_use': data.vehicleUse ?? 'particular',
      'serial_motor': data.serialMotor,
      'serial_carroceria': data.serialCarroceria,
      'rear_photo_url': vehiclePhotoUrl,
    });

    // Insert document records
    if (cedulaUrl != null) {
      await _insertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: cedulaUrl,
        docType: 'cedula',
        file: data.cedulaImage!,
        ocrData: {
          'idType': data.idType,
          'idNumber': data.idNumber,
          'firstName': data.firstName,
          'lastName': data.lastName,
        },
      );
    }

    if (licenciaUrl != null) {
      await _insertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: licenciaUrl,
        docType: 'licencia_conducir',
        file: data.licenciaImage!,
        ocrData: {
          'licenciaNumber': data.licenciaNumber,
          'categories': data.licenciaCategories,
          'expiryDate': data.licenciaExpiry?.toIso8601String(),
          'bloodType': data.bloodType,
        },
      );
    }

    if (carnetUrl != null) {
      await _insertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: carnetUrl,
        docType: 'carnet_circulacion',
        file: data.carnetImage!,
        ocrData: {
          'plate': data.plate,
          'brand': data.brand,
          'model': data.model,
          'year': data.year,
        },
      );
    }

    if (vehiclePhotoUrl != null) {
      await _insertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: vehiclePhotoUrl,
        docType: 'vehicle_photo',
        file: data.vehiclePhoto!,
        ocrData: {},
      );
    }
  }

  Future<String> _uploadDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    final ext = 'jpg';
    final path = '$userId/${docType}_${_uuid.v4()}.$ext';
    await SupabaseService.storage.from(SupabaseConstants.bucketDocuments).upload(
      path,
      file,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    final signedUrl = await SupabaseService.storage
        .from(SupabaseConstants.bucketDocuments)
        .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year
    return signedUrl;
  }

  Future<void> _insertDocumentRecord({
    required String userId,
    required String vehicleId,
    required String url,
    required String docType,
    required File file,
    required Map<String, dynamic> ocrData,
  }) async {
    final hash = await HashUtils.sha256HashFile(file);
    await SupabaseService.client.from(SupabaseConstants.documents).insert({
      'id': _uuid.v4(),
      'profile_id': userId,
      'vehicle_id': vehicleId,
      'document_type': docType,
      'storage_url': url,
      'sha256_hash': hash,
      'ocr_data': ocrData,
      'uploaded_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<bool> profileExists(String userId) async {
    final result = await SupabaseService.client
        .from(SupabaseConstants.profiles)
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    return result != null;
  }
}
