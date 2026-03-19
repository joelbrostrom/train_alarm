import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:sov_inte_forbi/providers/auth_provider.dart';
import 'package:sov_inte_forbi/theme.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isSignUp) {
      auth.signUpWithEmail(email, password);
    } else {
      auth.signInWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo & title
                Icon(Icons.train_rounded, size: 56, color: AppColors.cyan)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.08, 1.08),
                      duration: 1200.ms,
                    ),
                const SizedBox(height: 16),
                Text(
                  'Sov Inte Förbi',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontSize: isWide ? 36 : 28,
                  ),
                ).animate().fadeIn(duration: 500.ms),
                const SizedBox(height: 6),
                Text(
                  'Never miss your stop again',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: AppColors.mistDim),
                ).animate(delay: 150.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 40),

                // Card with form
                Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.navySurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              _isSignUp ? 'Create Account' : 'Welcome Back',
                              style: Theme.of(context).textTheme.titleLarge,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),

                            // Email field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                hintText: 'Email',
                                prefixIcon: Icon(
                                  Icons.email_outlined,
                                  size: 20,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Enter your email';
                                }
                                if (!v.contains('@'))
                                  return 'Enter a valid email';
                                return null;
                              },
                              onChanged: (_) => auth.clearError(),
                            ),
                            const SizedBox(height: 14),

                            // Password field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    size: 20,
                                    color: AppColors.mistDim,
                                  ),
                                  onPressed:
                                      () => setState(
                                        () =>
                                            _obscurePassword =
                                                !_obscurePassword,
                                      ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Enter your password';
                                }
                                if (_isSignUp && v.length < 6) {
                                  return 'At least 6 characters';
                                }
                                return null;
                              },
                              onChanged: (_) => auth.clearError(),
                              onFieldSubmitted: (_) => _submit(),
                            ),
                            const SizedBox(height: 8),

                            // Error message
                            if (auth.errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                      auth.errorMessage!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: AppColors.coral),
                                      textAlign: TextAlign.center,
                                    )
                                    .animate()
                                    .fadeIn(duration: 200.ms)
                                    .shakeX(hz: 4, amount: 4, duration: 400.ms),
                              ),

                            const SizedBox(height: 8),

                            // Submit button
                            SizedBox(
                              height: 50,
                              child: ElevatedButton(
                                onPressed: auth.loading ? null : _submit,
                                child:
                                    auth.loading
                                        ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: AppColors.navy,
                                          ),
                                        )
                                        : Text(
                                          _isSignUp
                                              ? 'Create Account'
                                              : 'Sign In',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Toggle sign in / sign up
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _isSignUp
                                      ? 'Already have an account?'
                                      : "Don't have an account?",
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _isSignUp = !_isSignUp);
                                    auth.clearError();
                                  },
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                  ),
                                  child: Text(
                                    _isSignUp ? 'Sign In' : 'Sign Up',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                    .animate(delay: 300.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.08, end: 0, duration: 500.ms),

                const SizedBox(height: 24),

                // Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppColors.glassBorder),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.mistDim,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppColors.glassBorder),
                    ),
                  ],
                ).animate(delay: 500.ms).fadeIn(duration: 400.ms),

                const SizedBox(height: 24),

                // Google sign-in button
                SizedBox(
                      height: 50,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed:
                            auth.loading ? null : () => auth.signInWithGoogle(),
                        icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                        label: const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    )
                    .animate(delay: 600.ms)
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.05, end: 0, duration: 400.ms),

                const SizedBox(height: 32),

                // Skip / continue as guest
                TextButton(
                  onPressed: auth.loading ? null : () => _skipSignIn(context),
                  child: Text(
                    'Continue as guest',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.mistDim,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.mistDim,
                    ),
                  ),
                ).animate(delay: 700.ms).fadeIn(duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _skipSignIn(BuildContext context) {
    context.read<AuthProvider>().skipSignIn();
  }
}
