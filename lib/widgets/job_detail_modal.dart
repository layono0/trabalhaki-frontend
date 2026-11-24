import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

class JobDetailModal extends StatelessWidget {
  final Job job;
  final VoidCallback onClose;
  final void Function(Job job) onMatch;

  const JobDetailModal({
    super.key,
    required this.job,
    required this.onClose,
    required this.onMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // Sticky Header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    border: Border(
                      bottom: BorderSide(color: AppColors.border),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton.outlined(
                        onPressed: onClose,
                        tooltip: 'Fechar detalhes',
                        icon: const Icon(LucideIcons.chevronDown, size: 22),
                      ),
                      const Text(
                        'Detalhes da vaga',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                ),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Logo & Title
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                margin: const EdgeInsets.only(bottom: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.lg),
                                  border: Border.all(color: AppColors.border),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(
                                  job.logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    color: AppColors.surfaceMuted,
                                    child: const Icon(
                                      LucideIcons.building,
                                      size: 36,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                job.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.ink,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.company,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full-width Salary Banner (prevents truncation of salary ranges)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            border: Border.all(
                              color: AppColors.secondaryText
                                  .withValues(alpha: 0.22),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: const Icon(
                                  LucideIcons.dollarSign,
                                  size: 20,
                                  color: AppColors.secondaryText,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Salário',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      job.salary,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Intrinsic 2-column Metadata Tiles (no fixed aspect ratio clipping)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMetaTile(
                                icon: LucideIcons.mapPin,
                                iconColor: AppColors.primary,
                                label: 'Local',
                                value: job.location,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildMetaTile(
                                icon: LucideIcons.building,
                                iconColor: AppColors.accent,
                                label: 'Modalidade',
                                value: job.type,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildMetaTile(
                                icon: LucideIcons.briefcase,
                                iconColor: AppColors.textSecondary,
                                label: 'Contrato',
                                value: job.contract,
                              ),
                            ),
                            if (job.level.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildMetaTile(
                                  icon: LucideIcons.layers,
                                  iconColor: AppColors.primary,
                                  label: 'Senioridade',
                                  value: job.level,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 22),

                        // Explainable Compatibility Section
                        if (job.compatibilityScore != null ||
                            (job.explanation != null &&
                                job.explanation!.isNotEmpty))
                          _buildCompatibilitySection(),

                        // About Section
                        _buildSectionHeader('Sobre a vaga'),
                        const SizedBox(height: 8),
                        Text(
                          job.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Requirements
                        if (job.requirements.isNotEmpty) ...[
                          _buildSectionHeader('Requisitos'),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: job.requirements.map((req) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primarySoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Text(
                                  req,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Benefits
                        if (job.benefits.isNotEmpty) ...[
                          _buildSectionHeader('Benefícios'),
                          const SizedBox(height: 12),
                          Column(
                            children: job.benefits.map((ben) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      LucideIcons.checkCircle2,
                                      size: 18,
                                      color: AppColors.secondaryText,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        ben,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Fixed Bottom Action Button
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: const Border(
                    top: BorderSide(color: AppColors.border),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      onMatch(job);
                      onClose();
                    },
                    icon: const Icon(LucideIcons.heart, size: 19),
                    label: const Text('Tenho interesse'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    );
  }

  Widget _buildMetaTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompatibilitySection() {
    final explanation = job.explanation;
    final score = job.compatibilityScore;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
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
                    LucideIcons.slidersHorizontal,
                    color: AppColors.primary,
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Compatibilidade',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              if (score != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '$score% match',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (explanation != null && explanation.isNotEmpty) ...[
            if (explanation.containsKey('skills'))
              _buildExplanationRow(
                icon: LucideIcons.code,
                label: 'Habilidades',
                detail: explanation['skills'].toString(),
              ),
            if (explanation.containsKey('experience'))
              _buildExplanationRow(
                icon: LucideIcons.briefcase,
                label: 'Experiência',
                detail: explanation['experience'].toString(),
              ),
            if (explanation.containsKey('salary'))
              _buildExplanationRow(
                icon: LucideIcons.dollarSign,
                label: 'Salário',
                detail: explanation['salary'].toString(),
              ),
            if (explanation.containsKey('modality'))
              _buildExplanationRow(
                icon: LucideIcons.building,
                label: 'Modalidade',
                detail: explanation['modality'].toString(),
              ),
            if (explanation.containsKey('location'))
              _buildExplanationRow(
                icon: LucideIcons.mapPin,
                label: 'Localização',
                detail: explanation['location'].toString(),
              ),
          ] else ...[
            const Text(
              'Esta vaga foi recomendada com base nas competências e preferências do seu perfil.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExplanationRow({
    required IconData icon,
    required String label,
    required String detail,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, size: 15, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
