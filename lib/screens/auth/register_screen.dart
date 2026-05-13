import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../utils/app_theme.dart';
import '../../widgets/google_sign_in_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _usernameCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passCtrl     = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _usernameCtrl.dispose(); _fullNameCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final pass     = _passCtrl.text;
    if (username.isEmpty || email.isEmpty || pass.isEmpty) return;
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password must be at least 6 characters'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterRequested(
      email: email, password: pass, username: username,
      fullName: _fullNameCtrl.text.trim().isEmpty ? null : _fullNameCtrl.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) context.go('/');
          if (state is AuthNeedsUsername) context.go('/complete-profile');
          if (state is AuthEmailConfirmationRequired) {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Check your email'),
                content: Text(state.message),
                actions: [TextButton(
                  onPressed: () { Navigator.pop(context); context.go('/login'); },
                  child: const Text('Go to Login'),
                )],
              ),
            );
          }
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red[700]),
            );
          }
        },
        builder: (context, state) {
          final loading = state is AuthLoading;
          return SafeArea(
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
                      const Text('Join Marapedia', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Help preserve Mara history and culture', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                      const SizedBox(height: 20),
                      GoogleSignInButton(
                        onPressed: loading ? null : () =>
                          context.read<AuthBloc>().add(AuthGoogleLoginRequested()),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or sign up with email', style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                        ),
                        const Expanded(child: Divider()),
                      ]),
                      const SizedBox(height: 12),
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
                            Row(children: [
                              Expanded(child: _field('Username *', _usernameCtrl, 'marauser01', TextInputType.text)),
                              const SizedBox(width: 12),
                              Expanded(child: _field('Full Name', _fullNameCtrl, 'Your name', TextInputType.name)),
                            ]),
                            const SizedBox(height: 14),
                            _field('Email *', _emailCtrl, 'you@email.com', TextInputType.emailAddress),
                            const SizedBox(height: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Password *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  onSubmitted: (_) => _submit(),
                                  decoration: InputDecoration(
                                    hintText: 'At least 6 characters',
                                    prefixIcon: const Icon(Icons.lock_outline, size: 18),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 18),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 46,
                              child: ElevatedButton(
                                onPressed: loading ? null : _submit,
                                child: loading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Create account', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text('Already have an account? ', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                        GestureDetector(
                          onTap: () => context.push('/login'),
                          child: const Text('Sign in', style: TextStyle(color: AppTheme.greenPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String hint, TextInputType type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        TextField(controller: ctrl, keyboardType: type, textInputAction: TextInputAction.next,
          decoration: InputDecoration(hintText: hint)),
      ],
    );
  }
}
