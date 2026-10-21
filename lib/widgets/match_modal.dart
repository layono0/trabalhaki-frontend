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
    barrierLabel: "Fechar modal de match",
    barrierColor: Colors.black.withValues(alpha: 0.70),
    transitionDuration: const Duration(milliseconds: 350),
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
      final curvedAnimation = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.88, end: 1.0).animate(curvedAnimation),
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
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _leftAvatarSlide;
  late Animation<Offset> _rightAvatarSlide;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _leftAvatarSlide = Tween<Offset>(
      begin: const Offset(-1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _rightAvatarSlide = Tween<Offset>(
      begin: const Offset(1.2, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCandidateAvatar() {
    final photo = widget.candidatePhoto;
    final name = widget.candidateName ?? "Candidato";
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "C";

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null && photo.isNotEmpty
          ? Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildAvatarFallback(initial),
            )
          : _buildAvatarFallback(initial),
    );
  }

  Widget _buildAvatarFallback(String initial) {
    return Container(
      color: const Color(0xFF241571),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompanyAvatar() {
    return Container(
      width: 76,
      height: 76,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: widget.job.logo.isNotEmpty
          ? Image.network(
              widget.job.logo,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                LucideIcons.building,
                color: AppColors.textPrimary,
                size: 30,
              ),
            )
          : const Icon(
              LucideIcons.building,
              color: AppColors.textPrimary,
              size: 30,
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
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF280F9F),
                AppColors.primary,
                Color(0xFF1B0B68),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Content Body
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Celebratory title
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.secondary.withValues(alpha: 0.5),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  LucideIcons.sparkles,
                                  color: AppColors.secondary,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  "MATCH PERFEITO",
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "É um Match!",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Avatars & Heart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SlideTransition(
                          position: _leftAvatarSlide,
                          child: _buildCandidateAvatar(),
                        ),
                        const SizedBox(width: 10),
                        ScaleTransition(
                          scale: _heartScale,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SlideTransition(
                          position: _rightAvatarSlide,
                          child: _buildCompanyAvatar(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Text explanation
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.white70,
                          height: 1.35,
                        ),
                        children: [
                          const TextSpan(text: "Você e a "),
                          TextSpan(
                            text: widget.job.company,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const TextSpan(text: "\ntêm interesse mútuo!"),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.job.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: widget.onChatNow,
                        icon: const Icon(LucideIcons.messageCircle, size: 18),
                        label: const Text(
                          "Conversar agora",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: const Color(0xFF1A1A2E),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: widget.onClose,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white70,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Continuar buscando vagas",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Close icon button at top right (painted on top so it intercepts taps)
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.white70, size: 20),
                  onPressed: widget.onClose,
                  tooltip: "Fechar",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
