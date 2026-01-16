import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/api_constants.dart';
import 'plant_type.dart';

/// Types of alerts the system can generate
enum AlertType {
  harvestReady,
  phWarning,
  ecWarning,
  temperatureWarning,
  humidityWarning,
  uvWarning,
  vocWarning,
  waterTempWarning,
  generalInfo,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.harvestReady:
        return 'Harvest Ready';
      case AlertType.phWarning:
        return 'pH Level Alert';
      case AlertType.ecWarning:
        return 'EC Level Alert';
      case AlertType.temperatureWarning:
        return 'Temperature Alert';
      case AlertType.humidityWarning:
        return 'Humidity Alert';
      case AlertType.uvWarning:
        return 'UV Index Alert';
      case AlertType.vocWarning:
        return 'VOC Level Alert';
      case AlertType.waterTempWarning:
        return 'Water Temperature Alert';
      case AlertType.generalInfo:
        return 'Information';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.harvestReady:
        return Icons.agriculture_rounded;
      case AlertType.phWarning:
        return Icons.science_rounded;
      case AlertType.ecWarning:
        return Icons.electric_bolt_rounded;
      case AlertType.temperatureWarning:
        return Icons.thermostat_rounded;
      case AlertType.humidityWarning:
        return Icons.water_drop_rounded;
      case AlertType.uvWarning:
        return Icons.wb_sunny_rounded;
      case AlertType.vocWarning:
        return Icons.air_rounded;
      case AlertType.waterTempWarning:
        return Icons.waves_rounded;
      case AlertType.generalInfo:
        return Icons.info_outline_rounded;
    }
  }

  Color getColor(AlertSeverity severity) {
    if (this == AlertType.harvestReady) {
      return AppColors.harvestGold;
    }
    switch (severity) {
      case AlertSeverity.info:
        return AppColors.info;
      case AlertSeverity.warning:
        return AppColors.warningAmber;
      case AlertSeverity.critical:
        return AppColors.criticalRed;
    }
  }
}

/// Plant alert model
class PlantAlert {
  final String id;
  final String blockId;
  final PlantType? plantType;
  final AlertType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final String? recommendation;
  final double? currentValue;
  final double? optimalMin;
  final double? optimalMax;
  final DateTime timestamp;
  final bool isDismissed;
  final int consecutiveReadings;

  PlantAlert({
    required this.id,
    required this.blockId,
    this.plantType,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.recommendation,
    this.currentValue,
    this.optimalMin,
    this.optimalMax,
    required this.timestamp,
    this.isDismissed = false,
    this.consecutiveReadings = 1,
  });

  factory PlantAlert.fromJson(Map<String, dynamic> json) {
    return PlantAlert(
      id: json['id'] ?? '',
      blockId: json['blockId'] ?? json['block_id'] ?? '',
      plantType: json['plantType'] != null
          ? PlantType.values.firstWhere(
              (e) => e.name == json['plantType'],
              orElse: () => PlantType.lettuce,
            )
          : null,
      type: AlertType.values.firstWhere(
        (e) => e.name == (json['type'] ?? json['alert_type']),
        orElse: () => AlertType.generalInfo,
      ),
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      recommendation: json['recommendation'],
      currentValue: json['currentValue']?.toDouble() ?? json['current_value']?.toDouble(),
      optimalMin: json['optimalMin']?.toDouble() ?? json['optimal_min']?.toDouble(),
      optimalMax: json['optimalMax']?.toDouble() ?? json['optimal_max']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isDismissed: json['isDismissed'] ?? json['is_dismissed'] ?? false,
      consecutiveReadings: json['consecutiveReadings'] ?? json['consecutive_readings'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockId': blockId,
      'plantType': plantType?.name,
      'type': type.name,
      'severity': severity.name,
      'title': title,
      'message': message,
      'recommendation': recommendation,
      'currentValue': currentValue,
      'optimalMin': optimalMin,
      'optimalMax': optimalMax,
      'timestamp': timestamp.toIso8601String(),
      'isDismissed': isDismissed,
      'consecutiveReadings': consecutiveReadings,
    };
  }

  PlantAlert copyWith({
    String? id,
    String? blockId,
    PlantType? plantType,
    AlertType? type,
    AlertSeverity? severity,
    String? title,
    String? message,
    String? recommendation,
    double? currentValue,
    double? optimalMin,
    double? optimalMax,
    DateTime? timestamp,
    bool? isDismissed,
    int? consecutiveReadings,
  }) {
    return PlantAlert(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      plantType: plantType ?? this.plantType,
      type: type ?? this.type,
      severity: severity ?? this.severity,
      title: title ?? this.title,
      message: message ?? this.message,
      recommendation: recommendation ?? this.recommendation,
      currentValue: currentValue ?? this.currentValue,
      optimalMin: optimalMin ?? this.optimalMin,
      optimalMax: optimalMax ?? this.optimalMax,
      timestamp: timestamp ?? this.timestamp,
      isDismissed: isDismissed ?? this.isDismissed,
      consecutiveReadings: consecutiveReadings ?? this.consecutiveReadings,
    );
  }
}

/// Alert threshold configuration per plant type
class AlertThreshold {
  final PlantType plantType;
  final double phMin;
  final double phMax;
  final double ecMin;
  final double ecMax;
  final double waterTempMin;
  final double waterTempMax;
  final double humidityMin;
  final double humidityMax;
  final double weatherTempMin;
  final double weatherTempMax;
  final double uvMin;
  final double uvMax;
  final int vocMax;

