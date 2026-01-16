import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../core/constants/api_constants.dart';

class SensorService {
  final http.Client _client;
  Timer? _pollingTimer;
  final _sensorDataController = StreamController<BlockSensorData>.broadcast();
  
  String? _currentBlockId;
  
  SensorService({http.Client? client}) : _client = client ?? http.Client();

  /// Stream of sensor data updates
  Stream<BlockSensorData> get sensorDataStream => _sensorDataController.stream;

  /// Start polling for sensor data at configured interval
  void startPolling(String blockId) {
    _currentBlockId = blockId;
    _stopPolling();
    
    // Fetch immediately
    _fetchAndEmit(blockId);
    
    // Then poll at interval
    _pollingTimer = Timer.periodic(
      Duration(seconds: AppConstants.sensorPollingIntervalSeconds),
      (_) => _fetchAndEmit(blockId),
    );
  }

  /// Stop polling
  void stopPolling() {
    _stopPolling();
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchAndEmit(String blockId) async {
    final data = await getSensorData(blockId);
    if (data != null) {
      _sensorDataController.add(data);
    }
  }

  /// Get current sensor data for a block
  Future<BlockSensorData?> getSensorData(String blockId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.sensorDataEndpoint(blockId)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return BlockSensorData.fromJson(data);
      }
      return _getMockSensorData(blockId);
    } catch (e) {
      // Return mock data for demo purposes
      return _getMockSensorData(blockId);
    }
  }

  /// Get sensor history for charts (1h, 6h, or 24h)
  Future<List<BlockSensorData>> getSensorHistory(
    String blockId, {
    int hours = 24,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.sensorHistoryEndpoint(blockId, hours)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => BlockSensorData.fromJson(item)).toList();
      }
      return _getMockSensorHistory(blockId, hours);
    } catch (e) {
      // Return mock history for demo
      return _getMockSensorHistory(blockId, hours);
    }
  }

  /// Get list of available sensor blocks
  Future<List<String>> getAvailableBlocks() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.availableBlocksEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      return _getMockBlocks();
    } catch (e) {
      return _getMockBlocks();
    }
  }

  List<String> _getMockBlocks() {
    return ['Block-A', 'Block-B', 'Block-C'];
  }

  // Mock data for demo/development
  BlockSensorData _getMockSensorData(String blockId) {
    final now = DateTime.now();
    final hourFactor = now.hour / 24.0;
    final minuteFactor = now.minute / 60.0;
    
    return BlockSensorData(
      blockId: blockId,
      phLevel: 6.2 + (minuteFactor * 0.5) - 0.25,
      ecLevel: 1.1 + (minuteFactor * 0.3) - 0.15,
      waterTemp: 20.0 + (hourFactor * 4) - 2,
      vocIndex: 50 + (now.minute % 30),
      weatherTemp: 22.0 + (hourFactor * 8) - 4,
      humidity: 65.0 + (minuteFactor * 15) - 7.5,
      uvIndex: now.hour >= 6 && now.hour <= 18
          ? 2.0 + (6 - (now.hour - 12).abs()) * 1.0
          : 0.0,
      timestamp: now.toIso8601String(),
    );
  }

  List<BlockSensorData> _getMockSensorHistory(String blockId, int hours) {
    final List<BlockSensorData> history = [];
    final now = DateTime.now();
    final intervalMinutes = hours <= 1 ? 5 : (hours <= 6 ? 15 : 30);
    final dataPoints = (hours * 60) ~/ intervalMinutes;

    for (int i = dataPoints; i >= 0; i--) {
      final timestamp = now.subtract(Duration(minutes: i * intervalMinutes));
      final hourFactor = timestamp.hour / 24.0;
      final noise = (i % 7) / 10.0;
      
      history.add(BlockSensorData(
        blockId: blockId,
        phLevel: 6.0 + (hourFactor * 0.8) + noise - 0.3,
        ecLevel: 1.0 + (hourFactor * 0.4) + noise * 0.5 - 0.2,
        waterTemp: 19.0 + (hourFactor * 5) + noise * 2,
        vocIndex: 40 + (timestamp.hour * 2) + (i % 20),
        weatherTemp: 20.0 + (8 - (timestamp.hour - 14).abs()) * 0.8,
        humidity: 60.0 + (hourFactor * 20) - 10 + noise * 5,
        uvIndex: timestamp.hour >= 6 && timestamp.hour <= 18
            ? 1.0 + (6 - (timestamp.hour - 12).abs()) * 1.2
            : 0.0,
        timestamp: timestamp.toIso8601String(),
      ));
    }

    return history;
  }

  void dispose() {
    _stopPolling();
    _sensorDataController.close();
    _client.close();
  }
}
