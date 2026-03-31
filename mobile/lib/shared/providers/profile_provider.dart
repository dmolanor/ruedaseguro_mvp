import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

// ─── Profile ─────────────────────────────────────────────────────

class ProfileSummary {
  final String id;
  final String firstName;
  final String lastName;
  final String idType;
  final String idNumber;
  final String phone;
  // Extended fields for the profile screen
  final String? dateOfBirth;
  final String? ciudad;
  final String? estado;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? emergencyRelation;

  const ProfileSummary({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.idType,
    required this.idNumber,
    required this.phone,
    this.dateOfBirth,
    this.ciudad,
    this.estado,
    this.emergencyName,
    this.emergencyPhone,
    this.emergencyRelation,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory ProfileSummary.fromMap(Map<String, dynamic> m) => ProfileSummary(
        id: m['id'] as String,
        firstName: m['first_name'] as String? ?? '',
        lastName: m['last_name'] as String? ?? '',
        idType: m['id_type'] as String? ?? 'V',
        idNumber: m['id_number'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
        dateOfBirth: m['date_of_birth'] as String?,
        ciudad: m['ciudad'] as String?,
        estado: m['estado'] as String?,
        emergencyName: m['emergency_name'] as String?,
        emergencyPhone: m['emergency_phone'] as String?,
        emergencyRelation: m['emergency_relation'] as String?,
      );
}

final profileProvider = FutureProvider<ProfileSummary?>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return null;

  final row = await SupabaseService.client
      .from('profiles')
      .select(
        'id, first_name, last_name, id_type, id_number, phone, '
        'date_of_birth, ciudad, estado, '
        'emergency_name, emergency_phone, emergency_relation',
      )
      .eq('id', userId)
      .maybeSingle();

  if (row == null) return null;
  return ProfileSummary.fromMap(row as Map<String, dynamic>);
});

// ─── Vehicle ─────────────────────────────────────────────────────

class VehicleSummary {
  final String id;
  final String brand;
  final String model;
  final int year;
  final String plate;
  final String color;
  final String? serialMotor;

  const VehicleSummary({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.plate,
    required this.color,
    this.serialMotor,
  });

  factory VehicleSummary.fromMap(Map<String, dynamic> m) => VehicleSummary(
        id: m['id'] as String,
        brand: m['brand'] as String? ?? '',
        model: m['model'] as String? ?? '',
        year: m['year'] as int? ?? 0,
        plate: m['plate'] as String? ?? '',
        color: m['color'] as String? ?? '',
        serialMotor: m['serial_motor'] as String?,
      );
}

final vehicleProvider = FutureProvider<VehicleSummary?>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return null;

  final row = await SupabaseService.client
      .from('vehicles')
      .select('id, brand, model, year, plate, color, serial_motor')
      .eq('owner_id', userId)
      .maybeSingle();

  if (row == null) return null;
  return VehicleSummary.fromMap(row as Map<String, dynamic>);
});
