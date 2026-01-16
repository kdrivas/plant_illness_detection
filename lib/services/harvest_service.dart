import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/harvest_tracker.dart';
import '../models/plant_type.dart';
import '../models/sensor_data.dart';
import '../models/plant_alert.dart';
import '../core/constants/api_constants.dart';

class HarvestService {
  final http.Client _client;
  final Map<String, HarvestTracker> _trackers = {};

  HarvestService({http.Client? client}) : _client = client ?? http.Client();

  /// Get all active harvest trackers
  List<HarvestTracker> get activeTrackers => 
      _trackers.values.where((t) => !t.isComplete).toList();

  /// Get tracker for a specific block
  HarvestTracker? getTracker(String blockId) => _trackers[blockId];

  /// Start tracking harvest for a block
  HarvestTracker startTracking({
    required String blockId,
    required PlantType plantType,
    String? notes,
  }) {
    final tracker = HarvestTracker.create(
      blockId: blockId,
      plantType: plantType,
      notes: notes,
    );
    _trackers[blockId] = tracker;
    return tracker;
  }

  /// Update tracker based on sensor data conditions
  /// Returns true if conditions were optimal (day counted)
  bool evaluateConditions(String blockId, BlockSensorData data, PlantType plantType) {
    final tracker = _trackers[blockId];
    if (tracker == null || tracker.isComplete) return false;

    final threshold = AlertThreshold.forPlant(plantType);
    
    // Check if all conditions are within optimal range
    final isOptimal = _isWithinRange(data.phLevel, threshold.phMin, threshold.phMax) &&
        _isWithinRange(data.ecLevel, threshold.ecMin, threshold.ecMax) &&
        _isWithinRange(data.waterTemp, threshold.waterTempMin, threshold.waterTempMax) &&
        _isWithinRange(data.humidity, threshold.humidityMin, threshold.humidityMax) &&
        _isWithinRange(data.weatherTemp, threshold.weatherTempMin, threshold.weatherTempMax);

    if (isOptimal) {
      // Check if a day has passed since last increment
      // In production, this would be more sophisticated
      _trackers[blockId] = tracker.incrementOptimalDays();
      return true;
    }

    return false;
  }

  bool _isWithinRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  /// Mark harvest as complete (manual confirmation)
  HarvestTracker? markHarvestComplete(String blockId) {
    final tracker = _trackers[blockId];
    if (tracker == null) return null;

    final completedTracker = tracker.markComplete();
    _trackers[blockId] = completedTracker;
    
    return completedTracker;
  }

  /// Reset and start new tracking cycle for a block
  HarvestTracker resetAndStartNew({
    required String blockId,
    required PlantType plantType,
    String? notes,
  }) {
    return startTracking(
      blockId: blockId,
      plantType: plantType,
      notes: notes,
    );
  }

  /// Check if any tracker is ready for harvest
  List<PlantAlert> getHarvestReadyAlerts() {
    final alerts = <PlantAlert>[];
    
    for (final tracker in _trackers.values) {
      if (!tracker.isComplete && tracker.isReadyForHarvest) {
        alerts.add(PlantAlert(
          id: 'harvest_${tracker.id}',
          blockId: tracker.blockId,
          plantType: tracker.plantType,
          type: AlertType.harvestReady,
          severity: AlertSeverity.info,
          title: '🎉 Ready to Harvest!',
          message: '${tracker.plantType.displayName} in ${tracker.blockId} has reached ${tracker.optimalDaysCount} optimal growing days.',
          recommendation: 'Your plants are ready for harvest. Tap to confirm harvest completion.',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    return alerts;
  }

  /// Get harvest summary
  HarvestSummary getSummary() {
    return HarvestSummary.fromTrackers(_trackers.values.toList());
  }

  /// Sync with server (optional)
  Future<void> syncWithServer() async {
    try {
      for (final tracker in _trackers.values) {
        await _client.post(
          Uri.parse(ApiConstants.harvestStatusEndpoint(tracker.blockId)),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(tracker.toJson()),
        );
      }
    } catch (e) {
      // Silently fail - local tracking continues
    }
  }

  /// Load trackers from server
  Future<void> loadFromServer(List<String> blockIds) async {
    for (final blockId in blockIds) {
      try {
        final response = await _client.get(
          Uri.parse(ApiConstants.harvestStatusEndpoint(blockId)),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          _trackers[blockId] = HarvestTracker.fromJson(data);
        }
      } catch (e) {
        // Silently fail - will use local data
      }
    }
  }

  void dispose() {
    _client.close();
  }
}
