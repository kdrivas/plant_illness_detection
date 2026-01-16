import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/sensor_data.dart';
import '../theme/app_colors.dart';
import '../constants/api_constants.dart';

class SensorLineChart extends StatelessWidget {
  final List<BlockSensorData> data;
  final SensorMetric metric;
  final double? minThreshold;
  final double? maxThreshold;
  final ChartTimeframe timeframe;

  const SensorLineChart({
    super.key,
    required this.data,
    required this.metric,
    this.minThreshold,
    this.maxThreshold,
    this.timeframe = ChartTimeframe.twentyFourHours,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final spots = _createSpots();
    final minY = _calculateMinY(spots);
    final maxY = _calculateMaxY(spots);
    final yRange = maxY - minY;
    final horizontalInterval = yRange > 0 ? yRange / 5 : 1.0;

    return Padding(
      padding: const EdgeInsets.only(right: 16, top: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: horizontalInterval,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppColors.textHint.withOpacity(0.2),
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getXInterval(),
                getTitlesWidget: _bottomTitleWidget,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                interval: horizontalInterval,
                getTitlesWidget: _leftTitleWidget,
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: spots.length.toDouble() - 1,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: metric.color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: spots.length <= 24,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: AppColors.backgroundCard,
                    strokeWidth: 2,
                    strokeColor: metric.color,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    metric.color.withOpacity(0.3),
                    metric.color.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: _createThresholdLines(),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.backgroundDarkCard,
              tooltipRoundedRadius: 8,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final index = spot.spotIndex;
                  final timestamp = index < data.length 
                      ? DateTime.parse(data[index].timestamp) 
                      : DateTime.now();
                  return LineTooltipItem(
                    '${metric.formatValue(spot.y)}\n${_formatTime(timestamp)}',
                    const TextStyle(
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }

  List<FlSpot> _createSpots() {
    return data.asMap().entries.map((entry) {
      final value = metric.getValue(entry.value);
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  double _calculateMinY(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    double min = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    if (minThreshold != null && minThreshold! < min) {
      min = minThreshold!;
    }
    return (min - (min.abs() * 0.1)).clamp(0, double.infinity);
  }

  double _calculateMaxY(List<FlSpot> spots) {
    if (spots.isEmpty) return 100;
    double max = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    if (maxThreshold != null && maxThreshold! > max) {
      max = maxThreshold!;
    }
    // Ensure max is at least a small value to prevent zero range
    if (max <= 0) max = 10;
    return max + (max * 0.1);
  }

  List<HorizontalLine> _createThresholdLines() {
    final lines = <HorizontalLine>[];
    
    if (minThreshold != null) {
      lines.add(HorizontalLine(
        y: minThreshold!,
        color: AppColors.warningAmber.withOpacity(0.7),
        strokeWidth: 2,
        dashArray: [8, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: const TextStyle(
            color: AppColors.warningAmber,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          labelResolver: (_) => 'Min',
        ),
      ));
    }
    
    if (maxThreshold != null) {
      lines.add(HorizontalLine(
        y: maxThreshold!,
        color: AppColors.warningAmber.withOpacity(0.7),
        strokeWidth: 2,
        dashArray: [8, 4],
        label: HorizontalLineLabel(
          show: true,
          alignment: Alignment.topRight,
          style: const TextStyle(
            color: AppColors.warningAmber,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          labelResolver: (_) => 'Max',
        ),
      ));
    }
    
    return lines;
  }

  double _getXInterval() {
    final count = data.length;
    if (count <= 12) return 1;
    if (count <= 24) return 2;
    if (count <= 48) return 4;
    return (count / 6).ceilToDouble();
  }

  Widget _bottomTitleWidget(double value, TitleMeta meta) {
    final index = value.toInt();
    if (index < 0 || index >= data.length) {
      return const SizedBox.shrink();
    }
    
    final timestamp = DateTime.parse(data[index].timestamp);
    final text = _formatTimeShort(timestamp);
    
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textHint,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        metric.formatValue(value),
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeShort(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }
}

/// Sensor metric configuration
enum SensorMetric {
  ph,
  ec,
  waterTemp,
  humidity,
  weatherTemp,
  uv,
  voc,
  moisture,
  waterSupplied,
}

extension SensorMetricExtension on SensorMetric {
  String get displayName {
    switch (this) {
      case SensorMetric.ph:
        return 'pH Level';
      case SensorMetric.ec:
        return 'EC Level';
      case SensorMetric.waterTemp:
        return 'Water Temp';
      case SensorMetric.humidity:
        return 'Humidity';
      case SensorMetric.weatherTemp:
        return 'Air Temp';
      case SensorMetric.uv:
        return 'UV Index';
      case SensorMetric.voc:
        return 'VOC Index';
      case SensorMetric.moisture:
        return 'Soil Moisture';
      case SensorMetric.waterSupplied:
        return 'Water Supplied';
    }
  }

  String get unit {
    switch (this) {
      case SensorMetric.ph:
        return '';
      case SensorMetric.ec:
        return 'mS/cm';
      case SensorMetric.waterTemp:
      case SensorMetric.weatherTemp:
        return '°C';
      case SensorMetric.humidity:
      case SensorMetric.moisture:
        return '%';
      case SensorMetric.uv:
        return '';
      case SensorMetric.voc:
        return '';
      case SensorMetric.waterSupplied:
        return 'L';
    }
  }

  Color get color {
    switch (this) {
      case SensorMetric.ph:
        return AppColors.chartPh;
      case SensorMetric.ec:
        return AppColors.chartEc;
      case SensorMetric.waterTemp:
        return AppColors.chartWaterTemp;
      case SensorMetric.humidity:
        return AppColors.chartHumidity;
      case SensorMetric.weatherTemp:
        return AppColors.chartWeatherTemp;
      case SensorMetric.uv:
        return AppColors.chartUv;
      case SensorMetric.voc:
        return AppColors.chartVoc;
      case SensorMetric.moisture:
        return AppColors.chartMoisture;
      case SensorMetric.waterSupplied:
        return AppColors.chartWaterSupplied;
    }
  }

  IconData get icon {
    switch (this) {
      case SensorMetric.ph:
        return Icons.science_outlined;
      case SensorMetric.ec:
        return Icons.electric_bolt_outlined;
      case SensorMetric.waterTemp:
        return Icons.waves_outlined;
      case SensorMetric.humidity:
        return Icons.water_drop_outlined;
      case SensorMetric.weatherTemp:
        return Icons.thermostat_outlined;
      case SensorMetric.uv:
        return Icons.wb_sunny_outlined;
      case SensorMetric.voc:
        return Icons.air_outlined;
      case SensorMetric.moisture:
        return Icons.grass_outlined;
      case SensorMetric.waterSupplied:
        return Icons.water_outlined;
    }
  }

  double getValue(BlockSensorData data) {
    switch (this) {
      case SensorMetric.ph:
        return data.phLevel;
      case SensorMetric.ec:
        return data.ecLevel;
      case SensorMetric.waterTemp:
        return data.waterTemp;
      case SensorMetric.humidity:
        return data.humidity;
      case SensorMetric.weatherTemp:
        return data.weatherTemp;
      case SensorMetric.uv:
        return data.uvIndex;
      case SensorMetric.voc:
        return data.vocIndex.toDouble();
      case SensorMetric.moisture:
        return data.moisture;
      case SensorMetric.waterSupplied:
        return data.waterSupplied;
    }
  }

  String formatValue(double value) {
    switch (this) {
      case SensorMetric.ph:
        return value.toStringAsFixed(1);
      case SensorMetric.ec:
        return value.toStringAsFixed(2);
      case SensorMetric.waterTemp:
      case SensorMetric.weatherTemp:
        return '${value.toStringAsFixed(1)}°';
      case SensorMetric.humidity:
      case SensorMetric.moisture:
        return '${value.toStringAsFixed(0)}%';
      case SensorMetric.uv:
        return value.toStringAsFixed(1);
      case SensorMetric.voc:
        return value.toStringAsFixed(0);
      case SensorMetric.waterSupplied:
        return '${value.toStringAsFixed(1)}L';
    }
  }

  double get optimalMin {
    switch (this) {
      case SensorMetric.ph:
        return 5.5;
      case SensorMetric.ec:
        return 1.0;
      case SensorMetric.waterTemp:
        return 18.0;
      case SensorMetric.humidity:
        return 40.0;
      case SensorMetric.weatherTemp:
        return 18.0;
      case SensorMetric.uv:
        return 3.0;
      case SensorMetric.voc:
        return 0.0;
      case SensorMetric.moisture:
        return 40.0;
      case SensorMetric.waterSupplied:
        return 0.0;
    }
  }

  double get optimalMax {
    switch (this) {
      case SensorMetric.ph:
        return 7.0;
      case SensorMetric.ec:
        return 2.5;
      case SensorMetric.waterTemp:
        return 24.0;
      case SensorMetric.humidity:
        return 70.0;
      case SensorMetric.weatherTemp:
        return 28.0;
      case SensorMetric.uv:
        return 6.0;
      case SensorMetric.voc:
        return 100.0;
      case SensorMetric.moisture:
        return 70.0;
      case SensorMetric.waterSupplied:
        return 100.0;
    }
  }

  bool isOptimal(double value) {
    return value >= optimalMin && value <= optimalMax;
  }
}
