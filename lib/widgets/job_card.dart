import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/job.dart';
import '../theme/app_theme.dart';

enum SwipeDirection { left, right }

class JobCard extends StatefulWidget {
  final Job job;
  final bool isFront;
  final void Function(Job job, SwipeDirection direction)? onSwipe;
  final VoidCallback? onClick;

  const JobCard({
    required this.job,
    required this.isFront,
    this.onSwipe,
    this.onClick,
    super.key,
  });

  @override
  State<JobCard> createState() => JobCardState();
}

class JobCardState extends State<JobCard> with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _animController;
  Animation<Offset>? _offsetAnimation;
  bool _isSwipingOut = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_offsetAnimation != null) {
          setState(() {
            _dragOffset = _offsetAnimation!.value;
          });
        }
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void swipeCard(SwipeDirection direction) {
    if (_isSwipingOut) return;
    _isSwipingOut = true;
    final targetX = direction == SwipeDirection.right ? 600.0 : -600.0;

    _offsetAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(targetX, _dragOffset.dy),
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _animController.forward(from: 0).then((_) {
      widget.onSwipe?.call(widget.job, direction);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isFront || _isSwipingOut) return;
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isFront || _isSwipingOut) return;

    if (_dragOffset.dx > 100) {
      swipeCard(SwipeDirection.right);
    } else if (_dragOffset.dx < -100) {
      swipeCard(SwipeDirection.left);
    } else {
      // Snap back
      _offsetAnimation = Tween<Offset>(
        begin: _dragOffset,
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
      );
      _animController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFront) {
      return Transform.translate(
        offset: const Offset(0, 10),
        child: Transform.scale(
          scale: 0.95,
          child: Opacity(
            opacity: 0.8,
            child: _buildCardContent(isFrontCard: false),
          ),
        ),
      );
    }

    final rotationAngle =
        (_dragOffset.dx / 200).clamp(-1.0, 1.0) * (15 * math.pi / 180);
    final likeOpacity = (_dragOffset.dx / 100).clamp(0.0, 1.0);
    final passOpacity = (-_dragOffset.dx / 100).clamp(0.0, 1.0);

    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onTap: widget.onClick,
      child: Transform.translate(
        offset: _dragOffset,
        child: Transform.rotate(
          angle: rotationAngle,
          alignment: Alignment.bottomCenter,
          child: Stack(
            children: [
              _buildCardContent(isFrontCard: true),
              // LIKE STAMP ("INTERESSADO")
              if (likeOpacity > 0)
                Positioned(
                  top: 32,
                  left: 32,
                  child: Opacity(
                    opacity: likeOpacity,
                    child: Transform.rotate(
                      angle: -15 * math.pi / 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.secondary,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "INTERESSADO",
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // PASS STAMP ("PASSAR")
              if (passOpacity > 0)
                Positioned(
                  top: 32,
                  right: 32,
                  child: Opacity(
                    opacity: passOpacity,
                    child: Transform.rotate(
                      angle: 15 * math.pi / 180,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.redPass,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "PASSAR",
                          style: TextStyle(
                            color: AppColors.redPass,
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent({required bool isFrontCard}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppColors.gray100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company logo & PostedAt
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.gray100,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.network(
                      widget.job.logo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        LucideIcons.building,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      if (widget.job.compatibilityScore != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            "${widget.job.compatibilityScore}% match",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gray50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.job.postedAt,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                widget.job.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),

              // Company name
              Text(
                widget.job.company,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Badges / Tags
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTag(
                    icon: LucideIcons.dollarSign,
                    label: widget.job.salary,
                    bgColor: AppColors.greenTagBg,
                    textColor: AppColors.greenTagText,
                  ),
                  _buildTag(
                    icon: LucideIcons.mapPin,
                    label: widget.job.location,
                    bgColor: AppColors.blueTagBg,
                    textColor: AppColors.blueTagText,
                  ),
                  _buildTag(
                    icon: LucideIcons.building,
                    label: widget.job.type,
                    bgColor: AppColors.purpleTagBg,
                    textColor: AppColors.purpleTagText,
                  ),
                  _buildTag(
                    icon: LucideIcons.briefcase,
                    label: widget.job.contract,
                    bgColor: AppColors.gray100,
                    textColor: const Color(0xFF374151),
                  ),
                ],
              ),

              const Spacer(),

              // Resumo section
              const Text(
                "Resumo",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.job.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
