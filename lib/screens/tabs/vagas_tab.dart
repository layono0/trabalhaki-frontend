import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';
import '../../widgets/status_view.dart';

class VagasTab extends StatefulWidget {
  final List<Job> jobs;
  final void Function(Job job, SwipeDirection direction) onSwipe;
  final void Function(Job job) onCardClick;
  final VoidCallback onResetJobs;
  final void Function({String? modality, String? state, double? minSalary})?
  onApplyFilters;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? activeModality;
  final String? activeState;
  final double? activeMinSalary;
  final VoidCallback? onUndo;

  const VagasTab({
    super.key,
    required this.jobs,
    required this.onSwipe,
    required this.onCardClick,
    required this.onResetJobs,
    this.onApplyFilters,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.activeModality,
    this.activeState,
    this.activeMinSalary,
    this.onUndo,
  });

  @override
  State<VagasTab> createState() => _VagasTabState();
}

class _VagasTabState extends State<VagasTab> {
  final JobCardController _cardController = JobCardController();
  bool get _hasActiveFilters =>
      widget.activeModality != null ||
      widget.activeState != null ||
      widget.activeMinSalary != null;
  bool get _busy => widget.isLoading || widget.isSubmitting;

  void _handleAction(SwipeDirection direction) {
    if (_busy || widget.jobs.isEmpty) return;
    if (_cardController.hasAttachedCard) {
      _cardController.swipe(direction);
    } else {
      widget.onSwipe(widget.jobs.first, direction);
    }
  }

