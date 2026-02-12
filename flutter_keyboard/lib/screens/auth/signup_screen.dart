import 'package:flutter/material.dart';
import 'package:desenrola_ai_keyboard/l10n/app_localizations.dart';
import '../../config/app_theme.dart';
import '../../services/firebase_auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = FirebaseAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Text(l10n.acceptTermsError),
            ],
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Text(l10n.signupSuccess),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.textPrimary),
                const SizedBox(width: 12),
                Expanded(child: Text(e.toString())),
              ],
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Text(
                      l10n.createAccountTitle,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.signupSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.nameLabel,
                        hintText: l10n.nameHint,
                        prefixIcon: const Icon(Icons.person_outlined, color: AppColors.textTertiary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.nameValidationEmpty;
                        }
                        if (value.trim().length < 2) {
                          return l10n.nameValidationMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.emailLabel,
                        hintText: l10n.emailHint,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textTertiary),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.emailValidationEmpty;
                        }
                        if (!value.contains('@')) {
                          return l10n.emailValidationInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                        hintText: l10n.passwordHintMinChars,
                        prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.passwordValidationEnter;
                        }
                        if (value.length < 6) {
                          return l10n.passwordValidationMinLength;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirm password field
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        labelText: l10n.confirmPasswordLabel,
                        hintText: l10n.confirmPasswordHint,
                        prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textTertiary),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: AppColors.textTertiary,
                          ),
                          onPressed: () {
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.confirmPasswordValidationEmpty;
                        }
                        if (value != _passwordController.text) {
                          return l10n.passwordMismatch;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Terms checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: _isLoading
                                ? null
                                : (value) {
                                    setState(() => _acceptedTerms = value ?? false);
                                  },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _acceptedTerms = !_acceptedTerms);
                            },
                            child: Text.rich(
                              TextSpan(
                                text: '${l10n.termsPrefix} ',
                                style: TextStyle(color: AppColors.textSecondary),
                                children: [
                                  TextSpan(
                                    text: l10n.termsLink,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  TextSpan(text: ' ${l10n.andConjunction} '),
                                  TextSpan(
                                    text: l10n.privacyPolicyLink,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Signup button
                    GradientButton(
                      text: l10n.createAccountButton,
                      isLoading: _isLoading,
                      icon: Icons.person_add,
                      onPressed: _isLoading ? null : _signUp,
                    ),
                    const SizedBox(height: 24),

                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          l10n.hasAccountText,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: _isLoading ? null : () => Navigator.pop(context),
                          child: GradientText(
                            text: l10n.loginLink,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
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
