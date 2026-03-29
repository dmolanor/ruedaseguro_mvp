import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/shared/providers/auth_provider.dart';

class ProfileSummary {
  final String id;
  final String fullName;
  final String idType;
  final String idNumber;
  final String phone;

  const ProfileSummary({
    required this.id,
    required this.fullName,
    required this.idType,
    required this.idNumber,
    required this.phone,
  });

  String get firstName => fullName.split(' ').first;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  factory ProfileSummary.fromMap(Map<String, dynamic> m) => ProfileSummary(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        idType: m['id_type'] as String? ?? 'V',
        idNumber: m['id_number'] as String? ?? '',
        phone: m['phone'] as String? ?? '',
      );
}

final profileProvider = FutureProvider<ProfileSummary?>((ref) async {
  final auth = ref.watch(authProvider);
  final userId = auth.user?.id;
  if (userId == null) return null;

  final row = await SupabaseService.client
      .from('profiles')
      .select('id, full_name, id_type, id_number, phone')
      .eq('id', userId)
      .maybeSingle();

  if (row == null) return null;
  return ProfileSummary.fromMap(row as Map<String, dynamic>);
});