  const AlertThreshold({
    required this.plantType,
    required this.phMin,
    required this.phMax,
    required this.ecMin,
    required this.ecMax,
    required this.waterTempMin,
    required this.waterTempMax,
    required this.humidityMin,
    required this.humidityMax,
    required this.weatherTempMin,
    required this.weatherTempMax,
    required this.uvMin,
    required this.uvMax,
    required this.vocMax,
  });

  factory AlertThreshold.forPlant(PlantType plantType) {
    switch (plantType) {
      case PlantType.lettuce:
        return const AlertThreshold(
          plantType: PlantType.lettuce,
          phMin: 6.0,
          phMax: 7.0,
          ecMin: 0.8,
          ecMax: 1.2,
          waterTempMin: 18.0,
          waterTempMax: 22.0,
          humidityMin: 50.0,
          humidityMax: 70.0,
          weatherTempMin: 15.0,
          weatherTempMax: 24.0,
          uvMin: 2.0,
          uvMax: 6.0,
          vocMax: 100,
        );
      case PlantType.strawberry:
        return const AlertThreshold(
          plantType: PlantType.strawberry,
          phMin: 5.5,
          phMax: 6.5,
          ecMin: 1.0,
          ecMax: 1.5,
          waterTempMin: 18.0,
          waterTempMax: 24.0,
          humidityMin: 60.0,
          humidityMax: 75.0,
          weatherTempMin: 15.0,
          weatherTempMax: 26.0,
          uvMin: 3.0,
          uvMax: 8.0,
          vocMax: 100,
        );
      case PlantType.blueberry:
        return const AlertThreshold(
          plantType: PlantType.blueberry,
          phMin: 4.5,
          phMax: 5.5,
          ecMin: 1.2,
          ecMax: 1.8,
          waterTempMin: 15.0,
          waterTempMax: 21.0,
          humidityMin: 60.0,
          humidityMax: 80.0,
          weatherTempMin: 12.0,
          weatherTempMax: 25.0,
          uvMin: 4.0,
          uvMax: 10.0,
          vocMax: 80,
        );
    }
  }

  factory AlertThreshold.fromJson(Map<String, dynamic> json) {
    return AlertThreshold(
      plantType: PlantType.values.firstWhere(
        (e) => e.name == json['plantType'],
        orElse: () => PlantType.lettuce,
      ),
      phMin: (json['phMin'] ?? json['ph_min'] ?? 6.0).toDouble(),
      phMax: (json['phMax'] ?? json['ph_max'] ?? 7.0).toDouble(),
      ecMin: (json['ecMin'] ?? json['ec_min'] ?? 0.8).toDouble(),
      ecMax: (json['ecMax'] ?? json['ec_max'] ?? 1.2).toDouble(),
      waterTempMin: (json['waterTempMin'] ?? json['water_temp_min'] ?? 18.0).toDouble(),
      waterTempMax: (json['waterTempMax'] ?? json['water_temp_max'] ?? 22.0).toDouble(),
      humidityMin: (json['humidityMin'] ?? json['humidity_min'] ?? 50.0).toDouble(),
      humidityMax: (json['humidityMax'] ?? json['humidity_max'] ?? 70.0).toDouble(),
      weatherTempMin: (json['weatherTempMin'] ?? json['weather_temp_min'] ?? 15.0).toDouble(),
      weatherTempMax: (json['weatherTempMax'] ?? json['weather_temp_max'] ?? 24.0).toDouble(),
      uvMin: (json['uvMin'] ?? json['uv_min'] ?? 2.0).toDouble(),
      uvMax: (json['uvMax'] ?? json['uv_max'] ?? 6.0).toDouble(),
      vocMax: json['vocMax'] ?? json['voc_max'] ?? 100,
    );
  }
}
