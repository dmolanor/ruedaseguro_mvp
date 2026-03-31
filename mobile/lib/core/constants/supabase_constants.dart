class SupabaseConstants {
  SupabaseConstants._();

  // Tables
  static const String carriers = 'carriers';
  static const String carrierUsers = 'carrier_users';
  static const String brokers = 'brokers';
  static const String promoters = 'promoters';
  static const String pointsOfSale = 'points_of_sale';
  static const String profiles = 'profiles';
  static const String vehicles = 'vehicles';
  static const String policyTypes = 'policy_types';
  static const String policies = 'policies';
  static const String payments = 'payments';
  static const String claims = 'claims';
  static const String claimEvidence = 'claim_evidence';
  static const String documents = 'documents';
  static const String exchangeRates = 'exchange_rates';
  static const String auditLog = 'audit_log';

  // Storage buckets
  static const String bucketDocuments = 'documents';
  static const String bucketPolicies = 'policies';
  static const String bucketReceipts = 'receipts';
  static const String bucketPublic = 'public';

  // Sprint 3 tables
  static const String tickets = 'tickets';
  static const String ticketComments = 'ticket_comments';
  static const String telemetryEvents = 'telemetry_events';
  static const String carrierApiConfig = 'carrier_api_config';

  // Edge functions
  static const String fnBcvRate = 'bcv-rate';
  static const String fnPolicyRetry = 'policy-retry';
  static const String fnRenewalReminder = 'renewal-reminder';
}
