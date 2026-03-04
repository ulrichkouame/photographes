/// Supabase authentication repository: OTP, PIN, session management.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides authentication operations backed by Supabase.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  SupabaseClient get client => _client;

  /// Sends a WhatsApp OTP to [phoneNumber] via Supabase phone auth.
  Future<void> sendOtp(String phoneNumber) async {
    await _client.auth.signInWithOtp(phone: phoneNumber);
  }

  /// Verifies the [otp] sent to [phone]. Returns the [AuthResponse].
  Future<AuthResponse> verifyOtp(String phone, String otp) async {
    final response = await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );
    return response;
  }

  /// Stores the user's 4-digit [pin] hashed in the profiles table.
  Future<void> setPin(String pin) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Utilisateur non connecté');
    // Store hashed pin representation (simple base64 for demo; use bcrypt in prod)
    final pinHash = _hashPin(pin);
    await _client.from('profiles').upsert({
      'id': userId,
      'pin_hash': pinHash,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Returns `true` if the provided [pin] matches the stored hash.
  Future<bool> verifyPin(String pin) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;
    final data = await _client
        .from('profiles')
        .select('pin_hash')
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return false;
    final stored = data['pin_hash'] as String?;
    return stored != null && stored == _hashPin(pin);
  }

  /// Signs out the current session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Returns the currently authenticated [User], or `null`.
  User? getCurrentUser() => _client.auth.currentUser;

  /// Streams auth state changes.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _hashPin(String pin) {
    // Simple deterministic hash; replace with server-side bcrypt in production.
    final bytes = pin.codeUnits;
    int hash = 0;
    for (final b in bytes) {
      hash = (hash * 31 + b) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
