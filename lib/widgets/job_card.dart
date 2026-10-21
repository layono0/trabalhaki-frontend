import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../models/job.dart';
import '../theme/app_theme.dart';

enum SwipeDirection { left, right }

/// Controller to trigger programmatic swipes on the front JobCard.
class JobCardController {
  JobCardState? _state;

  void _attach(JobCardState state) {
    _state = state;
  }

  void _detach(JobCardState state) {
    if (_state == state) {
      _state = null;
    }
  }

  bool get hasAttachedCard => _state != null;

  void swipe(SwipeDirection direction) {
    _state?.swipeCard(direction);
  }
}

class JobCard extends StatefulWidget {
  final Job job;
  final bool isFront;
  final int stackIndex;
  final JobCardController? controller;
  final void Function(Job job, SwipeDirection direction)? onSwipe;
  final VoidCallback? onClick;

  const JobCard({
    required this.job,
    required this.isFront,
    this.stackIndex = 0,
    this.controller,
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
    _animController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 320),
        )..addListener(() {
          if (_offsetAnimation != null) {
            setState(() {
              _dragOffset = _offsetAnimation!.value;
            });
          }
        });

    if (widget.isFront) {
      widget.controller?._attach(this);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animController.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 320);
  }

  @override
  void didUpdateWidget(covariant JobCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        oldWidget.isFront != widget.isFront) {
      oldWidget.controller?._detach(this);
      if (widget.isFront) {
        widget.controller?._attach(this);
      }
    }

    // Reset animation and swipe state whenever a different job is loaded in this state
    if (oldWidget.job.id != widget.job.id) {
      _animController.stop();
      _isSwipingOut = false;
      _dragOffset = Offset.zero;
      _offsetAnimation = null;
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _animController.dispose();
    super.dispose();
  }

  void swipeCard(SwipeDirection direction) {
    if (_isSwipingOut) return;
    _isSwipingOut = true;
    final screenWidth = MediaQuery.maybeOf(context)?.size.width ?? 500.0;
    final targetX = direction == SwipeDirection.right
        ? screenWidth * 1.5
        : -screenWidth * 1.5;

    _offsetAnimation =
        Tween<Offset>(
          begin: _dragOffset,
          end: Offset(targetX, _dragOffset.dy * 1.2),
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
        );

    _animController.forward(from: 0).then((_) {
      if (mounted) {
        widget.onSwipe?.call(widget.job, direction);
      }
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
      // Snap back smoothly
      _offsetAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
          .animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
          );
      _animController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() {
            _dragOffset = Offset.zero;
            _offsetAnimation = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFront) {
      final double yOffset = widget.stackIndex == 1 ? 10.0 : 20.0;
      final double scale = widget.stackIndex == 1 ? 0.96 : 0.92;
      final double opacity = widget.stackIndex == 1 ? 0.85 : 0.70;

      return Transform.translate(
        offset: Offset(0, yOffset),
        child: Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
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
      onHorizontalDragUpdate: _onPanUpdate,
      onHorizontalDragEnd: _onPanEnd,
      onHorizontalDragCancel: () {
        if (!_isSwipingOut) _onPanEnd(DragEndDetails());
      },
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
                            color: AppColors.greenTagText,
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
    final job = widget.job;
    return ExcludeSemantics(
      excluding: !isFrontCard,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 48,
                            height: 48,
                            color: AppColors.gray100,
                            child: Image.network(
                              job.logo,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                              errorBuilder: (_, _, _) => const Icon(
                                LucideIcons.building,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.company,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.postedAt,
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
                    const SizedBox(height: 20),
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.salary,
                      style: const TextStyle(
                        fontSize: 20,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: AppColors.greenTagText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag(LucideIcons.mapPin, job.location),
                        _buildTag(LucideIcons.building, job.type),
                        _buildTag(LucideIcons.briefcase, job.contract),
                        if (job.level.isNotEmpty)
                          _buildTag(LucideIcons.layers, job.level),
                      ],
                    ),
                    if (job.compatibilityScore != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        '${job.compatibilityScore}% de compatibilidade',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    const Text(
                      'Sobre a oportunidade',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job.description.isEmpty
                          ? 'Abra os detalhes para saber mais sobre esta vaga.'
                          : job.description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isFrontCard)
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: widget.onClick,
                  icon: const Icon(LucideIcons.arrowUpRight, size: 18),
                  label: const Text('Ver detalhes da vaga'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.gray50,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}
