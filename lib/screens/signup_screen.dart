import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
  bool _isCandidate = true;
  bool _isLoading = false;
  String? _errorMessage;

  // Candidate controllers
  final _candidateNameController = TextEditingController();
  final _candidateEmailController = TextEditingController();
  final _candidatePasswordController = TextEditingController();

  // Company controllers
  final _companyNameController = TextEditingController();
  final _companyCnpjController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _companyPasswordController = TextEditingController();

  @override
  void dispose() {
    _candidateNameController.dispose();
    _candidateEmailController.dispose();
    _candidatePasswordController.dispose();
    _companyNameController.dispose();
    _companyCnpjController.dispose();
    _companyEmailController.dispose();
    _companyPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isCandidate) {
        final name = _candidateNameController.text.trim();
        final email = _candidateEmailController.text.trim();
        final password = _candidatePasswordController.text;

        if (name.isEmpty || email.isEmpty || password.isEmpty) {
          throw ApiException("Por favor preencha todos os campos.");
        }
        if (password.length < 6) {
          throw ApiException("A senha deve ter no mínimo 6 caracteres.");
        }

        final user = await ApiService.instance.registerCandidate(name, email, password);
        if (mounted) {
          widget.onSuccess(user.isCandidate ? "candidate" : "company");
        }
      } else {
        final companyName = _companyNameController.text.trim();
        final cnpj = _companyCnpjController.text.trim();
        final email = _companyEmailController.text.trim();
        final password = _companyPasswordController.text;

        if (companyName.isEmpty || cnpj.isEmpty || email.isEmpty || password.isEmpty) {
          throw ApiException("Por favor preencha todos os campos.");
        }
        if (password.length < 6) {
          throw ApiException("A senha deve ter no mínimo 6 caracteres.");
        }

        await ApiService.instance.registerCompany(companyName, cnpj, email, password);
        if (mounted) {
          widget.onSuccess("company");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
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
              InkWell(
                onTap: widget.onBack,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.chevronLeft,
                    color: AppColors.textPrimary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              const Text(
                "Criar Conta",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Cadastre-se para encontrar matches perfeitos",
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Account Type Selector
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCandidate = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isCandidate ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _isCandidate
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sou Candidato",
                            style: TextStyle(
                              fontWeight: _isCandidate ? FontWeight.bold : FontWeight.w500,
                              color: _isCandidate ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCandidate = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isCandidate ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: !_isCandidate
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Sou Empresa",
                            style: TextStyle(
                              fontWeight: !_isCandidate ? FontWeight.bold : FontWeight.w500,
                              color: !_isCandidate ? AppColors.primary : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Error banner
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circleAlert, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Fields
              if (_isCandidate) ...[
                _buildField("Nome completo", "ex: Ana Silva", _candidateNameController),
                const SizedBox(height: 16),
                _buildField("Email", "ex: ana.silva@email.com", _candidateEmailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField("Senha", "Mínimo 6 caracteres", _candidatePasswordController,
                    obscureText: true),
              ] else ...[
                _buildField("Nome da Empresa", "ex: Tech Solutions", _companyNameController),
                const SizedBox(height: 16),
                _buildField("CNPJ (apenas números ou formatado)", "33.000.167/0001-01",
                    _companyCnpjController,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                _buildField("Email corporativo", "ex: contato@empresa.com",
                    _companyEmailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildField("Senha", "Mínimo 6 caracteres", _companyPasswordController,
                    obscureText: true),
              ],

              const SizedBox(height: 28),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          "Criar Conta e Entrar",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: widget.onBack,
                  child: const Text(
                    "Já tem uma conta? Entrar",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    String hint,
    TextEditingController controller, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
