import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../../repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repo;

  AuthBloc(this._repo) : super(AuthInitial()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdateRequested>(_onProfileUpdate);
    on<AuthAvatarUpdateRequested>(_onAvatarUpdate);
  }

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final profile = await _repo.fetchProfile(user.id);
        if (profile != null) {
          emit(
            AuthAuthenticated(
              userId: user.id,
              email: user.email ?? '',
              profile: profile,
            ),
          );
          return;
        }
      }
      // Try auto-login from saved credentials
      await _repo.tryAutoLogin();
      final user2 = Supabase.instance.client.auth.currentUser;
      if (user2 != null) {
        final profile = await _repo.fetchProfile(user2.id);
        if (profile != null) {
          emit(
            AuthAuthenticated(
              userId: user2.id,
              email: user2.email ?? '',
              profile: profile,
            ),
          );
          return;
        }
      }
      emit(AuthUnauthenticated());
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final profile = await _repo.signIn(event.email, event.password);
      final user = Supabase.instance.client.auth.currentUser!;
      if (profile != null) {
        emit(
          AuthAuthenticated(
            userId: user.id,
            email: user.email ?? '',
            profile: profile,
          ),
        );
      } else {
        emit(const AuthError('Profile not found'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegister(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final profile = await _repo.signUp(
        email: event.email,
        password: event.password,
        username: event.username,
        fullName: event.fullName,
      );
      if (profile != null) {
        final user = Supabase.instance.client.auth.currentUser!;
        emit(
          AuthAuthenticated(
            userId: user.id,
            email: user.email ?? '',
            profile: profile,
          ),
        );
      } else {
        emit(
          const AuthEmailConfirmationRequired(
            'Account created! Please check your email to confirm before signing in.',
          ),
        );
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogout(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _repo.signOut();
    emit(AuthUnauthenticated());
  }

  Future<void> _onProfileUpdate(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;
    try {
      final profile = await _repo.updateProfile(
        event.userId,
        fullName: event.fullName,
        bio: event.bio,
      );
      if (profile != null) {
        emit(
          AuthProfileUpdated(
            userId: current.userId,
            email: current.email,
            profile: profile,
          ),
        );
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onAvatarUpdate(
    AuthAvatarUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    final current = state as AuthAuthenticated;
    try {
      final profile = await _repo.updateAvatar(event.userId, event.avatarUrl);
      if (profile != null) {
        emit(
          AuthProfileUpdated(
            userId: current.userId,
            email: current.email,
            profile: profile,
          ),
        );
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
