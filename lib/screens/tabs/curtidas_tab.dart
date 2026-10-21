import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/opportunity_tile.dart';
import '../../widgets/status_view.dart';

class CurtidasTab extends StatelessWidget {
  final List<Job> likedJobs;
  final void Function(Job job) onJobClick;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onExplore;
  final String? errorMessage;

  const CurtidasTab({
    super.key,
    required this.likedJobs,
    required this.onJobClick,
    this.onRefresh,
    this.onExplore,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Vagas curtidas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar curtidas',
                onPressed: onRefresh,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Revisite as oportunidades que chamaram sua atenção.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        if (errorMessage != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '$errorMessage Seus dados anteriores foram mantidos.',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        const SizedBox(height: 16),
        Expanded(
          child: likedJobs.isEmpty
              ? StatusView(
                  title: 'Seu próximo passo começa nas vagas',
                  message: 'Toque em “Tenho interesse” em uma oportunidade. Ela ficará guardada aqui após a confirmação.',
                  actionLabel: onExplore != null
                      ? 'Explorar vagas'
                      : 'Atualizar curtidas',
                  onAction:
                      onExplore ??
                      () {
                        onRefresh?.call();
                      },
                  icon: LucideIcons.heart,
                )
              : RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: likedJobs.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final job = likedJobs[index];
                      return OpportunityTile(
                        title: job.title,
                        company: job.company,
                        logo: job.logo,
                        detail: job.salary,
                        supporting: '${job.type} · ${job.location}',
                        onTap: () => onJobClick(job),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
