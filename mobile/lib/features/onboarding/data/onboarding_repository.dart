import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/utils/hash_utils.dart';
import 'package:ruedaseguro/features/onboarding/domain/onboarding_state.dart';

/// Sprint 4A (RS-078): Updated to remove licencia, use certificadoImage, and
/// save new vehicle fields (vehicle_type, vehicle_body_type, serial_niv, seats)
/// plus geolocation fields on profiles (RS-085).
class OnboardingRepository {
  OnboardingRepository._();
  static final instance = OnboardingRepository._();

  final _uuid = const Uuid();

  Future<void> saveOnboardingData(OnboardingData data) async {
    final user = SupabaseService.auth.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final userId = user.id;
    final phone = user.phone ?? '';

    // Upload documents (fail fast if storage is down)
    String? cedulaUrl;
    String? certificadoUrl;

    if (data.cedulaImage != null) {
      cedulaUrl = await _uploadDocument(
        file: data.cedulaImage!,
        userId: userId,
        docType: 'cedula',
      );
    }

    if (data.certificadoImage != null) {
      certificadoUrl = await _uploadDocument(
        file: data.certificadoImage!,
        userId: userId,
        docType: 'certificado_circulacion',
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
      'date_of_birth':
          data.dateOfBirth?.toIso8601String().split('T').first,
      'nationality': data.nationality,
      'sex': data.sex,
      'urbanizacion': data.urbanizacion,
      'municipio': data.municipio,
      'estado': data.estado,
      'codigo_postal': data.codigoPostal,
      // RS-085: geolocation
      if (data.latitude != null) 'latitude': data.latitude,
      if (data.longitude != null) 'longitude': data.longitude,
      'address_from_gps': data.addressFromGps,
      // Emergency contact (single — RS-088 will add multi-contact table)
      'emergency_name': data.emergencyContactName,
      'emergency_phone': data.emergencyContactPhone,
      'emergency_relation': data.emergencyContactRelation,
      'consent_rcv': data.consentRcv,
      'consent_veracidad': data.consentVeracidad,
      'consent_antifraude': data.consentAntifraude,
      'consent_privacidad': data.consentPrivacidad,
      'consent_timestamp': data.consentTimestamp?.toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
    });

    // Insert or update vehicle
    final vehicleId = await _upsertVehicle(
      userId: userId,
      data: data,
    );

    // Insert document records
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

    if (certificadoUrl != null) {
      await _upsertDocumentRecord(
        userId: userId,
        vehicleId: vehicleId,
        url: certificadoUrl,
        docType: 'certificado_circulacion',
        file: data.certificadoImage!,
        ocrData: {
          'plate': data.plate,
          'brand': data.brand,
          'model': data.model,
          'year': data.year,
          'vehicleType': data.vehicleType,
          'vehicleBodyType': data.vehicleBodyType,
          'serialNiv': data.serialNiv,
          'seats': data.seats,
          'format': data.certificadoOcr?.format.name,
        },
        ocrConfidence: data.certificadoOcr?.confidence,
      );
    }
  }

  Future<String> _upsertVehicle({
    required String userId,
    required OnboardingData data,
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
      'vehicle_use': data.vehicleUse ?? 'particular',
      // New Sprint 4A fields (RS-079)
      'vehicle_type': data.vehicleType,
      'vehicle_body_type': data.vehicleBodyType,
      'serial_niv': data.serialNiv,
      'serial_motor': data.serialMotor,
      'seats': data.seats,
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
    // Use appropriate extension for PDFs
    final ext = file.path.toLowerCase().endsWith('.pdf') ? 'pdf' : 'jpg';
    final path = '$userId/${docType}_${_uuid.v4()}.$ext';
    await SupabaseService.storage.from(SupabaseConstants.bucketDocuments).upload(
      path,
      file,
      fileOptions: FileOptions(
        contentType: ext == 'pdf' ? 'application/pdf' : 'image/jpeg',
        upsert: false,
      ),
    );
    return await SupabaseService.storage
        .from(SupabaseConstants.bucketDocuments)
        .createSignedUrl(path, 60 * 60 * 24 * 365);
  }

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

    final existing = await SupabaseService.client
        .from(SupabaseConstants.documents)
        .select('id')
        .eq('profile_id', userId)
        .eq('doc_type', docType)
        .eq('file_hash', hash)
        .maybeSingle();

    if (existing != null) return;

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
