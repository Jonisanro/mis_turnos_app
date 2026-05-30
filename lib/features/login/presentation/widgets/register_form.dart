import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mis_turnos_app/core/theme/app_theme.dart';
import 'package:mis_turnos_app/features/login/presentation/providers/login_provider.dart';
import 'package:mis_turnos_app/features/login/presentation/widgets/login_form.dart';

class RegisterCard extends ConsumerStatefulWidget {
  const RegisterCard({super.key});

  @override
  ConsumerState<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends ConsumerState<RegisterCard> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final result = await ref.read(loginProvider).registerWithEmail(
          _emailController.text,
          _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.isSuccess) {
      context.go('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'No se pudo crear la cuenta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        width: isMobile ? size.width * 0.9 : 420,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Center(
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.accent,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Crear cuenta',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Registrate para gestionar tu agenda de turnos',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.secondary),
              ),
              const SizedBox(height: 32),

              // Email
              AuthTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'tu@email.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Ingresá tu email';
                  if (!v.contains('@')) return 'Email inválido';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Password
              AuthTextField(
                controller: _passwordController,
                label: 'Contraseña',
                hint: 'Mínimo 6 caracteres',
                icon: Icons.lock_outline_rounded,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.next,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Ingresá una contraseña';
                  if (v.length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Confirmar password
              AuthTextField(
                controller: _confirmController,
                label: 'Repetir contraseña',
                hint: '••••••••',
                icon: Icons.lock_outline_rounded,
                obscureText: !_isPasswordVisible,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _register(),
                validator: (v) {
                  if (v != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Crear cuenta'),
                ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => context.go('/'),
                child: const Text('¿Ya tenés cuenta? Iniciá sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
