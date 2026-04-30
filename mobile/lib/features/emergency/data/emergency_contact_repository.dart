import 'package:ruedaseguro/core/services/supabase_service.dart';

/// Represents a trusted emergency contact stored in Supabase.
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.profileId,
    required this.fullName,
    required this.phone,
    this.relation,
    required this.isPrimary,
  });

  final String id;
  final String profileId;
  final String fullName;
  final String phone;
  final String?
  relation; // 'madre' | 'padre' | 'pareja' | 'hijo_a' | 'hermano_a' | 'amigo_a' | 'otro'
  final bool isPrimary;

  static const relationLabels = {
    'madre': 'Mamá',
    'padre': 'Papá',
    'pareja': 'Pareja',
    'hijo_a': 'Hijo/a',
    'hermano_a': 'Hermano/a',
    'amigo_a': 'Amigo/a',
    'otro': 'Otro',
  };

  String get relationLabel => relation != null
      ? relationLabels[relation] ?? relation!
      : 'Sin especificar';

  factory EmergencyContact.fromMap(Map<String, dynamic> m) => EmergencyContact(
    id: m['id'] as String,
    profileId: m['profile_id'] as String,
    fullName: m['full_name'] as String,
    phone: m['phone'] as String,
    relation: m['relation'] as String?,
    isPrimary: m['is_primary'] as bool? ?? false,
  );

  Map<String, dynamic> toInsertMap(String profileId) => {
    'profile_id': profileId,
    'full_name': fullName,
    'phone': phone,
    'relation': relation,
    'is_primary': isPrimary,
  };
}

class EmergencyContactRepository {
  EmergencyContactRepository._();
  static final instance = EmergencyContactRepository._();

  Future<List<EmergencyContact>> fetchAll(String profileId) async {
    final rows = await SupabaseService.client
        .from('emergency_contacts')
        .select()
        .eq('profile_id', profileId)
        .order('is_primary', ascending: false)
        .order('created_at');
    return (rows as List).map((r) => EmergencyContact.fromMap(r)).toList();
  }

  Future<EmergencyContact> insert(EmergencyContact contact) async {
    final profileId = SupabaseService.auth.currentUser!.id;

    // If this will be primary, demote existing primary first
    if (contact.isPrimary) {
      await SupabaseService.client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('profile_id', profileId)
          .eq('is_primary', true);
    }

    final row = await SupabaseService.client
        .from('emergency_contacts')
        .insert(contact.toInsertMap(profileId))
        .select()
        .single();
    return EmergencyContact.fromMap(row);
  }

  Future<EmergencyContact> update(EmergencyContact contact) async {
    final profileId = SupabaseService.auth.currentUser!.id;

    if (contact.isPrimary) {
      await SupabaseService.client
          .from('emergency_contacts')
          .update({'is_primary': false})
          .eq('profile_id', profileId)
          .eq('is_primary', true)
          .neq('id', contact.id);
    }

    final row = await SupabaseService.client
        .from('emergency_contacts')
        .update({
          'full_name': contact.fullName,
          'phone': contact.phone,
          'relation': contact.relation,
          'is_primary': contact.isPrimary,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', contact.id)
        .select()
        .single();
    return EmergencyContact.fromMap(row);
  }

  Future<void> delete(String id) async {
    await SupabaseService.client
        .from('emergency_contacts')
        .delete()
        .eq('id', id);
  }

  /// Returns true if the profile has at least one emergency contact.
  Future<bool> hasContacts(String profileId) async {
    final rows = await SupabaseService.client
        .from('emergency_contacts')
        .select('id')
        .eq('profile_id', profileId)
        .limit(1);
    return (rows as List).isNotEmpty;
  }
}