  Future<void> _showFilters() async {
    String? modality = widget.activeModality;
    String? state = widget.activeState;
    double? minSalary = widget.activeMinSalary;
    const states = [
      'AC',
      'AL',
      'AP',
      'AM',
      'BA',
      'CE',
      'DF',
      'ES',
      'GO',
      'MA',
      'MT',
      'MS',
      'MG',
      'PA',
      'PB',
      'PR',
      'PE',
      'PI',
      'RJ',
      'RN',
      'RS',
      'RO',
      'RR',
      'SC',
      'SP',
      'SE',
      'TO',
    ];
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            0,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrar vagas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => update(() {
                      modality = null;
                      state = null;
                      minSalary = null;
                    }),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Modalidade de trabalho',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final entry in const <String, String>{
                    '': 'Todas',
                    'REMOTE': 'Remoto',
                    'HYBRID': 'Híbrido',
                    'ONSITE': 'Presencial',
                  }.entries)
                    ChoiceChip(
                      label: Text(entry.value),
                      selected: (modality ?? '') == entry.key,
                      onSelected: (_) => update(
                        () => modality = entry.key.isEmpty ? null : entry.key,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<double>(
                key: ValueKey('salary_$minSalary'),
                initialValue: minSalary,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Salário mínimo'),
                items: const [
                  DropdownMenuItem<double>(
                    value: null,
                    child: Text('Qualquer faixa salarial'),
                  ),
                  DropdownMenuItem(
                    value: 3000,
                    child: Text('A partir de R\$ 3.000'),
                  ),
                  DropdownMenuItem(
                    value: 5000,
                    child: Text('A partir de R\$ 5.000'),
                  ),
                  DropdownMenuItem(
                    value: 8000,
                    child: Text('A partir de R\$ 8.000'),
                  ),
                  DropdownMenuItem(
                    value: 12000,
                    child: Text('A partir de R\$ 12.000'),
                  ),
                ],
                onChanged: (value) => update(() => minSalary = value),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey('state_$state'),
                initialValue: state,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Estado (UF)'),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Todos os estados'),
                  ),
                  for (final uf in states)
                    DropdownMenuItem(value: uf, child: Text(uf)),
                ],
                onChanged: (value) => update(() => state = value),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    widget.onApplyFilters?.call(
                      modality: modality,
                      state: state,
                      minSalary: minSalary,
                    );
                  },
                  child: const Text('Aplicar filtros'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearFilters() => widget.onApplyFilters?.call();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Large text and short windows need document scrolling, not a squeezed deck.
      final scrolls =
          constraints.maxHeight < 520 ||
          MediaQuery.textScalerOf(context).scale(16) > 22;
      final content = SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vagas para você',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      IconButton.filledTonal(
                        tooltip: _hasActiveFilters
                            ? 'Editar filtros ativos'
                            : 'Filtrar vagas',
                        onPressed: _busy ? null : _showFilters,
                        icon: Icon(
                          _hasActiveFilters
                              ? LucideIcons.listFilter
                              : LucideIcons.slidersHorizontal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasActiveFilters)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (widget.activeModality != null)
                            _filterLabel(
                              const {
                                    'REMOTE': 'Remoto',
                                    'HYBRID': 'Híbrido',
                                    'ONSITE': 'Presencial',
                                  }[widget.activeModality] ??
                                  widget.activeModality!,
                            ),
                          if (widget.activeState != null)
                            _filterLabel(widget.activeState!),
                          if (widget.activeMinSalary != null)
                            _filterLabel(
                              'R\$ ${widget.activeMinSalary!.toInt()}+',
                            ),
                          TextButton(
                            onPressed: _busy ? null : _clearFilters,
                            child: const Text('Limpar filtros'),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (scrolls)
                  SizedBox(height: 420, child: _buildDeck())
                else
                  Expanded(child: _buildDeck()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton.outlined(
                            tooltip: 'Desfazer último descarte',
                            onPressed: _busy ? null : widget.onUndo,
                            icon: const Icon(LucideIcons.undo2, size: 20),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                                  _busy ||
                                      widget.jobs.isEmpty ||
                                      widget.error != null
                                  ? null
                                  : () => _handleAction(SwipeDirection.left),
                              icon: const Icon(LucideIcons.x, size: 18),
                              label: const Text('Pular'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              onPressed:
                                  _busy ||
                                      widget.jobs.isEmpty ||
                                      widget.error != null
                                  ? null
                                  : () => _handleAction(SwipeDirection.right),
                              icon: widget.isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.favorite, size: 18),
                              label: Text(
                                widget.isSubmitting
                                    ? 'Enviando…'
                                    : 'Tenho interesse',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.isSubmitting
                            ? 'Confirmando seu interesse…'
                            : 'Suas vagas de interesse ficam em Curtidas.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return scrolls ? SingleChildScrollView(child: content) : content;
    },
  );

  Widget _filterLabel(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.primary, fontSize: 13),
    ),
  );

  Widget _buildDeck() {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Buscando oportunidades…'),
          ],
        ),
      );
    }
    if (widget.error != null) {
      return StatusView(
        title: 'Não foi possível carregar as vagas',
        message: widget.error!,
        actionLabel: 'Tentar novamente',
        onAction: widget.onResetJobs,
        icon: LucideIcons.wifiOff,
      );
    }
    if (widget.isSubmitting && widget.jobs.isEmpty) {
      return const Center(
        child: Text(
          'Registrando seu interesse…',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    if (widget.jobs.isEmpty) {
      return StatusView(
        title: _hasActiveFilters
            ? 'Nenhuma vaga com esses filtros'
            : 'Você viu todas as vagas.',
        message: _hasActiveFilters
            ? 'Experimente outra modalidade, estado ou faixa salarial.'
            : 'Você pode desfazer o último descarte ou voltar depois para ver novas oportunidades.',
        actionLabel: _hasActiveFilters ? 'Limpar filtros' : 'Atualizar vagas',
        onAction: _hasActiveFilters ? _clearFilters : widget.onResetJobs,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: IgnorePointer(
        ignoring: widget.isSubmitting,
        child: Stack(
          children: List.generate(min(widget.jobs.length, 3), (index) {
            final job = widget.jobs[index];
            return Positioned.fill(
              child: JobCard(
                key: ValueKey('job_${job.id}'),
                job: job,
                isFront: index == 0,
                stackIndex: index,
                controller: index == 0 ? _cardController : null,
                onSwipe: widget.onSwipe,
                onClick: () => widget.onCardClick(job),
              ),
            );
          }).reversed.toList(),
        ),
      ),
    );
  }
}
