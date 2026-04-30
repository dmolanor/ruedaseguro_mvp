// RS-067 — Real claim submission with Supabase storage photo upload.

import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

class ClaimRepository {
  ClaimRepository._();
  static final instance = ClaimRepository._();

  final _uuid = const Uuid();

  /// Creates a claim record and returns (claimId, claimNumber).
  Future<({String claimId, String claimNumber})> createClaim({
    required String profileId,
    required String policyId,
    required String incidentType,
    required String description,
    String? location,
    bool hasInjuries = false,
    DateTime? incidentAt,
  }) async {
    final claimId = _uuid.v4();
    final now = DateTime.now().toUtc();
    final shortId = claimId.substring(0, 6).toUpperCase();
    final claimNumber = 'SIN-${now.year}-$shortId';

    await SupabaseService.client.from(SupabaseConstants.claims).insert({
      'id': claimId,
      'profile_id': profileId,
      'policy_id': policyId,
      'claim_number': claimNumber,
      'incident_type': incidentType,
      'incident_description': description,
      if (location != null && location.isNotEmpty) 'incident_address': location,
      'has_injuries': hasInjuries,
      'incident_date': (incidentAt ?? now).toIso8601String(),
      'status': 'reported',
    });

    return (claimId: claimId, claimNumber: claimNumber);
  }

  /// Returns claims for the given profile, newest first.
  Future<List<Map<String, dynamic>>> fetchClaims(String profileId) async {
    final rows = await SupabaseService.client
        .from(SupabaseConstants.claims)
        .select(
          'id, claim_number, incident_type, status, created_at, incident_description',
        )
        .eq('profile_id', profileId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// Uploads a photo file to Supabase Storage and inserts a claim_evidence row.
  /// Path: receipts/{userId}/claims/{claimId}/{index}.{ext}
  /// Matches the existing RLS policy that scopes by auth.uid() as first folder segment.
  /// Returns the public URL of the uploaded file.
  Future<String> uploadClaimPhoto({
    required String userId,
    required String claimId,
    required File photoFile,
    required int index,
  }) async {
    final ext = photoFile.path.split('.').last.toLowerCase();
    final storagePath = '$userId/claims/$claimId/$index.$ext';

    await SupabaseService.client.storage
        .from(SupabaseConstants.bucketReceipts)
        .upload(storagePath, photoFile, fileOptions: FileOptions(upsert: true));

    final publicUrl = SupabaseService.client.storage
        .from(SupabaseConstants.bucketReceipts)
        .getPublicUrl(storagePath);

    await SupabaseService.client.from(SupabaseConstants.claimEvidence).insert({
      'id': _uuid.v4(),
      'claim_id': claimId,
      'file_type': 'photo',
      'file_url': publicUrl,
    });

    return publicUrl;
  }
}
