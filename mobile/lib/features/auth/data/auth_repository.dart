import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ruedaseguro/core/services/supabase_service.dart';
import 'package:ruedaseguro/core/constants/supabase_constants.dart';

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  Future<void> signInWithOtp(String phone) async {
    await SupabaseService.auth.signInWithOtp(phone: phone);
  }

  Future<Session?> verifyOtp(String phone, String token) async {
    final response = await SupabaseService.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
    return response.session;
  }

  /// Dev-only: sign in anonymously to test the onboarding flow without SMS.
  Future<void> signInAnonymously() async {
    await SupabaseService.auth.signInAnonymously();
  }

  Future<void> signOut() async {
    await SupabaseService.auth.signOut();
  }

  Session? getCurrentSession() => SupabaseService.auth.currentSession;

  User? getCurrentUser() => SupabaseService.auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      SupabaseService.auth.onAuthStateChange;

  Future<bool> profileExists() async {
    final user = SupabaseService.auth.currentUser;
    if (user == null) return false;
    final result = await SupabaseService.client
        .from(SupabaseConstants.profiles)
        .select('id')
        .eq('id', user.id)
        .maybeSingle();
    return result != null;
  }
}
