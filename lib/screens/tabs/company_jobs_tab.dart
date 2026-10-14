import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/job.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class CompanyJobsTab extends StatefulWidget {
  final List<Job> jobs;
  final VoidCallback onRefresh;
  final void Function(Job job) onJobClick;

  const CompanyJobsTab({
    super.key,
    required this.jobs,
    required this.onRefresh,
    required this.onJobClick,
  });

  @override
  State<CompanyJobsTab> createState() => _CompanyJobsTabState();
}

class _CompanyJobsTabState extends State<CompanyJobsTab> {
  bool _isSubmitting = false;

  void _showCreateJobDialog() {
    _showJobFormDialog(null);
  }

  void _showEditJobDialog(Job job) {
    _showJobFormDialog(job);
  }

  void _showJobFormDialog(Job? existingJob) {
    final isEdit = existingJob != null;
    final titleCtrl = TextEditingController(text: existingJob?.title ?? '');
    final descCtrl =
        TextEditingController(text: existingJob?.description ?? '');
    final minSalaryCtrl = TextEditingController();
    final maxSalaryCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final stateCtrl = TextEditingController();
    final contractCtrl =
        TextEditingController(text: existingJob?.contract ?? 'CLT');
    final levelCtrl =
        TextEditingController(text: existingJob?.level ?? 'Pleno');
    final expYearsCtrl = TextEditingController();
    final benefitsCtrl = TextEditingController(
        text: existingJob?.benefits.join(', ') ?? '');
    final skillsCtrl = TextEditingController(
        text: existingJob?.requirements.join(', ') ?? '');
    final diffSkillsCtrl = TextEditingController(
        text: existingJob?.differentials.join(', ') ?? '');

    String selectedModality = 'REMOTE';

    // Parse existing salary
    if (isEdit) {
      final salaryParts = existingJob.salary
          .replaceAll('R\$', '')
          .replaceAll('.', '')
          .replaceAll(' ', '')
          .split('—');
      if (salaryParts.length == 2) {
        minSalaryCtrl.text = salaryParts[0].trim();
        maxSalaryCtrl.text = salaryParts[1].trim();
      }
      // Parse experience years
      final expMatch = RegExp(r'(\d+)').firstMatch(existingJob.experience);
      if (expMatch != null) expYearsCtrl.text = expMatch.group(1)!;
      // Parse location
      final locParts = existingJob.location.split(', ');
      if (locParts.length >= 2) {
        cityCtrl.text = locParts[0];
        stateCtrl.text = locParts[1];
      } else if (locParts.isNotEmpty) {
        cityCtrl.text = locParts[0];
      }
      // Parse modality
      if (existingJob.type == 'Remoto') {
        selectedModality = 'REMOTE';
      } else if (existingJob.type == 'Híbrido') {
        selectedModality = 'HYBRID';
      } else if (existingJob.type == 'Presencial') {
        selectedModality = 'ONSITE';
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 620),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    decoration: const BoxDecoration(
                      border: Border(
                          bottom: BorderSide(color: AppColors.gray200)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                            isEdit ? LucideIcons.pencil : LucideIcons.plusCircle,
                            color: AppColors.primary,
                            size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isEdit ? 'Editar Vaga' : 'Nova Vaga',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  // Form
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _formField('Título *', titleCtrl, 'Ex: Desenvolvedor Backend Pleno'),
                          const SizedBox(height: 12),
                          _formField('Descrição *', descCtrl, 'Descreva a vaga...', maxLines: 3),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _formField('Salário Mín *', minSalaryCtrl, '3000', keyboard: TextInputType.number)),
                              const SizedBox(width: 12),
                              Expanded(child: _formField('Salário Máx *', maxSalaryCtrl, '7000', keyboard: TextInputType.number)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Modalidade *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: selectedModality,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.gray200),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'REMOTE', child: Text('Remoto')),
                              DropdownMenuItem(value: 'HYBRID', child: Text('Híbrido')),
                              DropdownMenuItem(value: 'ONSITE', child: Text('Presencial')),
                            ],
                            onChanged: (v) => setDialogState(() => selectedModality = v!),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _formField('Cidade', cityCtrl, 'São Paulo')),
                              const SizedBox(width: 12),
                              Expanded(child: _formField('Estado', stateCtrl, 'SP')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _formField('Contrato *', contractCtrl, 'CLT')),
                              const SizedBox(width: 12),
                              Expanded(child: _formField('Nível *', levelCtrl, 'Pleno')),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _formField('Anos de Experiência *', expYearsCtrl, '2', keyboard: TextInputType.number),
                          const SizedBox(height: 12),
                          _formField('Benefícios', benefitsCtrl, 'VR, VT, Plano de Saúde (separar por vírgula)'),
                          const SizedBox(height: 12),
                          _formField('Skills Obrigatórias', skillsCtrl, 'Java, Spring Boot (separar por vírgula)'),
                          const SizedBox(height: 12),
                          _formField('Skills Diferenciais', diffSkillsCtrl, 'Docker, AWS (separar por vírgula)'),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.gray200)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              side: const BorderSide(color: AppColors.gray200),
                            ),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _submitJob(
                                      ctx,
                                      isEdit: isEdit,
                                      jobId: existingJob?.id,
                                      title: titleCtrl.text,
                                      description: descCtrl.text,
                                      minSalary: minSalaryCtrl.text,
                                      maxSalary: maxSalaryCtrl.text,
                                      modality: selectedModality,
                                      city: cityCtrl.text,
                                      state: stateCtrl.text,
                                      contractType: contractCtrl.text,
                                      seniorityLevel: levelCtrl.text,
                                      experienceYears: expYearsCtrl.text,
                                      benefits: benefitsCtrl.text,
                                      requiredSkills: skillsCtrl.text,
                                      preferredSkills: diffSkillsCtrl.text,
                                    ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white))
                                : Text(isEdit ? 'Salvar' : 'Criar Vaga'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.gray300, fontSize: 14),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.gray200),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _submitJob(
    BuildContext dialogCtx, {
    required bool isEdit,
    String? jobId,
    required String title,
    required String description,
    required String minSalary,
    required String maxSalary,
    required String modality,
    required String city,
    required String state,
    required String contractType,
    required String seniorityLevel,
    required String experienceYears,
    required String benefits,
    required String requiredSkills,
    required String preferredSkills,
  }) async {
    // Validation
    if (title.trim().isEmpty ||
        description.trim().isEmpty ||
        minSalary.trim().isEmpty ||
        maxSalary.trim().isEmpty ||
        contractType.trim().isEmpty ||
        seniorityLevel.trim().isEmpty ||
        experienceYears.trim().isEmpty) {
      _showSnack('Preencha todos os campos obrigatórios (*)');
      return;
    }

    setState(() => _isSubmitting = true);

    final List<Map<String, String>> skills = [];
    for (var s in requiredSkills.split(',')) {
      if (s.trim().isNotEmpty) {
        skills.add({'skillName': s.trim(), 'skillType': 'REQUIRED'});
      }
    }
    for (var s in preferredSkills.split(',')) {
      if (s.trim().isNotEmpty) {
        skills.add({'skillName': s.trim(), 'skillType': 'PREFERRED'});
      }
    }

    final benefitList = benefits
        .split(',')
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final body = <String, dynamic>{
      'title': title.trim(),
      'description': description.trim(),
      'minimumSalary': double.tryParse(minSalary.trim()) ?? 0,
      'maximumSalary': double.tryParse(maxSalary.trim()) ?? 0,
      'modality': modality,
      'contractType': contractType.trim(),
      'seniorityLevel': seniorityLevel.trim(),
      'experienceYears': int.tryParse(experienceYears.trim()) ?? 0,
      'benefits': benefitList,
      'skills': skills,
    };
    if (city.trim().isNotEmpty) body['city'] = city.trim();
    if (state.trim().isNotEmpty) body['state'] = state.trim();
    body['country'] = 'Brasil';

    try {
      if (isEdit) {
        await ApiService.instance.updateJob(jobId!, body);
        _showSnack('Vaga atualizada com sucesso!');
      } else {
        await ApiService.instance.createJob(body);
        _showSnack('Vaga criada com sucesso!');
      }
      if (dialogCtx.mounted) Navigator.pop(dialogCtx);
      widget.onRefresh();
    } on ApiException catch (e) {
      _showSnack(e.message);
    } catch (e) {
      _showSnack('Erro: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmCloseJob(Job job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Encerrar Vaga'),
        content: Text(
            'Tem certeza que deseja encerrar "${job.title}"?\n\nVagas encerradas não recebem novos likes ou matches.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Encerrar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.instance.closeJob(job.id);
        _showSnack('Vaga encerrada com sucesso!');
        widget.onRefresh();
      } on ApiException catch (e) {
        _showSnack(e.message);
      }
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 3)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(LucideIcons.briefcase,
                        color: AppColors.primary, size: 26),
                    SizedBox(width: 8),
                    Text(
                      "Minhas Vagas",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: _showCreateJobDialog,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.plus,
                        size: 22, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Job List
          Expanded(
            child: widget.jobs.isNotEmpty
                ? RefreshIndicator(
                    onRefresh: () async => widget.onRefresh(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: widget.jobs.length,
                      itemBuilder: (ctx, i) => _buildJobCard(widget.jobs[i]),
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 96,
                          height: 96,
                          decoration: const BoxDecoration(
                            color: AppColors.gray100,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.briefcase,
                              size: 40, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "Nenhuma vaga cadastrada.",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Crie sua primeira vaga para encontrar candidatos.",
                          style: TextStyle(
                              fontSize: 15, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton.icon(
                          onPressed: _showCreateJobDialog,
                          icon: const Icon(LucideIcons.plus, size: 18),
                          label: const Text("Criar Vaga",
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
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

  Widget _buildJobCard(Job job) {
    final isClosed = job.status == 'CLOSED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isClosed ? Colors.red.shade100 : AppColors.gray200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => widget.onJobClick(job),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      job.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClosed
                          ? Colors.red.shade50
                          : AppColors.greenTagBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isClosed ? 'Encerrada' : 'Ativa',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isClosed
                            ? Colors.red.shade700
                            : AppColors.greenTagText,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.mapPin,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.location,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.building2,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(job.type,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(width: 12),
                  Icon(LucideIcons.banknote,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(job.salary,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isClosed) ...[
                    _actionButton(
                      icon: LucideIcons.pencil,
                      label: 'Editar',
                      color: AppColors.primary,
                      onTap: () => _showEditJobDialog(job),
                    ),
                    const SizedBox(width: 8),
                    _actionButton(
                      icon: LucideIcons.xCircle,
                      label: 'Encerrar',
                      color: Colors.red,
                      onTap: () => _confirmCloseJob(job),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
