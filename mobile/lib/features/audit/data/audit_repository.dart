import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

/// Append-only audit log. Failures are swallowed — never crash the app
/// because an audit write fails.
class AuditRepository {
  AuditRepository._();
  static final instance = AuditRepository._();

  Future<void> logEvent({
    required String actorId,
    required String eventType,
    String? targetId,
    String? targetTable,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await SupabaseService.client.from(SupabaseConstants.auditLog).insert({
        'actor_id': actorId,
        'event_type': eventType,
        if (targetId != null) 'target_id': targetId,
        if (targetTable != null) 'target_table': targetTable,
        if (payload != null) 'payload': payload,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (_) {
      // Audit log must never interrupt normal app flow.
    }
  }
}
