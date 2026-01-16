import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/harvest_tracker.dart';
import '../../models/plant_type.dart';
import '../theme/app_colors.dart';

class HarvestProgressRing extends StatelessWidget {
  final HarvestTracker tracker;
  final VoidCallback? onMarkComplete;
  final double size;

  const HarvestProgressRing({
    super.key,
    required this.tracker,
    this.onMarkComplete,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final progress = tracker.progressPercentage;
    final isReady = tracker.isReadyForHarvest;
    
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Progress ring
          CustomPaint(
            size: Size(size, size),
            painter: _ProgressRingPainter(
              progress: progress,
              plantColor: tracker.plantType.color,
              isReady: isReady,
            ),
          ),
          
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tracker.plantType.emoji,
                style: TextStyle(fontSize: size * 0.25),
              ),
              const SizedBox(height: 4),
              if (isReady)
                Text(
                  'Ready!',
                  style: TextStyle(
                    color: AppColors.harvestGold,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.12,
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(
                  duration: 1500.ms,
                  color: AppColors.harvestGold.withOpacity(0.5),
                )
              else
                Text(
                  '${tracker.daysRemaining}d',
                  style: TextStyle(
                    color: tracker.plantType.color,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.14,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color plantColor;
  final bool isReady;

  _ProgressRingPainter({
    required this.progress,
    required this.plantColor,
    required this.isReady,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;
    final strokeWidth = 10.0;

    // Background ring
    final bgPaint = Paint()
      ..color = AppColors.gaugeBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = isReady ? AppColors.harvestGold : plantColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isReady != isReady;
  }
}

class HarvestCard extends StatelessWidget {
  final HarvestTracker tracker;
  final VoidCallback? onMarkComplete;
  final VoidCallback? onTap;

  const HarvestCard({
    super.key,
    required this.tracker,
    this.onMarkComplete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = tracker.isReadyForHarvest;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
          border: isReady
              ? Border.all(color: AppColors.harvestGold, width: 2)
              : null,
        ),
        child: Row(
          children: [
            HarvestProgressRing(
              tracker: tracker,
              size: 80,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tracker.plantType.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tracker.plantType.displayName,
                          style: TextStyle(
                            color: tracker.plantType.color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        tracker.blockId,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isReady 
                        ? 'Ready for Harvest!'
                        : '${tracker.daysRemaining} days remaining',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isReady ? AppColors.harvestGold : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tracker.optimalDaysCount}/${tracker.targetDays} optimal days',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isReady && onMarkComplete != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onMarkComplete,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('Mark Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.harvestGold,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HarvestCompleteDialog extends StatelessWidget {
  final HarvestTracker tracker;

  const HarvestCompleteDialog({super.key, required this.tracker});

  static Future<bool?> show(BuildContext context, HarvestTracker tracker) {
    return showDialog<bool>(
      context: context,
      builder: (context) => HarvestCompleteDialog(tracker: tracker),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Text(tracker.plantType.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Text('Confirm Harvest'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You are about to mark this harvest as complete:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          _InfoRow(label: 'Plant', value: tracker.plantType.displayName),
          _InfoRow(label: 'Block', value: tracker.blockId),
          _InfoRow(label: 'Growing Days', value: '${tracker.growingDays} days'),
          _InfoRow(
            label: 'Optimal Days',
            value: '${tracker.optimalDaysCount}/${tracker.targetDays}',
          ),
          const SizedBox(height: 16),
          Text(
            'This action will reset the harvest tracker for this block.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.check),
          label: const Text('Confirm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.harvestGold,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
