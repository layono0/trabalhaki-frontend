import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../models/job.dart';
import '../../theme/app_theme.dart';
import '../../widgets/job_card.dart';

class VagasTab extends StatefulWidget {
  final List<Job> jobs;
  final void Function(Job job, SwipeDirection direction) onSwipe;
  final void Function(Job job) onCardClick;
  final VoidCallback onResetJobs;

  const VagasTab({
    super.key,
    required this.jobs,
    required this.onSwipe,
    required this.onCardClick,
    required this.onResetJobs,
  });

  @override
  State<VagasTab> createState() => _VagasTabState();
}

class _VagasTabState extends State<VagasTab> {
  final GlobalKey<JobCardState> _frontCardKey = GlobalKey<JobCardState>();

  void _handleAction(SwipeDirection direction) {
    if (widget.jobs.isNotEmpty) {
      if (_frontCardKey.currentState != null) {
        _frontCardKey.currentState!.swipeCard(direction);
      } else {
        widget.onSwipe(widget.jobs.first, direction);
      }
    }
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
                    Icon(
                      LucideIcons.briefcase,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Trabalhaki",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gray100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    LucideIcons.slidersHorizontal,
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          // Cards Deck Area
          Expanded(
            child: widget.jobs.isNotEmpty
                ? Stack(
                    children: [
                      // Stack of Cards (reverse order so index 0 is on top)
                      Positioned.fill(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                          child: Stack(
                            children: List.generate(
                              min(widget.jobs.length, 3),
                              (index) {
                                final job = widget.jobs[index];
                                final isFront = index == 0;
                                return Positioned.fill(
                                  child: JobCard(
                                    key: isFront ? _frontCardKey : null,
                                    job: job,
                                    isFront: isFront,
                                    onSwipe: widget.onSwipe,
                                    onClick: () => widget.onCardClick(job),
                                  ),
                                );
                              },
                            ).reversed.toList(),
                          ),
                        ),
                      ),

                      // Floating Bottom Action Controls (Pass, Superlike, Like)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Pass Button (X)
                            _buildActionButton(
                              size: 64,
                              onPressed: () => _handleAction(SwipeDirection.left),
                              icon: LucideIcons.x,
                              iconColor: Colors.red,
                              iconSize: 32,
                              backgroundColor: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),

                            // Superlike Button (Star)
                            _buildActionButton(
                              size: 48,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Superlike enviado! ⭐"),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                                _handleAction(SwipeDirection.right);
                              },
                              icon: Icons.star,
                              iconColor: AppColors.starYellow,
                              iconSize: 24,
                              backgroundColor: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            const SizedBox(width: 20),

                            // Like Button (Heart)
                            _buildActionButton(
                              size: 64,
                              onPressed: () => _handleAction(SwipeDirection.right),
                              icon: Icons.favorite,
                              iconColor: Colors.white,
                              iconSize: 32,
                              backgroundColor: AppColors.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
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
                            child: const Icon(
                              LucideIcons.briefcase,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "Você viu todas as vagas.",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Volte mais tarde para novas oportunidades.",
                            style: TextStyle(
                              fontSize: 15,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 28),
                          ElevatedButton(
                            onPressed: widget.onResetJobs,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gray100,
                              foregroundColor: AppColors.textPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              "Atualizar vagas",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required double size,
    required VoidCallback onPressed,
    required IconData icon,
    required Color iconColor,
    required double iconSize,
    required Color backgroundColor,
    required List<BoxShadow> boxShadow,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          boxShadow: boxShadow,
        ),
        child: Center(
          child: Icon(icon, color: iconColor, size: iconSize),
        ),
      ),
    );
  }
}
