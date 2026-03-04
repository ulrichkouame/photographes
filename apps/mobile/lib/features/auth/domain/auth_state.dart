/// Sealed auth state used by [AuthNotifier].
library;

import 'package:supabase_flutter/supabase_flutter.dart';

/// Represents the current authentication state of the application.
sealed class AuthState {
  const AuthState();
}

/// Initial state before any auth check.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Auth operation is in progress.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// A valid session exists.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final User user;
}

/// No active session.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed.
final class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
