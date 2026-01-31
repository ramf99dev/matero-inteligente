import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream of auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      AppLogger.info('✅ Usuario logueado: ${response.user?.email}');
      return response;
    } catch (e) {
      AppLogger.error('❌ Error al iniciar sesión', e);
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      AppLogger.info('✅ Usuario registrado: ${response.user?.email}');
      return response;
    } catch (e) {
      AppLogger.error('❌ Error al registrarse', e);
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      AppLogger.info('👋 Usuario cerró sesión');
    } catch (e) {
      AppLogger.error('❌ Error al cerrar sesión', e);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      AppLogger.info('📧 Enlace de reseteo enviado a: $email');
    } catch (e) {
      AppLogger.error('❌ Error al enviar reset de contraseña', e);
      rethrow;
    }
  }
}
