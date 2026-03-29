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
    final phone = user.phone ?? '';

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

    // Upsert profile
    await SupabaseService.client.from(SupabaseConstants.profiles).upsert({
      'id': userId,
      'phone': phone,
      'id_type': data.idType ?? 'V',
      'id_number': data.idNumber,
      'first_name': data.firstName,
      'last_name': data.lastName,
      'date_of_birth': data.dateOfBirth?.toIso8601String().split('T').first,
      'nationality': data.nationality,
      'sex': data.sex,
      'urbanizacion': data.urbanizacion,
      'ciudad': data.ciudad,
      'municipio': data.municipio,
      'estado': data.estado,
      'codigo_postal': data.codigoPostal,
      'emergency_name': data.emergencyContactName,
      'emergency_phone': data.emergencyContactPhone,
      'emergency_relation': data.emergencyContactRelation,
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

    // Insert or update vehicle (check first to avoid duplicates on retry)
    final vehicleId = await _upsertVehicle(
      userId: userId,
      data: data,
      vehiclePhotoUrl: vehiclePhotoUrl,
    );

    // Insert document records (only if not already uploaded for this user)
    if (cedulaUrl != null) {
      await _upsertDocumentRecord(
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
        ocrConfidence: data.cedulaOcr?.confidence,
      );
    }

    if (licenciaUrl != null) {
      await _upsertDocumentRecord(
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
        ocrConfidence: data.licenciaOcr?.confidence,
      );
    }

    if (carnetUrl != null) {
      await _upsertDocumentRecord(
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
        ocrConfidence: data.carnetOcr?.confidence,
      );
    }

    if (vehiclePhotoUrl != null) {
      await _upsertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: vehiclePhotoUrl,
        docType: 'vehicle_photo',
        file: data.vehiclePhoto!,
        ocrData: {},
        ocrConfidence: null,
      );
    }
  }

  /// Inserts a new vehicle or updates the existing one for this user.
  Future<String> _upsertVehicle({
    required String userId,
    required OnboardingData data,
    String? vehiclePhotoUrl,
  }) async {
    final existing = await SupabaseService.client
        .from(SupabaseConstants.vehicles)
        .select('id')
        .eq('owner_id', userId)
        .maybeSingle();

    final payload = {
      'owner_id': userId,
      'plate': data.plate,
      'brand': data.brand,
      'model': data.model,
      'year': data.year,
      'color': data.color,
      'vehicle_use': data.vehicleUse ?? 'particular',
      'serial_motor': data.serialMotor,
      'serial_carroceria': data.serialCarroceria,
      if (vehiclePhotoUrl != null) 'rear_photo_url': vehiclePhotoUrl,
    };

    if (existing != null) {
      final vehicleId = existing['id'] as String;
      await SupabaseService.client
          .from(SupabaseConstants.vehicles)
          .update(payload)
          .eq('id', vehicleId);
      return vehicleId;
    } else {
      final vehicleId = _uuid.v4();
      await SupabaseService.client
          .from(SupabaseConstants.vehicles)
          .insert({...payload, 'id': vehicleId});
      return vehicleId;
    }
  }

  Future<String> _uploadDocument({
    required File file,
    required String userId,
    required String docType,
  }) async {
    final path = '$userId/${docType}_${_uuid.v4()}.jpg';
    await SupabaseService.storage.from(SupabaseConstants.bucketDocuments).upload(
      path,
      file,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: false),
    );
    return await SupabaseService.storage
        .from(SupabaseConstants.bucketDocuments)
        .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year
  }

  /// Inserts a document record, skipping if one with the same hash already
  /// exists for this user+docType (safe retry on network failure).
  Future<void> _upsertDocumentRecord({
    required String userId,
    required String vehicleId,
    required String url,
    required String docType,
    required File file,
    required Map<String, dynamic> ocrData,
    double? ocrConfidence,
  }) async {
    final hash = await HashUtils.sha256HashFile(file);

    // Check for existing record with same hash to prevent duplicates on retry.
    final existing = await SupabaseService.client
        .from(SupabaseConstants.documents)
        .select('id')
        .eq('profile_id', userId)
        .eq('doc_type', docType)
        .eq('file_hash', hash)
        .maybeSingle();

    if (existing != null) return; // Already uploaded — skip.

    await SupabaseService.client.from(SupabaseConstants.documents).insert({
      'id': _uuid.v4(),
      'profile_id': userId,
      'vehicle_id': vehicleId,
      'doc_type': docType,
      'file_url': url,
      'file_hash': hash,
      'ocr_extracted': ocrData,
      if (ocrConfidence != null) 'ocr_confidence': ocrConfidence,
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
