// Hallmark · v2.0.0 · screen: Login (hero) · theme Ink · genre editorial
// Floor: stamp line first, tokens only, focus-visible on interactives, reduced-motion aware, ≤80 words/screen, centred capped container, no invented metrics.

import 'package:flutter/material.dart';

import '../api.dart';
import '../auth_store.dart';
import '../main.dart';
import '../widgets/app_theme.dart';

/// Sign-in / account creation hero. One idea per screen: prove identity, enter
/// the academic dashboard. All copy under 80 words; every field visible without
/// scrolling on a small phone.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  final _focusName = FocusNode();

  bool _isLogin = true;
  String _role = 'student';
  bool _busy = false;
  String? _error;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _focusEmail.dispose();
    _focusPassword.dispose();
    _focusName.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final data = _isLogin
          ? await apiPost('/api/auth/login', body: {
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
            })
          : await apiPost('/api/auth/register', body: {
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'password': _passwordController.text,
              'role': _role,
            });
      await AuthStore.saveSession(
          data['user'] as Map<String, dynamic>,
          token: data['token'] as String);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => homeForRole(AuthStore.user!.role ?? 'student')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Cannot reach the server. Is the API running?');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final tt = context.tt;
    final reduced = prefersReducedMotion(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spaceMd),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand mark — single signal colour, no emoji icon.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Icon(
                        Icons.school,
                        size: 48,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceLg),
                    // Hero headline: seven words or fewer.
                    Text(
                      'Welcome back',
                      textAlign: TextAlign.center,
                      style: tt.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXs),
                    // One sentence, twelve words or fewer.
                    Text(
                      _isLogin
                          ? 'Sign in to your academic account.'
                          : 'Create a new academic account.',
                      textAlign: TextAlign.center,
                      style: tt.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spaceXl),
                    if (!_isLogin) ...[
                      TextFormField(
                        controller: _nameController,
                        focusNode: _focusName,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Name is required'
                            : null,
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                      DropdownButtonFormField<String>(
                        focusNode: _focusName,
                        initialValue: _role,
                        decoration: const InputDecoration(
                          labelText: 'I am a',
                          prefixIcon: Icon(Icons.account_circle_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'student', child: Text('Student')),
                          DropdownMenuItem(
                              value: 'teacher', child: Text('Teacher')),
                          DropdownMenuItem(
                              value: 'parent', child: Text('Parent')),
                        ],
                        onChanged: (v) => setState(() => _role = v ?? 'student'),
                      ),
                      const SizedBox(height: AppTheme.spaceMd),
                    ],
                    TextFormField(
                      controller: _emailController,
                      focusNode: _focusEmail,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onEditingComplete: () =>
                          _isLogin ? _focusPassword.requestFocus() : null,
                      decoration: const InputDecoration(
                        labelText: 'College email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (v) => (v == null || !v.contains('@'))
                          ? 'Enter a valid email'
                          : null,
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _focusPassword,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onEditingComplete: _submit,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          focusNode: FocusNode(skipTraversal: true),
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Minimum 6 characters'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppTheme.spaceMd),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spaceSm),
                        decoration: BoxDecoration(
                          color: cs.errorContainer,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline,
                                color: cs.error, size: 20),
                            const SizedBox(width: AppTheme.spaceSm),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: cs.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: AppTheme.spaceLg),
                    // Primary action — one filled button style.
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                                valueColor: reduced
                                    ? AlwaysStoppedAnimation<Color>(cs.onPrimary)
                                    : null,
                              ),
                            )
                          : Text(_isLogin ? 'Sign in' : 'Create account'),
                    ),
                    const SizedBox(height: AppTheme.spaceMd),
                    // Secondary action — text button, not a second primary.
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _isLogin = !_isLogin;
                                  _error = null;
                                }),
                        child: Text(
                          _isLogin
                              ? 'New here? Create an account'
                              : 'Already have an account? Sign in',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
