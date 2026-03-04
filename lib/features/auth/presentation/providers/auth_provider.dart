/// Riverpod providers for authentication state management.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../data/auth_repository.dart';
import '../../domain/auth_state.dart';

/// Provides a singleton [AuthRepository].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(sb.Supabase.instance.client);
});

/// [StateNotifier] that drives authentication flows.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial()) {
    _init();
  }

  final AuthRepository _repo;

  void _init() {
    final user = _repo.getCurrentUser();
    if (user != null) {
      state = AuthAuthenticated(user);
    } else {
      state = const AuthUnauthenticated();
    }
    _repo.authStateChanges.listen((event) {
      final u = event.session?.user;
      if (u != null) {
        state = AuthAuthenticated(u);
      } else {
        state = const AuthUnauthenticated();
      }
    });
  }

  /// Sends a WhatsApp OTP to the given [phoneNumber].
  Future<void> sendOtp(String phoneNumber) async {
    state = const AuthLoading();
    try {
      await _repo.sendOtp(phoneNumber);
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Verifies the [otp] for [phone].
  Future<bool> verifyOtp(String phone, String otp) async {
    state = const AuthLoading();
    try {
      final response = await _repo.verifyOtp(phone, otp);
      if (response.user != null) {
        state = AuthAuthenticated(response.user!);
        return true;
      }
      state = const AuthUnauthenticated();
      return false;
    } catch (e) {
      state = AuthError(e.toString());
      return false;
    }
  }

  /// Sets up the 4-digit PIN for the current user.
  Future<void> setPin(String pin) async {
    state = const AuthLoading();
    try {
      await _repo.setPin(pin);
      final user = _repo.getCurrentUser();
      if (user != null) state = AuthAuthenticated(user);
    } catch (e) {
      state = AuthError(e.toString());
    }
  }

  /// Returns `true` if [pin] matches the stored PIN.
  Future<bool> verifyPin(String pin) async {
    return _repo.verifyPin(pin);
  }

  /// Signs out the current user.
  Future<void> signOut() async {
    state = const AuthLoading();
    try {
      await _repo.signOut();
      state = const AuthUnauthenticated();
    } catch (e) {
      state = AuthError(e.toString());
    }
  }
}

/// StateNotifierProvider for [AuthNotifier].
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
