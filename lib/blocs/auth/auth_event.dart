import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {}
class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  const AuthLoginRequested(this.email, this.password);
  @override List<Object?> get props => [email, password];
}
class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String username;
  final String? fullName;
  const AuthRegisterRequested({required this.email, required this.password, required this.username, this.fullName});
  @override List<Object?> get props => [email, password, username, fullName];
}
class AuthLogoutRequested extends AuthEvent {}
class AuthProfileUpdateRequested extends AuthEvent {
  final String userId;
  final String? fullName;
  final String? bio;
  const AuthProfileUpdateRequested(this.userId, {this.fullName, this.bio});
  @override List<Object?> get props => [userId, fullName, bio];
}
class AuthAvatarUpdateRequested extends AuthEvent {
  final String userId;
  final String avatarUrl;
  const AuthAvatarUpdateRequested(this.userId, this.avatarUrl);
  @override List<Object?> get props => [userId, avatarUrl];
}
