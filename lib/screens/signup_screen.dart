import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/candidate_profile.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_messages.dart';

class SignupScreen extends StatefulWidget {
  final void Function(String role) onSuccess;
  final VoidCallback onBack;

  const SignupScreen({
    super.key,
    required this.onSuccess,
    required this.onBack,
  });

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _desiredRoleController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _desiredRoleController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final desiredRole = _desiredRoleController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Por favor, preencha todos os campos obrigatórios.');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Por favor, insira um endereço de e-mail válido.');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'A senha deve ter no mínimo 6 caracteres.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await ApiService.instance.registerCandidate(name, email, password);

      if (desiredRole.isNotEmpty) {
        try {
          await ApiService.instance.updateCandidateProfile(
            CandidateProfile(
              name: name,
              desiredRole: desiredRole,
              skills: const [],
            ),
          );
        } catch (_) {
          // Non-blocking on initial profile enrichment
        }
      }

      if (mounted) {
        widget.onSuccess(user.isCandidate ? 'candidate' : 'candidate');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = friendlyErrorMessage(
            e,
            fallback: 'Não foi possível criar sua conta agora. Tente novamente.',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton.outlined(
                onPressed: widget.onBack,
                tooltip: 'Voltar',
                icon: const Icon(LucideIcons.chevronLeft, size: 22),
              ),
              const SizedBox(height: 24),

              // Title & Subtitle
              const Text(
                'Criar Conta',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cadastre-se para encontrar vagas alinhadas ao seu perfil',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.circleAlert,
                        color: AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Form fields using shared AppTheme.inputDecorationTheme
              _buildInputLabel('Nome completo *'),
              TextField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'ex: Ana Silva',
                  prefixIcon: Icon(LucideIcons.user, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              _buildInputLabel('E-mail *'),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'ex: ana.silva@email.com',
                  prefixIcon: Icon(LucideIcons.mail, size: 20),
                ),
              ),
              const SizedBox(height: 18),

              _buildInputLabel('Senha *'),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  hintText: 'Mínimo 6 caracteres',
                  prefixIcon: const Icon(LucideIcons.lock, size: 20),
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Mostrar senha'
                        : 'Ocultar senha',
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              _buildInputLabel('Cargo desejado (opcional)'),
              TextField(
                controller: _desiredRoleController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _isLoading ? null : _handleRegister(),
                decoration: const InputDecoration(
                  hintText: 'ex: Desenvolvedor Flutter, Designer UX',
                  prefixIcon: Icon(LucideIcons.briefcase, size: 20),
                ),
              ),
              const SizedBox(height: 14),

              // Info card on progressive curriculum (no Sparkles, unified palette)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.secondarySoft,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  border: Border.all(
                    color: AppColors.secondaryText.withValues(alpha: 0.2),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.info,
                      size: 18,
                      color: AppColors.secondaryText,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cadastro ágil: você poderá complementar competências, pretensão salarial e foto no seu Perfil quando quiser.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Criar minha conta'),
                ),
              ),
              const SizedBox(height: 20),

              // Updated enterprise notice (Portal Web is live!)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.building2,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Empresa contratante? Acesse o Portal Web do Trabalhaki.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
