import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/candidate_profile.dart';
import '../../models/company_profile.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ProfileTab extends StatefulWidget {
  final VoidCallback onLogout;
  final ApiService? api;

  const ProfileTab({super.key, required this.onLogout, this.api});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  ApiService get _api => widget.api ?? ApiService.instance;
  bool _isLoading = true;
  CandidateProfile? _candidateProfile;
  CompanyProfile? _companyProfile;
  String? _errorMessage;

  bool get _isCompany => _api.currentUser?.isCompany == true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isCompany) {
        final profile = await _api.getMyCompanyProfile();
        if (mounted) setState(() => _companyProfile = profile);
      } else {
        final profile = await _api.getMyCandidateProfile();
        if (mounted) setState(() => _candidateProfile = profile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptionsDialog() {
    if (_candidateProfile == null) return;
    final urlCtrl = TextEditingController(text: _candidateProfile!.photoUrl ?? "");

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Foto de Perfil"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Insira o link da sua foto de perfil ou imagem profissional:",
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: "URL da foto (JPEG, PNG ou WEBP)",
                hintText: "https://...",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (_candidateProfile!.photoUrl != null && _candidateProfile!.photoUrl!.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                setState(() => _isLoading = true);
                try {
                  final updated = CandidateProfile(
                    id: _candidateProfile!.id,
                    userId: _candidateProfile!.userId,
                    name: _candidateProfile!.name,
                    photoUrl: "",
                    desiredRole: _candidateProfile!.desiredRole,
                    area: _candidateProfile!.area,
                    experienceYears: _candidateProfile!.experienceYears,
                    education: _candidateProfile!.education,
                    city: _candidateProfile!.city,
                    state: _candidateProfile!.state,
                    country: _candidateProfile!.country,
                    minimumSalaryExpectation: _candidateProfile!.minimumSalaryExpectation,
                    preferredModality: _candidateProfile!.preferredModality,
                    preferredContractType: _candidateProfile!.preferredContractType,
                    completionPercentage: _candidateProfile!.completionPercentage,
                    skills: _candidateProfile!.skills,
                  );
                  final res = await _api.updateCandidateProfile(updated);
                  if (mounted) {
                    setState(() => _candidateProfile = res);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Foto removida com sucesso!")),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Erro ao remover foto: $e")),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isLoading = false);
                }
              },
              child: const Text("Remover Foto", style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUrl = urlCtrl.text.trim();
              Navigator.of(ctx).pop();
              setState(() => _isLoading = true);
              try {
                final updated = CandidateProfile(
                  id: _candidateProfile!.id,
                  userId: _candidateProfile!.userId,
                  name: _candidateProfile!.name,
                  photoUrl: newUrl.isNotEmpty ? newUrl : null,
                  desiredRole: _candidateProfile!.desiredRole,
                  area: _candidateProfile!.area,
                  experienceYears: _candidateProfile!.experienceYears,
                  education: _candidateProfile!.education,
                  city: _candidateProfile!.city,
                  state: _candidateProfile!.state,
                  country: _candidateProfile!.country,
                  minimumSalaryExpectation: _candidateProfile!.minimumSalaryExpectation,
                  preferredModality: _candidateProfile!.preferredModality,
                  preferredContractType: _candidateProfile!.preferredContractType,
                  completionPercentage: _candidateProfile!.completionPercentage,
                  skills: _candidateProfile!.skills,
                );
                final res = await _api.updateCandidateProfile(updated);
                if (mounted) {
                  setState(() => _candidateProfile = res);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Foto atualizada com sucesso!")),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Erro ao atualizar foto: $e")),
                  );
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  void _showEditCandidateDialog() {
    if (_candidateProfile == null) return;
    final nameCtrl = TextEditingController(text: _candidateProfile!.name);
    final roleCtrl = TextEditingController(text: _candidateProfile!.desiredRole);
    final areaCtrl = TextEditingController(text: _candidateProfile!.area);
    final salaryCtrl = TextEditingController(
        text: _candidateProfile!.minimumSalaryExpectation != null && _candidateProfile!.minimumSalaryExpectation! > 0
            ? _candidateProfile!.minimumSalaryExpectation!.toStringAsFixed(0)
            : "");
    final expCtrl = TextEditingController(
        text: _candidateProfile!.experienceYears > 0 ? _candidateProfile!.experienceYears.toString() : "");
    final eduCtrl = TextEditingController(text: _candidateProfile!.education);
    final cityCtrl = TextEditingController(text: _candidateProfile!.city);
    final stateCtrl = TextEditingController(text: _candidateProfile!.state);
    final newSkillCtrl = TextEditingController();

    String selectedModality = _candidateProfile!.preferredModality;
    if (!['REMOTE', 'HYBRID', 'ONSITE'].contains(selectedModality)) {
      selectedModality = 'REMOTE';
    }

    String selectedContract = _candidateProfile!.preferredContractType;
    if (selectedContract.isEmpty) selectedContract = 'CLT';

    bool saving = false;
    String? saveError;
    final currentSkills = List<String>.from(_candidateProfile!.skills);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Editar Perfil Profissional"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (saveError != null) Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Semantics(liveRegion: true, child: Text(saveError!,
                      style: const TextStyle(color: AppColors.error))),
                  ),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nome completo"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(labelText: "Cargo desejado"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areaCtrl,
                    decoration: const InputDecoration(labelText: "Área de atuação"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: expCtrl,
                          decoration: const InputDecoration(labelText: "Experiência (anos)"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: salaryCtrl,
                          decoration: const InputDecoration(labelText: "Pretensão (R\$)"),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: eduCtrl,
                    decoration: const InputDecoration(labelText: "Escolaridade / Formação"),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: cityCtrl,
                          decoration: const InputDecoration(labelText: "Cidade"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: stateCtrl,
                          decoration: const InputDecoration(labelText: "Estado (UF)"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedModality,
                    decoration: const InputDecoration(labelText: "Modalidade preferida"),
                    items: const [
                      DropdownMenuItem(value: 'REMOTE', child: Text('Remoto')),
                      DropdownMenuItem(value: 'HYBRID', child: Text('Híbrido')),
                      DropdownMenuItem(value: 'ONSITE', child: Text('Presencial')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedModality = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: ['CLT', 'PJ', 'CLT / PJ', 'Estágio'].contains(selectedContract)
                        ? selectedContract
                        : 'CLT',
                    decoration: const InputDecoration(labelText: "Tipo de contratação"),
                    items: const [
                      DropdownMenuItem(value: 'CLT', child: Text('CLT')),
                      DropdownMenuItem(value: 'PJ', child: Text('PJ')),
                      DropdownMenuItem(value: 'CLT / PJ', child: Text('CLT / PJ')),
                      DropdownMenuItem(value: 'Estágio', child: Text('Estágio')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedContract = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    "Competências / Habilidades (Skills):",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (currentSkills.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: currentSkills
                          .map(
                            (skill) => Chip(
                              label: Text(skill, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(LucideIcons.x, size: 14),
                              onDeleted: () {
                                setDialogState(() {
                                  currentSkills.remove(skill);
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newSkillCtrl,
                          decoration: const InputDecoration(
                            hintText: "Adicionar skill (ex: Flutter)",
                            isDense: true,
                          ),
                          onSubmitted: (val) {
                            final text = val.trim();
                            if (text.isNotEmpty && !currentSkills.contains(text)) {
                              setDialogState(() {
                                currentSkills.add(text);
                                newSkillCtrl.clear();
                              });
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.plusCircle, color: AppColors.primary),
                        onPressed: () {
                          final text = newSkillCtrl.text.trim();
                          if (text.isNotEmpty && !currentSkills.contains(text)) {
                            setDialogState(() {
                              currentSkills.add(text);
                              newSkillCtrl.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(ctx).pop(),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: saving ? null : () async {
                  setDialogState(() { saving = true; saveError = null; });
                  try {
                    final updated = CandidateProfile(
                      id: _candidateProfile!.id,
                      userId: _candidateProfile!.userId,
                      name: nameCtrl.text.trim(),
                      photoUrl: _candidateProfile!.photoUrl,
                      desiredRole: roleCtrl.text.trim(),
                      area: areaCtrl.text.trim(),
                      experienceYears: int.tryParse(expCtrl.text.trim()) ?? 0,
                      education: eduCtrl.text.trim(),
                      city: cityCtrl.text.trim(),
                      state: stateCtrl.text.trim(),
                      country: _candidateProfile!.country,
                      minimumSalaryExpectation: double.tryParse(salaryCtrl.text.trim()),
                      preferredModality: selectedModality,
                      preferredContractType: selectedContract,
                      completionPercentage: _candidateProfile!.completionPercentage,
                      skills: currentSkills,
                    );
                    final res = await _api.updateCandidateProfile(updated);
                    if (mounted) {
                      setState(() => _candidateProfile = res);
                      if (ctx.mounted) { Navigator.of(ctx).pop(); }
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text("Perfil atualizado com sucesso!")),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      setDialogState(() {
                      saveError = 'Não foi possível salvar. Seus dados foram mantidos; tente novamente.';
                    });
                    }
                  } finally {
                    if (context.mounted) setDialogState(() => saving = false);
                  }
                },
                child: Text(saving ? "Salvando…" : "Salvar"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Perfil",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    children: [
                      if (!_isCompany && _candidateProfile != null)
                        IconButton(
                          onPressed: _showEditCandidateDialog,
                          icon: const Icon(LucideIcons.pencil, color: AppColors.primary, size: 20),
                          tooltip: "Editar Perfil",
                        ),
                      IconButton(
                        onPressed: widget.onLogout,
                        icon: const Icon(
                          LucideIcons.logOut,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        tooltip: "Sair da conta",
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (_isLoading)
                const SizedBox(
                  height: 300,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null && _candidateProfile == null && _companyProfile == null)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(LucideIcons.cloudOff, size: 48, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfile,
                        child: const Text("Tentar novamente"),
                      ),
                    ],
                  ),
                )
              else if (_isCompany && _companyProfile != null)
                _buildCompanyContent(_companyProfile!)
              else
                _buildCandidateContent(_candidateProfile ?? const CandidateProfile()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCandidateContent(CandidateProfile candidate) {
    return Column(
      children: [
        // Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // User photo with camera badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gray50, width: 4),
                      color: AppColors.primary,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: candidate.avatarUrl != null
                        ? Image.network(
                            candidate.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildAvatarFallback(candidate.name),
                          )
                        : _buildAvatarFallback(candidate.name),
                  ),
                  GestureDetector(
                    onTap: _showPhotoOptionsDialog,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        LucideIcons.camera,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                candidate.name.isNotEmpty ? candidate.name : "Candidato",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),

              // Role
              Text(
                candidate.role,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),

              // Location
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    LucideIcons.mapPin,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    candidate.location.isNotEmpty ? candidate.location : "Brasil",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Profile Completion Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Completude do perfil",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "${candidate.completionPercentage}%",
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981), // green-500
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (candidate.completionPercentage / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.gray200,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Skills Badge Card
        if (candidate.skills.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Competências (Skills)",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.pencil, size: 16, color: AppColors.primary),
                      onPressed: _showEditCandidateDialog,
                      tooltip: "Editar Skills",
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.gray100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gray100),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Adicione suas competências para aumentar o match com vagas!",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ),
                TextButton(
                  onPressed: _showEditCandidateDialog,
                  child: const Text("Adicionar"),
                ),
              ],
            ),
          ),

        // Preferences Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Preferências",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceRow(
                label: "Pretensão salarial",
                value: candidate.salaryExpectation,
                hasBorder: true,
              ),
              _buildPreferenceRow(
                label: "Modalidade",
                value: candidate.modality,
                hasBorder: true,
              ),
              _buildPreferenceRow(
                label: "Contratação",
                value: candidate.contractType,
                hasBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyContent(CompanyProfile company) {
    return Column(
      children: [
        // Company Profile Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gray100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gray50, width: 4),
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.network(
                  company.displayLogo,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    LucideIcons.building2,
                    size: 48,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    company.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (company.verificationStatus == 'VERIFIED') ...[
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.badgeCheck, color: Color(0xFF2563EB), size: 20),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                company.industry ?? "Empresa Parceira",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              if (company.city != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.mapPin, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      company.location,
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          "Plano",
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                        Text(
                          company.planType,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          "Vagas Ativas",
                          style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                        ),
                        Text(
                          "${company.activeJobsCount}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Dados Cadastrais",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildPreferenceRow(label: "CNPJ", value: company.cnpj, hasBorder: true),
              _buildPreferenceRow(
                label: "Porte",
                value: company.companySize ?? "50-200 funcionários",
                hasBorder: true,
              ),
              _buildPreferenceRow(
                label: "Status",
                value: company.verificationStatus == 'VERIFIED' ? 'Verificada' : 'Em análise',
                hasBorder: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceRow({
    required String label,
    required String value,
    required bool hasBorder,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: hasBorder
            ? const Border(
                bottom: BorderSide(color: AppColors.gray100),
              )
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "C";
    return Container(
      color: const Color(0xFF280F9F),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
