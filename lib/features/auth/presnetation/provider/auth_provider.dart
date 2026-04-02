import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;

  AuthStatus _status = AuthStatus.initial;
  String _errorMessage = '';

  AuthStatus get status => _status;
  String get errorMessage => _errorMessage;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String get userDisplayName =>
      currentUser?.userMetadata?['name'] as String? ??
      currentUser?.email?.split('@').first ??
      'User';

  // ── Stream for _AuthGate ──────────────────────────
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  // ── Login ─────────────────────────────────────────
  Future<bool> login(String email, String password) async {
    _setLoading();
    try {
      await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Login failed. Please try again.');
      return false;
    }
  }

  // ── Register ──────────────────────────────────────
  Future<bool> register(String name, String email, String password) async {
    _setLoading();
    try {
      await _client.auth.signUp(
        email: email.trim(),
        password: password.trim(),
        data: {'name': name}, // stored in user_metadata
      );

      // Save user profile to users table
      final uid = _client.auth.currentUser?.id;
      if (uid != null) {
        await _client.from('users').upsert({
          'id': uid,
          'name': name,
          'email': email.trim(),
          'is_dealer': false,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Registration failed. Please try again.');
      return false;
    }
  }

  // ── Logout ────────────────────────────────────────
  Future<void> logout() async {
    await _client.auth.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // ── Forgot password ───────────────────────────────
  Future<bool> sendPasswordResetEmail(String email) async {
    _setLoading();
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      _status = AuthStatus.initial;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    }
  }

  // ── Helpers ───────────────────────────────────────
  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = '';
    notifyListeners();
  }

  void _setError(String msg) {
    _status = AuthStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = '';
    _status = isLoggedIn
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }
}
