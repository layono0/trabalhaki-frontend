import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/opportunity_tile.dart';
import '../../widgets/status_view.dart';

class MatchesTab extends StatelessWidget {
  final List<MatchItem> matches;
  final void Function(MatchItem match) onSelectMatch;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onExplore;
  final String? errorMessage;

  const MatchesTab({
    super.key,
    required this.matches,
    required this.onSelectMatch,
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
                  'Seus matches',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar matches',
                onPressed: onRefresh,
                icon: const Icon(LucideIcons.refreshCw, size: 20),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'O interesse foi mútuo. Agora vocês podem conversar.',
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
          child: matches.isEmpty
              ? StatusView(
                  title: 'As próximas conversas começam aqui',
                  message: 'Quando você e uma empresa demonstrarem interesse, o match aparecerá aqui para iniciar a conversa.',
                  actionLabel: onExplore != null
                      ? 'Explorar vagas'
                      : 'Atualizar matches',
                  onAction:
                      onExplore ??
                      () {
                        onRefresh?.call();
                      },
                  icon: LucideIcons.messageCircle,
                )
              : RefreshIndicator(
                  onRefresh: onRefresh ?? () async {},
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: matches.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final match = matches[index];
                      return OpportunityTile(
                        title: match.title,
                        company: match.company,
                        logo: match.logo,
                        detail: 'Abrir conversa',
                        supporting: match.date,
                        icon: LucideIcons.messageCircle,
                        onTap: () => onSelectMatch(match),
                      );
                    },
                  ),
                ),
        ),
      ],
    ),
  );
}
