import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/sensor_data.dart';
import '../models/plant_alert.dart';
import '../models/plant_type.dart';
import '../core/constants/api_constants.dart';

class AlertService {
  final http.Client _client;
  final Map<String, List<_ReadingTracker>> _readingTrackers = {};
  final _uuid = const Uuid();

  AlertService({http.Client? client}) : _client = client ?? http.Client();

  /// Fetch alerts from API, falls back to client-side evaluation
  Future<List<PlantAlert>> getAlerts(String blockId, {PlantType? plantType}) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.blockAlertsEndpoint(blockId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => PlantAlert.fromJson(item)).toList();
      }
    } catch (e) {
      // Fall through to client-side evaluation
    }
    
    return [];
  }

  /// Evaluate sensor data and generate alerts based on sustained readings
  List<PlantAlert> evaluateSensorData(
    BlockSensorData data,
    PlantType plantType,
  ) {
    final threshold = AlertThreshold.forPlant(plantType);
    final alerts = <PlantAlert>[];
    final blockId = data.blockId;

    // Initialize tracker for this block if needed
    _readingTrackers[blockId] ??= [];

    // Check each sensor value
    _checkAndTrack(
      blockId: blockId,
      type: AlertType.phWarning,
      value: data.phLevel,
      min: threshold.phMin,
      max: threshold.phMax,
      plantType: plantType,
      unit: '',
      alerts: alerts,
    );

    _checkAndTrack(
      blockId: blockId,
      type: AlertType.ecWarning,
      value: data.ecLevel,
      min: threshold.ecMin,
      max: threshold.ecMax,
      plantType: plantType,
      unit: 'mS/cm',
      alerts: alerts,
    );

    _checkAndTrack(
      blockId: blockId,
      type: AlertType.waterTempWarning,
      value: data.waterTemp,
      min: threshold.waterTempMin,
      max: threshold.waterTempMax,
      plantType: plantType,
      unit: '°C',
      alerts: alerts,
    );

    _checkAndTrack(
      blockId: blockId,
      type: AlertType.humidityWarning,
      value: data.humidity,
      min: threshold.humidityMin,
      max: threshold.humidityMax,
      plantType: plantType,
      unit: '%',
      alerts: alerts,
    );

    _checkAndTrack(
      blockId: blockId,
      type: AlertType.temperatureWarning,
      value: data.weatherTemp,
      min: threshold.weatherTempMin,
      max: threshold.weatherTempMax,
      plantType: plantType,
      unit: '°C',
      alerts: alerts,
    );

    _checkAndTrack(
      blockId: blockId,
      type: AlertType.uvWarning,
      value: data.uvIndex,
      min: threshold.uvMin,
      max: threshold.uvMax,
      plantType: plantType,
      unit: '',
      alerts: alerts,
    );

    // VOC only has max threshold
    if (data.vocIndex > threshold.vocMax) {
      _trackReading(blockId, AlertType.vocWarning, true);
      final consecutiveCount = _getConsecutiveCount(blockId, AlertType.vocWarning);
      
      if (consecutiveCount >= AppConstants.sustainedReadingThreshold) {
        alerts.add(_createAlert(
          blockId: blockId,
          type: AlertType.vocWarning,
          plantType: plantType,
          currentValue: data.vocIndex.toDouble(),
          optimalMin: 0,
          optimalMax: threshold.vocMax.toDouble(),
          consecutiveReadings: consecutiveCount,
          isHigh: true,
          unit: '',
        ));
      }
    } else {
      _trackReading(blockId, AlertType.vocWarning, false);
    }

    // Clean up old trackers
    _cleanupTrackers();

    return alerts;
  }

  void _checkAndTrack({
    required String blockId,
    required AlertType type,
    required double value,
    required double min,
    required double max,
    required PlantType plantType,
    required String unit,
    required List<PlantAlert> alerts,
  }) {
    final isOutOfRange = value < min || value > max;
    _trackReading(blockId, type, isOutOfRange);

    if (isOutOfRange) {
      final consecutiveCount = _getConsecutiveCount(blockId, type);
      
      if (consecutiveCount >= AppConstants.sustainedReadingThreshold) {
        alerts.add(_createAlert(
          blockId: blockId,
          type: type,
          plantType: plantType,
          currentValue: value,
          optimalMin: min,
          optimalMax: max,
          consecutiveReadings: consecutiveCount,
          isHigh: value > max,
          unit: unit,
        ));
      }
    }
  }

  void _trackReading(String blockId, AlertType type, bool isOutOfRange) {
    final trackers = _readingTrackers[blockId]!;
    final existingIndex = trackers.indexWhere((t) => t.type == type);

    if (existingIndex >= 0) {
      if (isOutOfRange) {
        trackers[existingIndex] = trackers[existingIndex].increment();
      } else {
        trackers.removeAt(existingIndex);
      }
    } else if (isOutOfRange) {
      trackers.add(_ReadingTracker(type: type, count: 1, lastUpdate: DateTime.now()));
    }
  }

  int _getConsecutiveCount(String blockId, AlertType type) {
    final trackers = _readingTrackers[blockId];
    if (trackers == null) return 0;
    
    final tracker = trackers.where((t) => t.type == type).firstOrNull;
    return tracker?.count ?? 0;
  }

  PlantAlert _createAlert({
    required String blockId,
    required AlertType type,
    required PlantType plantType,
    required double currentValue,
    required double optimalMin,
    required double optimalMax,
    required int consecutiveReadings,
    required bool isHigh,
    required String unit,
  }) {
    final severity = _getSeverity(consecutiveReadings);
    final direction = isHigh ? 'high' : 'low';
    
    String title;
    String message;
    String recommendation;

    switch (type) {
      case AlertType.phWarning:
        title = 'pH Level ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current pH: ${currentValue.toStringAsFixed(1)} (Optimal: ${optimalMin.toStringAsFixed(1)}-${optimalMax.toStringAsFixed(1)})';
        recommendation = isHigh
            ? 'Consider adding pH down solution to lower acidity'
            : 'Consider adding pH up solution to increase pH level';
        break;
      case AlertType.ecWarning:
        title = 'EC Level ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current EC: ${currentValue.toStringAsFixed(2)} $unit (Optimal: ${optimalMin.toStringAsFixed(1)}-${optimalMax.toStringAsFixed(1)} $unit)';
        recommendation = isHigh
            ? 'Dilute nutrient solution with fresh water'
            : 'Increase nutrient concentration in the solution';
        break;
      case AlertType.waterTempWarning:
        title = 'Water Temperature ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current: ${currentValue.toStringAsFixed(1)}$unit (Optimal: ${optimalMin.toStringAsFixed(0)}-${optimalMax.toStringAsFixed(0)}$unit)';
        recommendation = isHigh
            ? 'Add cooling or shade to reduce water temperature'
            : 'Consider using a water heater to warm the solution';
        break;
      case AlertType.humidityWarning:
        title = 'Humidity ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current: ${currentValue.toStringAsFixed(0)}$unit (Optimal: ${optimalMin.toStringAsFixed(0)}-${optimalMax.toStringAsFixed(0)}$unit)';
        recommendation = isHigh
            ? 'Increase ventilation to reduce humidity'
            : 'Use a humidifier or misting system';
        break;
      case AlertType.temperatureWarning:
        title = 'Temperature ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current: ${currentValue.toStringAsFixed(1)}$unit (Optimal: ${optimalMin.toStringAsFixed(0)}-${optimalMax.toStringAsFixed(0)}$unit)';
        recommendation = isHigh
            ? 'Provide shade or improve ventilation'
            : 'Consider using grow lights for warmth or relocate plants';
        break;
      case AlertType.uvWarning:
        title = 'UV Index ${isHigh ? "Too High" : "Too Low"}';
        message = 'Current UV: ${currentValue.toStringAsFixed(1)} (Optimal: ${optimalMin.toStringAsFixed(0)}-${optimalMax.toStringAsFixed(0)})';
        recommendation = isHigh
            ? 'Provide shade cloth to protect plants'
            : 'Ensure adequate light exposure or use grow lights';
        break;
      case AlertType.vocWarning:
        title = 'VOC Levels Elevated';
        message = 'Current VOC Index: ${currentValue.toStringAsFixed(0)} (Max: ${optimalMax.toStringAsFixed(0)})';
        recommendation = 'Improve ventilation and check for contamination sources';
        break;
      default:
        title = 'Sensor Alert';
        message = 'Value out of optimal range';
        recommendation = 'Check sensor readings and adjust conditions';
    }

    return PlantAlert(
      id: _uuid.v4(),
      blockId: blockId,
      plantType: plantType,
      type: type,
      severity: severity,
      title: title,
      message: message,
      recommendation: recommendation,
      currentValue: currentValue,
      optimalMin: optimalMin,
      optimalMax: optimalMax,
      timestamp: DateTime.now(),
      consecutiveReadings: consecutiveReadings,
    );
  }

  AlertSeverity _getSeverity(int consecutiveReadings) {
    if (consecutiveReadings >= AppConstants.sustainedReadingThreshold * 3) {
      return AlertSeverity.critical;
    } else if (consecutiveReadings >= AppConstants.sustainedReadingThreshold * 2) {
      return AlertSeverity.warning;
    }
    return AlertSeverity.info;
  }

  void _cleanupTrackers() {
    final cutoff = DateTime.now().subtract(const Duration(minutes: 30));
    for (final trackers in _readingTrackers.values) {
      trackers.removeWhere((t) => t.lastUpdate.isBefore(cutoff));
    }
  }

  /// Clear all tracking data
  void clearTrackers() {
    _readingTrackers.clear();
  }

  void dispose() {
    _client.close();
  }
}

class _ReadingTracker {
  final AlertType type;
  final int count;
  final DateTime lastUpdate;

  _ReadingTracker({
    required this.type,
    required this.count,
    required this.lastUpdate,
  });

  _ReadingTracker increment() {
    return _ReadingTracker(
      type: type,
      count: count + 1,
      lastUpdate: DateTime.now(),
    );
  }
}
