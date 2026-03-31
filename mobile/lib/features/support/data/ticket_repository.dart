// RS-068 — In-app ticket creation.

import 'package:uuid/uuid.dart';

import 'package:ruedaseguro/core/constants/supabase_constants.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';

class TicketRepository {
  TicketRepository._();
  static final instance = TicketRepository._();

  final _uuid = const Uuid();

  /// Creates a support ticket for a rider and returns (ticketId, ticketNumber).
  Future<({String ticketId, String ticketNumber})> createTicket({
    required String profileId,
    required String subject,
    required String description,
    required String priority, // 'critical' | 'high' | 'medium' | 'low'
    String? policyId,
    String? paymentId,
  }) async {
    final ticketId = _uuid.v4();
    final shortId = ticketId.substring(0, 6).toUpperCase();
    final ticketNumber = 'TKT-${DateTime.now().year}-$shortId';

    await SupabaseService.client.from(SupabaseConstants.tickets).insert({
      'id': ticketId,
      'entity_type': 'rider',
      'entity_id': profileId,
      'rider_id': profileId,
      if (policyId != null) 'policy_id': policyId,
      if (paymentId != null) 'payment_id': paymentId,
      'subject': subject,
      'description': description,
      'priority': priority,
      'status': 'open',
    });

    return (ticketId: ticketId, ticketNumber: ticketNumber);
  }

  /// Fetches open tickets for the current rider.
  Future<List<Map<String, dynamic>>> fetchRiderTickets(String profileId) async {
    final rows = await SupabaseService.client
        .from(SupabaseConstants.tickets)
        .select('id, subject, priority, status, created_at')
        .eq('rider_id', profileId)
        .isFilter('archived_at', null)
        .order('created_at', ascending: false)
        .limit(20);
    return (rows as List).cast<Map<String, dynamic>>();
  }
}
