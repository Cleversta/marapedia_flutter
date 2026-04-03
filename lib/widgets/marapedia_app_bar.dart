import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../utils/app_theme.dart';

class MarapediaAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showSearch;
  const MarapediaAppBar({super.key, this.showSearch = true});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  State<MarapediaAppBar> createState() => _MarapediaAppBarState();
}

class _MarapediaAppBarState extends State<MarapediaAppBar> {
  bool _searching = false;
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submitSearch() {
    if (_ctrl.text.trim().isNotEmpty) {
      context.push('/search?q=${Uri.encodeComponent(_ctrl.text.trim())}');
      setState(() {
        _searching = false;
        _ctrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black12,
      leadingWidth: _searching ? 56 : 160,
      leading: _searching
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => setState(() {
                _searching = false;
                _ctrl.clear();
              }),
            )
          : GestureDetector(
              onTap: () => context.go('/'),
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppTheme.greenBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'M',
                          style: TextStyle(
                            color: AppTheme.greenPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                        children: [
                          TextSpan(text: 'Mara'),
                          TextSpan(
                            text: 'pedia',
                            style: TextStyle(color: AppTheme.greenPrimary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      title: _searching
          ? TextField(
              controller: _ctrl,
              autofocus: true,
              autofillHints: const [],
              enableIMEPersonalizedLearning: false,
              decoration: const InputDecoration(
                hintText: 'Search the encyclopedia...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _submitSearch(),
            )
          : null,
      actions: [
        if (widget.showSearch && !_searching)
          IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
            onPressed: () => setState(() => _searching = true),
          ),
        if (!_searching)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated) {
                return PopupMenuButton<String>(
                  offset: const Offset(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildAvatar(state),
                  ),
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'profile',
                      child: Row(children: [
                        Icon(Icons.person_outline, size: 18),
                        SizedBox(width: 8),
                        Text('My Profile'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'articles',
                      child: Row(children: [
                        Icon(Icons.article_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('My Articles'),
                      ]),
                    ),
                    if (state.profile.isEditor)
                      const PopupMenuItem(
                        value: 'editor',
                        child: Row(children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Editor Panel'),
                        ]),
                      ),
                    if (state.profile.isAdmin)
                      const PopupMenuItem(
                        value: 'admin',
                        child: Row(children: [
                          Icon(Icons.admin_panel_settings_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Admin Panel'),
                        ]),
                      ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'logout',
                      child: Row(children: [
                        Icon(Icons.logout, size: 18, color: Colors.red[400]),
                        const SizedBox(width: 8),
                        Text('Sign out', style: TextStyle(color: Colors.red[400])),
                      ]),
                    ),
                  ],
                  onSelected: (val) {
                    switch (val) {
                      case 'profile': context.push('/profile'); break;
                      case 'articles': context.push('/my-articles'); break;
                      case 'editor': context.push('/editor'); break;
                      case 'admin': context.push('/admin'); break;
                      case 'logout':
                        context.read<AuthBloc>().add(AuthLogoutRequested());
                        context.go('/');
                        break;
                    }
                  },
                );
              }
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Sign in'),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ElevatedButton(
                      onPressed: () => context.push('/register'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Register', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
              );
            },
          ),
        if (_searching)
          IconButton(icon: const Icon(Icons.search), onPressed: _submitSearch),
      ],
    );
  }

  Widget _buildAvatar(AuthAuthenticated state) {
    final url = state.profile.avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: AppTheme.greenLight,
        backgroundImage: NetworkImage(url),
        onBackgroundImageError: (_, __) {},
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppTheme.greenLight,
      child: Text(
        state.profile.username[0].toUpperCase(),
        style: const TextStyle(
          color: AppTheme.greenDark,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}