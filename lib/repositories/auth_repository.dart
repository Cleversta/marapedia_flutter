import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    final updates = <String, dynamic>{};
    if (fullName != null) updates['full_name'] = fullName;
    if (bio != null) updates['bio'] = bio;
    if (updates.isNotEmpty) {
      await _db.from('profiles').update(updates).eq('id', userId);
    }
    return fetchProfile(userId);
  }

  Future<ProfileModel?> updateAvatar(String userId, String avatarUrl) async {
    await _db.from('profiles').update({'avatar_url': avatarUrl}).eq('id', userId);
    return fetchProfile(userId);
  }

  Future<ProfileModel?> signInWithGoogle() async {
    final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID']!;
    final googleSignIn = GoogleSignIn(serverClientId: webClientId);
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelled');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) throw Exception('Failed to get Google ID token');

    final res = await _auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: googleAuth.accessToken,
    );
    if (res.user == null) throw Exception('Google sign-in failed');
    return fetchProfile(res.user!.id);
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
