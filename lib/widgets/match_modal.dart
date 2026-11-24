import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

/// Shows the match modal as a non-persistent, non-blocking dialog route.
/// Tapping outside (barrier) or pressing back automatically closes it cleanly.
Future<void> showMatchModal({
  required BuildContext context,
  required Job job,
  String? candidatePhoto,
  String? candidateName,
  required VoidCallback onChatNow,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar modal de match',
    barrierColor: AppColors.ink.withValues(alpha: 0.65),
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return MatchModal(
        job: job,
        candidatePhoto: candidatePhoto,
        candidateName: candidateName,
        onClose: () => Navigator.of(dialogContext).pop(),
        onChatNow: () {
          Navigator.of(dialogContext).pop();
          onChatNow();
        },
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class MatchModal extends StatefulWidget {
  final Job job;
  final String? candidatePhoto;
  final String? candidateName;
  final VoidCallback onClose;
  final VoidCallback onChatNow;

  const MatchModal({
    super.key,
    required this.job,
    this.candidatePhoto,
    this.candidateName,
    required this.onClose,
    required this.onChatNow,
  });

  @override
  State<MatchModal> createState() => _MatchModalState();
}

class _MatchModalState extends State<MatchModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _leftCardSlide;
  late Animation<Offset> _rightCardSlide;
  late Animation<double> _sealScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _leftCardSlide = Tween<Offset>(
      begin: const Offset(-0.35, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _rightCardSlide = Tween<Offset>(
      begin: const Offset(0.35, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );

    _sealScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.15), weight: 65),
      TweenSequenceItem(tween: Tween<double>(begin: 1.15, end: 1.0), weight: 35),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCandidateMiniCard() {
    final photo = widget.candidatePhoto;
    final name = widget.candidateName?.trim().isNotEmpty == true
        ? widget.candidateName!.trim()
        : 'Você';
    final initial = name[0].toUpperCase();

    return Transform.rotate(
      angle: -3.5 * math.pi / 180,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: photo != null && photo.isNotEmpty
                      ? Image.network(
                          photo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Text(
                          initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.job.compatibilityScore != null
                        ? '${widget.job.compatibilityScore}%'
                        : 'Perfil',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondaryText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Candidato',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobMiniCard() {
    return Transform.rotate(
      angle: 3.5 * math.pi / 180,
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2448),
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: widget.job.logo.isNotEmpty
                      ? Image.network(
                          widget.job.logo,
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            LucideIcons.building,
                            color: AppColors.ink,
                            size: 16,
                          ),
                        )
                      : const Icon(
                          LucideIcons.building,
                          color: AppColors.ink,
                          size: 16,
                        ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'VAGA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.job.company,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.job.salary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC2C9E6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.ink.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Ink Celebration Stage (matches Web MatchCelebrationModal)
                Container(
                  width: double.infinity,
                  color: AppColors.ink,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Stack(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.checkCircle2,
                                  color: AppColors.ink,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'MATCH CONFIRMADO',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Interlocking Candidate + Job cards with crisp central seal
                          SizedBox(
                            height: 114,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SlideTransition(
                                      position: _leftCardSlide,
                                      child: _buildCandidateMiniCard(),
                                    ),
                                    const SizedBox(width: 10),
                                    SlideTransition(
                                      position: _rightCardSlide,
                                      child: _buildJobMiniCard(),
                                    ),
                                  ],
                                ),
                                ScaleTransition(
                                  scale: _sealScale,
                                  child: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.secondary,
                                      borderRadius:
                                          BorderRadius.circular(AppRadii.md),
                                      border: Border.all(
                                        color: AppColors.ink,
                                        width: 3,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      LucideIcons.checkCircle2,
                                      color: AppColors.ink,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Positioned(
                        top: -8,
                        right: -4,
                        child: IconButton(
                          icon: const Icon(
                            LucideIcons.x,
                            color: Color(0xFFC2C9E6),
                            size: 20,
                          ),
                          onPressed: widget.onClose,
                          tooltip: 'Fechar',
                        ),
                      ),
                    ],
                  ),
                ),

                // Light Surface Body & Honest Candidate CTAs
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'É um Match!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                          children: [
                            const TextSpan(text: 'Você e '),
                            TextSpan(
                              text: widget.job.company,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: ' têm interesse mútuo na vaga '),
                            TextSpan(
                              text: widget.job.title,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceMuted,
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                        ),
                        child: const Text(
                          'No Trabalhaki, a empresa envia a primeira mensagem para abrir o chat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: widget.onChatNow,
                          icon: const Icon(LucideIcons.messageCircle, size: 18),
                          label: const Text('Ver conversa'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          onPressed: widget.onClose,
                          child: const Text('Continuar buscando vagas'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
