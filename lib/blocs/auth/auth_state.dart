import 'package:equatable/equatable.dart';
import '../../models/profile_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final ProfileModel profile;
  const AuthAuthenticated({required this.userId, required this.email, required this.profile});
  @override List<Object?> get props => [userId, email, profile];
}

class AuthUnauthenticated extends AuthState {}

class AuthNeedsUsername extends AuthState {
  final String userId;
  final String? fullName;
  const AuthNeedsUsername({required this.userId, this.fullName});
  @override List<Object?> get props => [userId, fullName];
}

class AuthEmailConfirmationRequired extends AuthState {
  final String message;
  const AuthEmailConfirmationRequired(this.message);
  @override List<Object?> get props => [message];
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override List<Object?> get props => [message];
}

class AuthProfileUpdated extends AuthAuthenticated {
  const AuthProfileUpdated({required super.userId, required super.email, required super.profile});
}
