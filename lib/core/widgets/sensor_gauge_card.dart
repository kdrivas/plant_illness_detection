import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SensorGaugeCard extends StatelessWidget {
  final String title;
  final double value;
  final double minValue;
  final double maxValue;
  final double? optimalMin;
  final double? optimalMax;
  final String unit;
  final IconData icon;
  final Color color;
  final bool showNoData;

  const SensorGaugeCard({
    super.key,
    required this.title,
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.optimalMin,
    this.optimalMax,
    required this.unit,
    required this.icon,
    required this.color,
    this.showNoData = false,
  });

  @override
  Widget build(BuildContext context) {
    final status = showNoData ? _GaugeStatus.noData : _getStatus();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          const SizedBox(height: 12),
          
          // Gauge
          SizedBox(
            height: 80,
            child: Center(
              child: _GaugePainter(
                value: showNoData ? 0 : value,
                minValue: minValue,
                maxValue: maxValue,
                optimalMin: optimalMin,
                optimalMax: optimalMax,
                color: color,
                showNoData: showNoData,
              ),
            ),
          ),
          
          // Value display
          Center(
            child: showNoData 
              ? Text(
                  '--',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary.withOpacity(0.5),
                  ),
                )
              : RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: _formatValue(),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getValueColor(),
                    ),
                  ),
                  if (unit.isNotEmpty)
                    TextSpan(
                      text: ' $unit',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue() {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  _GaugeStatus _getStatus() {
    if (optimalMin != null && value < optimalMin!) {
      return _GaugeStatus.low;
    }
    if (optimalMax != null && value > optimalMax!) {
      return _GaugeStatus.high;
    }
    return _GaugeStatus.optimal;
  }

  Color _getValueColor() {
    final status = _getStatus();
    switch (status) {
      case _GaugeStatus.optimal:
        return AppColors.primaryGreen;
      case _GaugeStatus.low:
      case _GaugeStatus.high:
        return AppColors.warningAmber;
      case _GaugeStatus.noData:
        return AppColors.textSecondary;
    }
  }
}

enum _GaugeStatus { optimal, low, high, noData }

class _StatusBadge extends StatelessWidget {
  final _GaugeStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    
    switch (status) {
      case _GaugeStatus.optimal:
        color = AppColors.success;
        label = 'Optimal';
        break;
      case _GaugeStatus.low:
        color = AppColors.warningAmber;
        label = 'Low';
        break;
      case _GaugeStatus.high:
        color = AppColors.warningAmber;
        label = 'High';
        break;
      case _GaugeStatus.noData:
        color = AppColors.textSecondary;
        label = 'No Data';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _GaugePainter extends StatelessWidget {
  final double value;
  final double minValue;
  final double maxValue;
  final double? optimalMin;
  final double? optimalMax;
  final Color color;
  final bool showNoData;

  const _GaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.optimalMin,
    this.optimalMax,
    required this.color,
    this.showNoData = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(120, 80),
      painter: _ArcGaugePainter(
        value: value,
        minValue: minValue,
        maxValue: maxValue,
        optimalMin: optimalMin,
        optimalMax: optimalMax,
        color: color,
        showNoData: showNoData,
      ),
    );
  }
}

class _ArcGaugePainter extends CustomPainter {
  final double value;
  final double minValue;
  final double maxValue;
  final double? optimalMin;
  final double? optimalMax;
  final Color color;
  final bool showNoData;

  _ArcGaugePainter({
    required this.value,
    required this.minValue,
    required this.maxValue,
    this.optimalMin,
    this.optimalMax,
    required this.color,
    this.showNoData = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - 10;
    
    // Background arc
    final bgPaint = Paint()
      ..color = showNoData ? AppColors.gaugeBackground.withOpacity(0.5) : AppColors.gaugeBackground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    // Don't draw value arc or optimal range if no data
    if (showNoData) return;

    // Optimal range (if provided)
    if (optimalMin != null && optimalMax != null) {
      final optMinAngle = _valueToAngle(optimalMin!);
      final optMaxAngle = _valueToAngle(optimalMax!);
      
      final optPaint = Paint()
        ..color = AppColors.gaugeOptimal.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi + optMinAngle,
        optMaxAngle - optMinAngle,
        false,
        optPaint,
      );
    }

    // Value arc
    final percentage = ((value - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    final sweepAngle = math.pi * percentage;

    final valuePaint = Paint()
      ..color = _getColor()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      sweepAngle,
      false,
      valuePaint,
    );

    // Needle indicator
    final needleAngle = math.pi + sweepAngle;
    final needleLength = radius - 5;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Center dot
    final dotPaint = Paint()
      ..color = AppColors.textPrimary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 6, dotPaint);
  }

  double _valueToAngle(double val) {
    final percentage = ((val - minValue) / (maxValue - minValue)).clamp(0.0, 1.0);
    return math.pi * percentage;
  }

  Color _getColor() {
    if (optimalMin != null && value < optimalMin!) {
      return AppColors.gaugeWarning;
    }
    if (optimalMax != null && value > optimalMax!) {
      return AppColors.gaugeWarning;
    }
    return color;
  }

  @override
  bool shouldRepaint(covariant _ArcGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
