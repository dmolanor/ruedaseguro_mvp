import 'package:flutter_test/flutter_test.dart';
import 'package:ruedaseguro/features/policy/data/policy_issuance_service.dart';

void main() {
  group('IssuanceResult.confirmed', () {
    test('isConfirmed is true', () {
      final r = IssuanceResult.confirmed(policyNumber: 'STUB-ABC-001');
      expect(r.isConfirmed, isTrue);
    });

    test('carrierPolicyNumber carries the provided number', () {
      final r = IssuanceResult.confirmed(policyNumber: 'STUB-ABC-001');
      expect(r.carrierPolicyNumber, 'STUB-ABC-001');
    });

    test('outcome is IssuanceOutcome.confirmed', () {
      final r = IssuanceResult.confirmed(policyNumber: 'X');
      expect(r.outcome, IssuanceOutcome.confirmed);
    });

    test('errorMessage is null', () {
      final r = IssuanceResult.confirmed(policyNumber: 'X');
      expect(r.errorMessage, isNull);
    });
  });

  group('IssuanceResult.provisional', () {
    test('isConfirmed is false', () {
      final r = IssuanceResult.provisional(reason: 'timeout');
      expect(r.isConfirmed, isFalse);
    });

    test('outcome is IssuanceOutcome.provisional', () {
      final r = IssuanceResult.provisional();
      expect(r.outcome, IssuanceOutcome.provisional);
    });

    test('errorMessage carries the provided reason', () {
      final r = IssuanceResult.provisional(reason: 'carrier unreachable');
      expect(r.errorMessage, 'carrier unreachable');
    });

    test('errorMessage is null when no reason provided', () {
      final r = IssuanceResult.provisional();
      expect(r.errorMessage, isNull);
    });

    test('carrierPolicyNumber is null', () {
      final r = IssuanceResult.provisional(reason: 'timeout');
      expect(r.carrierPolicyNumber, isNull);
    });
  });
}
