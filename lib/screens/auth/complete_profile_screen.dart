import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_state.dart';
import '../../utils/app_theme.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});
  @override State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<AuthBloc>().state;
    if (state is AuthNeedsUsername && state.fullName != null) {
      _fullNameCtrl.text = state.fullName!;
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameCtrl.text.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(username)) {
      setState(() => _error = 'Username must be 3–20 characters: letters, numbers, underscores only.');
      return;
    }

    setState(() { _loading = true; _error = ''; });

    final db = Supabase.instance.client;
    final userId = Supabase.instance.client.auth.currentUser!.id;

    final existing = await db.from('profiles').select('id').eq('username', username).maybeSingle();
    if (existing != null) {
      setState(() { _loading = false; _error = 'Username already taken. Please choose another.'; });
      return;
    }

    final err = await db.from('profiles').upsert({
      'id': userId,
      'username': username,
      'full_name': _fullNameCtrl.text.trim(),
      'role': 'contributor',
    }).then((_) => null, onError: (e) => e.toString());

    if (err != null) {
      setState(() { _loading = false; _error = err; });
    } else {
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: AppTheme.greenBg, borderRadius: BorderRadius.circular(16)),
                    child: const Center(child: Text('M', style: TextStyle(color: AppTheme.greenPrimary, fontWeight: FontWeight.w900, fontSize: 32))),
                  ),
                  const SizedBox(height: 16),
                  const Text('Almost done!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Choose your username', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.greenPrimary)),
                  const SizedBox(height: 4),
                  Text('Set a username to complete your Marapedia profile', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                            child: Text(_error, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                          ),
                        const Text('Username *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _usernameCtrl,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          decoration: const InputDecoration(
                            hintText: 'marauser01',
                            prefixIcon: Icon(Icons.alternate_email, size: 18),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('3–20 characters, letters, numbers, underscores only', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                        const SizedBox(height: 16),
                        const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _fullNameCtrl,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            hintText: 'Your name',
                            prefixIcon: Icon(Icons.person_outline, size: 18),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Complete profile', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
