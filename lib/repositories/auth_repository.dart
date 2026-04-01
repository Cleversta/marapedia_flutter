import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../services/secure_storage_service.dart';

class AuthRepository {
  final _auth = Supabase.instance.client.auth;
  final _db   = Supabase.instance.client;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<ProfileModel?> signIn(String email, String password) async {
    final res = await _auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Login failed');
    await SecureStorageService.saveCredentials(email, password);
    return fetchProfile(res.user!.id);
  }

  Future<ProfileModel?> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
  }) async {
    // Check username uniqueness
    final existing = await _db.from('profiles')
      .select('id')
      .eq('username', username.trim())
      .maybeSingle();
    if (existing != null) throw Exception('Username already taken.');

    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'username': username.trim().toLowerCase(), 'full_name': fullName?.trim()},
    );
    if (res.user == null) throw Exception('Registration failed');
    if (res.user!.identities?.isEmpty == true) throw Exception('Email already registered.');

    await SecureStorageService.saveCredentials(email, password);
    if (res.session != null) return fetchProfile(res.user!.id);
    return null; // email confirmation needed
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await SecureStorageService.clearAll();
  }

  Future<ProfileModel?> fetchProfile(String userId) async {
    final res = await _db.from('profiles').select('*').eq('id', userId).maybeSingle();
    if (res == null) return null;
    return ProfileModel.fromJson(Map<String, dynamic>.from(res));
  }

  Future<ProfileModel?> updateProfile(String userId, {String? fullName, String? bio}) async {
    await _db.from('profiles').update({
      if (fullName != null) 'full_name': fullName,
      if (bio != null) 'bio': bio,
    }).eq('id', userId);
    return fetchProfile(userId);
  }

  Future<ProfileModel?> updateAvatar(String userId, String avatarUrl) async {
    await _db.from('profiles').update({'avatar_url': avatarUrl}).eq('id', userId);
    return fetchProfile(userId);
  }

  Future<void> tryAutoLogin() async {
    final creds = await SecureStorageService.getCredentials();
    final email = creds['email'];
    final password = creds['password'];
    if (email != null && password != null) {
      await _auth.signInWithPassword(email: email, password: password);
    }
  }
}
