import 'dart:io' show File, Platform, Process;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/candidate_certificate.dart';
import '../../models/candidate_profile.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/demo_certificates.dart';
import '../../utils/error_messages.dart';

const List<String> _brazilStates = [
  'AC', 'AL', 'AP', 'AM', 'BA', 'CE', 'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
  'MG', 'PA', 'PB', 'PR', 'PE', 'PI', 'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
  'SP', 'SE', 'TO',
];

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
  List<CandidateCertificate> _certificates = [];
  String? _errorMessage;

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
      final profile = await _api.getMyCandidateProfile();
      List<CandidateCertificate> certs = [];
      try {
        certs = await _api.getMyCertificates();
      } catch (_) {
        // Keep profile loading resilient if certificates endpoint is unavailable
      }
      if (mounted) {
        setState(() {
          _candidateProfile = profile;
          _certificates = certs;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = friendlyErrorMessage(
            e,
            fallback: 'Não foi possível carregar seu perfil. Tente novamente.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptionsSheet() {
    if (_candidateProfile == null) return;
    final urlCtrl =
        TextEditingController(text: _candidateProfile!.photoUrl ?? '');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(ctx).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Foto de Perfil',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Insira o link da sua foto de perfil (JPEG, PNG ou WEBP):',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL da foto',
                hintText: 'https://...',
                prefixIcon: Icon(LucideIcons.image, size: 18),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (_candidateProfile!.photoUrl != null &&
                    _candidateProfile!.photoUrl!.isNotEmpty) ...[
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await _updatePhotoUrl('');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.dangerBorder),
                    ),
                    child: const Text('Remover'),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      final newUrl = urlCtrl.text.trim();
                      Navigator.of(ctx).pop();
                      await _updatePhotoUrl(newUrl.isNotEmpty ? newUrl : null);
                    },
                    child: const Text('Salvar foto'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePhotoUrl(String? photoUrl) async {
    if (_candidateProfile == null) return;
    setState(() => _isLoading = true);
    try {
      final updated = CandidateProfile(
        id: _candidateProfile!.id,
        userId: _candidateProfile!.userId,
        name: _candidateProfile!.name,
        photoUrl: photoUrl,
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
          SnackBar(
            content: Text(
              photoUrl == ''
                  ? 'Foto removida com sucesso.'
                  : 'Foto atualizada com sucesso.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                e,
                fallback: 'Não foi possível atualizar sua foto agora.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openEditCandidateScreen() async {
    if (_candidateProfile == null) return;
    final updated = await Navigator.of(context).push<CandidateProfile>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _EditCandidateProfileScreen(
          profile: _candidateProfile!,
          api: _api,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _candidateProfile = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado com sucesso!')),
      );
    }
  }

  Future<void> _openCertificateVerifierSheet() async {
    if (_candidateProfile == null) return;
    final verified = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (_) => _CertificateVerifierSheet(
        profile: _candidateProfile!,
        api: _api,
      ),
    );
    if (verified == true && mounted) {
      await _loadProfile();
    }
  }

  Future<void> _deleteCertificate(CandidateCertificate cert) async {
    try {
      await _api.deleteCandidateCertificate(cert.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Certificado removido do perfil.')),
        );
        await _loadProfile();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              friendlyErrorMessage(
                e,
                fallback: 'Não foi possível remover o certificado.',
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Perfil',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      if (_candidateProfile != null)
                        IconButton(
                          onPressed: _openEditCandidateScreen,
                          icon: const Icon(
                            LucideIcons.pencil,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          tooltip: 'Editar Perfil',
                        ),
                      IconButton(
                        onPressed: widget.onLogout,
                        icon: const Icon(
                          LucideIcons.logOut,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                        tooltip: 'Sair da conta',
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
              else if (_errorMessage != null && _candidateProfile == null)
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      const Icon(
                        LucideIcons.cloudOff,
                        size: 44,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _loadProfile,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              else
                _buildCandidateContent(
                  _candidateProfile ?? const CandidateProfile(),
                ),
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
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              // User photo with camera badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.surfaceMuted, width: 4),
                      color: AppColors.ink,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: candidate.avatarUrl != null
                        ? Image.network(
                            candidate.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) =>
                                _buildAvatarFallback(candidate.name),
                          )
                        : _buildAvatarFallback(candidate.name),
                  ),
                  Semantics(
                    button: true,
                    label: 'Alterar foto de perfil',
                    child: InkWell(
                      onTap: _showPhotoOptionsSheet,
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(8),
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
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Name
              Text(
                candidate.name.isNotEmpty ? candidate.name : 'Candidato',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
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
                    candidate.location.isNotEmpty
                        ? candidate.location
                        : 'Brasil',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // Profile Completion Bar (WCAG AA #0F6B3A)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Completude do perfil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          '${candidate.completionPercentage}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value:
                            (candidate.completionPercentage / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.secondaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Skills Badge Card
        if (candidate.skills.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Competências',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.pencil,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      onPressed: _openEditCandidateScreen,
                      tooltip: 'Editar Competências',
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: candidate.skills
                      .map((s) {
                        final isVerified = candidate.verifiedSkills.any(
                          (vs) => vs.trim().toLowerCase() == s.trim().toLowerCase(),
                        );
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isVerified
                                ? AppColors.secondarySoft
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadii.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isVerified) ...[
                                const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 14,
                                  color: AppColors.secondaryText,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                s,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isVerified
                                      ? AppColors.secondaryText
                                      : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                      .toList(),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  LucideIcons.slidersHorizontal,
                  color: AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Adicione suas competências para melhorar sua compatibilidade com as vagas.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openEditCandidateScreen,
                  child: const Text('Adicionar'),
                ),
              ],
            ),
          ),

        // Preferences Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Preferências',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildPreferenceRow(
                label: 'Pretensão salarial',
                value: candidate.salaryExpectation,
                hasBorder: true,
              ),
              _buildPreferenceRow(
                label: 'Modalidade',
                value: candidate.modality,
                hasBorder: true,
              ),
              _buildPreferenceRow(
                label: 'Contratação',
                value: candidate.contractType,
                hasBorder: false,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Verificador de Competências (Certificados + Antifraude + Prioridade)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        LucideIcons.shieldCheck,
                        size: 20,
                        color: AppColors.secondaryText,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Verificador de Competências',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  if (candidate.priorityBonusTotal > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '+${candidate.priorityBonusTotal} pts prioridade',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Envie certificados emitidos por instituições reconhecidas. A análise antifraude confere metadados, emissor e seu nome completo para liberar prioridade nas vagas.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (_certificates.isNotEmpty) ...[
                for (final cert in _certificates)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cert.courseTitle,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${cert.institutionName} · Nível ${cert.institutionTier} · +${cert.priorityBonus} pts',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              if (cert.verifiedSkills.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: cert.verifiedSkills
                                      .map(
                                        (sk) => Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondarySoft,
                                            borderRadius: BorderRadius.circular(
                                              AppRadii.sm,
                                            ),
                                          ),
                                          child: Text(
                                            sk,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Remover certificado',
                          icon: const Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () => _deleteCertificate(cert),
                        ),
                      ],
                    ),
                  ),
              ],
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _openCertificateVerifierSheet,
                  icon: const Icon(LucideIcons.fileCheck2, size: 18),
                  label: const Text('Validar novo certificado'),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Confere emissor, titularidade e metadados; não substitui avaliação prática.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textHint,
                ),
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
                bottom: BorderSide(color: AppColors.border),
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
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'C';
    return Container(
      color: AppColors.ink,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 34,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Full-screen modal editor replacing the cramped AlertDialog.
class _EditCandidateProfileScreen extends StatefulWidget {
  final CandidateProfile profile;
  final ApiService api;

  const _EditCandidateProfileScreen({
    required this.profile,
    required this.api,
  });

  @override
  State<_EditCandidateProfileScreen> createState() =>
      _EditCandidateProfileScreenState();
}

class _EditCandidateProfileScreenState
    extends State<_EditCandidateProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _areaCtrl;
  late final TextEditingController _salaryCtrl;
  late final TextEditingController _expCtrl;
  late final TextEditingController _eduCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _newSkillCtrl;

  late String _selectedModality;
  late String _selectedContract;
  String? _selectedState;
  late List<String> _skills;
  bool _saving = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _roleCtrl = TextEditingController(text: p.desiredRole);
    _areaCtrl = TextEditingController(text: p.area);
    _salaryCtrl = TextEditingController(
      text: p.minimumSalaryExpectation != null &&
              p.minimumSalaryExpectation! > 0
          ? p.minimumSalaryExpectation!.toStringAsFixed(0)
          : '',
    );
    _expCtrl = TextEditingController(
      text: p.experienceYears > 0 ? p.experienceYears.toString() : '',
    );
    _eduCtrl = TextEditingController(text: p.education);
    _cityCtrl = TextEditingController(text: p.city);
    _newSkillCtrl = TextEditingController();

    _selectedModality =
        ['REMOTE', 'HYBRID', 'ONSITE'].contains(p.preferredModality)
            ? p.preferredModality
            : 'REMOTE';
    _selectedContract =
        ['CLT', 'PJ', 'CLT / PJ', 'Estágio'].contains(p.preferredContractType)
            ? p.preferredContractType
            : 'CLT';
    final upperState = p.state.trim().toUpperCase();
    _selectedState = _brazilStates.contains(upperState) ? upperState : null;
    _skills = List<String>.from(p.skills);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _areaCtrl.dispose();
    _salaryCtrl.dispose();
    _expCtrl.dispose();
    _eduCtrl.dispose();
    _cityCtrl.dispose();
    _newSkillCtrl.dispose();
    super.dispose();
  }

  void _addSkill([String? value]) {
    final text = (value ?? _newSkillCtrl.text).trim();
    if (text.isEmpty) return;
    if (!_skills.any((s) => s.toLowerCase() == text.toLowerCase())) {
      setState(() {
        _skills.add(text);
        _newSkillCtrl.clear();
      });
    } else {
      _newSkillCtrl.clear();
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final updated = CandidateProfile(
        id: widget.profile.id,
        userId: widget.profile.userId,
        name: _nameCtrl.text.trim(),
        photoUrl: widget.profile.photoUrl,
        desiredRole: _roleCtrl.text.trim(),
        area: _areaCtrl.text.trim(),
        experienceYears: int.tryParse(_expCtrl.text.trim()) ?? 0,
        education: _eduCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _selectedState ?? '',
        country: widget.profile.country,
        minimumSalaryExpectation: double.tryParse(_salaryCtrl.text.trim()),
        preferredModality: _selectedModality,
        preferredContractType: _selectedContract,
        completionPercentage: widget.profile.completionPercentage,
        skills: _skills,
      );
      final res = await widget.api.updateCandidateProfile(updated);
      if (mounted) {
        Navigator.of(context).pop(res);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _saveError =
              'Não foi possível salvar. Seus dados foram mantidos; tente novamente.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Editar Perfil Profissional',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        leading: IconButton(
          tooltip: 'Fechar',
          icon: const Icon(LucideIcons.x),
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_saveError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: AppColors.dangerBg,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.dangerBorder),
                      ),
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          _saveError!,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),

                  _sectionTitle('1. Identificação e objetivo'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nome completo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _roleCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Cargo desejado'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _areaCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Área de atuação'),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('2. Experiência e formação'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Experiência (anos)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _salaryCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Pretensão (R\$)',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _eduCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Escolaridade / Formação',
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('3. Localização e formato'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(labelText: 'Cidade'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedState,
                          isExpanded: true,
                          decoration:
                              const InputDecoration(labelText: 'UF'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('—'),
                            ),
                            for (final uf in _brazilStates)
                              DropdownMenuItem(value: uf, child: Text(uf)),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedState = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedModality,
                    decoration:
                        const InputDecoration(labelText: 'Modalidade preferida'),
                    items: const [
                      DropdownMenuItem(value: 'REMOTE', child: Text('Remoto')),
                      DropdownMenuItem(value: 'HYBRID', child: Text('Híbrido')),
                      DropdownMenuItem(
                        value: 'ONSITE',
                        child: Text('Presencial'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedModality = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedContract,
                    decoration:
                        const InputDecoration(labelText: 'Tipo de contratação'),
                    items: const [
                      DropdownMenuItem(value: 'CLT', child: Text('CLT')),
                      DropdownMenuItem(value: 'PJ', child: Text('PJ')),
                      DropdownMenuItem(
                        value: 'CLT / PJ',
                        child: Text('CLT / PJ'),
                      ),
                      DropdownMenuItem(
                        value: 'Estágio',
                        child: Text('Estágio'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedContract = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('4. Competências'),
                  const SizedBox(height: 10),
                  if (_skills.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _skills
                          .map(
                            (skill) => Chip(
                              label: Text(
                                skill,
                                style: const TextStyle(fontSize: 13),
                              ),
                              deleteIcon: const Icon(LucideIcons.x, size: 14),
                              onDeleted: () =>
                                  setState(() => _skills.remove(skill)),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _newSkillCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Adicionar competência (ex: Flutter)',
                          ),
                          onSubmitted: _addSkill,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: 'Adicionar competência',
                        icon: const Icon(LucideIcons.plus, size: 20),
                        onPressed: _addSkill,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Sticky bottom save bar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Salvando…' : 'Salvar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }
}

class _CertificateVerifierSheet extends StatefulWidget {
  final CandidateProfile profile;
  final ApiService api;

  const _CertificateVerifierSheet({
    required this.profile,
    required this.api,
  });

  @override
  State<_CertificateVerifierSheet> createState() =>
      _CertificateVerifierSheetState();
}

class _CertificateVerifierSheetState extends State<_CertificateVerifierSheet> {
  final TextEditingController _pathCtrl = TextEditingController();
  final TextEditingController _skillCtrl = TextEditingController();
  bool _submitting = false;
  bool _verifiedAtLeastOne = false;
  String? _error;
  CertificateValidationResult? _result;

  @override
  void dispose() {
    _pathCtrl.dispose();
    _skillCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFileDesktop() async {
    if (kIsWeb || !Platform.isLinux) {
      setState(() {
        _error =
            'Informe o caminho do arquivo PDF/PNG/JPEG abaixo para enviar.';
      });
      return;
    }
    try {
      final res = await Process.run('zenity', [
        '--file-selection',
        '--title=Selecionar certificado (PDF, PNG ou JPEG)',
        '--file-filter=Certificados | *.pdf *.png *.jpg *.jpeg',
      ]);
      if (res.exitCode == 0) {
        final selected = res.stdout.toString().trim();
        if (selected.isNotEmpty) {
          setState(() {
            _pathCtrl.text = selected;
            _error = null;
          });
        }
      }
    } catch (_) {
      setState(() {
        _error = 'Não foi possível abrir o seletor; digite o caminho do arquivo.';
      });
    }
  }

  Future<void> _submitBytes(List<int> bytes, String filename) async {
    setState(() {
      _submitting = true;
      _error = null;
      _result = null;
    });
    try {
      final res = await widget.api.uploadCandidateCertificate(
        fileBytes: bytes,
        filename: filename,
        targetSkill: _skillCtrl.text.trim().isNotEmpty ? _skillCtrl.text.trim() : null,
      );
      if (mounted) {
        setState(() {
          _result = res;
          if (res.accepted) _verifiedAtLeastOne = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = friendlyErrorMessage(
            e,
            fallback: 'Não foi possível validar o certificado agora.',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitFromPath() async {
    final path = _pathCtrl.text.trim();
    if (path.isEmpty) {
      setState(() => _error = 'Selecione ou informe o caminho de um arquivo PDF, PNG ou JPEG.');
      return;
    }
    if (kIsWeb) {
      setState(() => _error = 'Leitura por caminho local indisponível na Web.');
      return;
    }
    final file = File(path);
    if (!await file.exists()) {
      setState(() => _error = 'Arquivo não encontrado no caminho informado.');
      return;
    }
    final bytes = await file.readAsBytes();
    final filename = path.split('/').last;
    await _submitBytes(bytes, filename);
  }

  @override
  Widget build(BuildContext context) {
    final holderName = widget.profile.name.trim().isNotEmpty
        ? widget.profile.name.trim()
        : 'Candidato';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_verifiedAtLeastOne);
      },
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Verificador de Competências',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    icon: const Icon(LucideIcons.x),
                    onPressed: () =>
                        Navigator.of(context).pop(_verifiedAtLeastOne),
                  ),
                ],
              ),
              Text(
                'Titular esperado: $holderName',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _skillCtrl,
                decoration: const InputDecoration(
                  labelText: 'Competência alvo (opcional)',
                  hintText: 'Ex: Java, AWS, Flutter',
                  prefixIcon: Icon(LucideIcons.award, size: 18),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pathCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Arquivo do certificado',
                        hintText: '/caminho/para/certificado.pdf',
                        prefixIcon: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                  ),
                  if (!kIsWeb && Platform.isLinux) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _pickFileDesktop,
                      icon: const Icon(LucideIcons.folderOpen, size: 16),
                      label: const Text('Escolher'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submitFromPath,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.shieldCheck, size: 18),
                  label: Text(
                    _submitting
                        ? 'Analisando metadados...'
                        : 'Verificar certificado',
                  ),
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                const Text(
                  'Demonstração rápida (modo debug):',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              final skill = _skillCtrl.text.trim().isNotEmpty
                                  ? _skillCtrl.text.trim()
                                  : 'Java';
                              _submitBytes(
                                buildAuthenticAluraPdf(holderName, skill),
                                'certificado-alura-valido.pdf',
                              );
                            },
                      child: const Text('Simular Alura válido'),
                    ),
                    OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              final skill = _skillCtrl.text.trim().isNotEmpty
                                  ? _skillCtrl.text.trim()
                                  : 'Java';
                              _submitBytes(
                                buildTamperedPhotoshopPdf(holderName, skill),
                                'certificado-editado-photoshop.pdf',
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.dangerBorder),
                      ),
                      child: const Text('Simular fraude Photoshop'),
                    ),
                  ],
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(color: AppColors.dangerBorder),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
              if (_result != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _result!.accepted
                        ? AppColors.secondarySoft
                        : AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: _result!.accepted
                          ? AppColors.secondaryText.withValues(alpha: 0.25)
                          : AppColors.dangerBorder,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _result!.accepted
                                ? 'CERTIFICADO VALIDADO'
                                : 'CERTIFICADO REJEITADO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: _result!.accepted
                                  ? AppColors.secondaryText
                                  : AppColors.error,
                            ),
                          ),
                          Text(
                            'Risco antifraude: ${_result!.fraudRiskScore}/100',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _result!.summary,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.ink,
                          height: 1.4,
                        ),
                      ),
                      if (_result!.forensicChecks.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        for (final chk in _result!.forensicChecks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  chk.passed
                                      ? LucideIcons.checkCircle2
                                      : LucideIcons.alertTriangle,
                                  size: 14,
                                  color: chk.passed
                                      ? AppColors.secondaryText
                                      : AppColors.error,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    chk.detail,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
