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

  /// Get dashboard overview data
  Future<Map<String, dynamic>> getDashboardOverview() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.overviewEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return {'rows': []};
    } catch (e) {
      print('Error fetching dashboard overview: $e');
      return {'rows': []};
    }
  }

  /// Get current sensor data for a row from /dashboard/overview endpoint
  Future<BlockSensorData?> getSensorData(String rowId) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.overviewEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> overview = json.decode(response.body);
        final List<dynamic> rows = overview['rows'] ?? [];
        // Find the row matching our rowId
        final rowData = rows.firstWhere(
          (r) => r['rowId'] == rowId || r['row_id'] == rowId,
          orElse: () => rows.isNotEmpty ? rows.first : null,
        );
        if (rowData != null) {
          return BlockSensorData.fromJson(_mapRowToSensorData(rowData));
        }
      }
      return _getMockSensorData(rowId);
    } catch (e) {
      print('Error fetching sensor data: $e');
      // Return mock data for demo purposes
      return _getMockSensorData(rowId);
    }
  }
  
  /// Map RowOverview response to BlockSensorData format
  Map<String, dynamic> _mapRowToSensorData(Map<String, dynamic> row) {
    return {
      'blockId': row['rowId'] ?? row['row_id'],
      'rowId': row['rowId'] ?? row['row_id'],
      'phLevel': row['phLevel'] ?? row['ph_level'] ?? 0.0,
      'ecLevel': row['ecLevel'] ?? row['ec_level'] ?? 0.0,
      'waterTemp': row['waterTemp'] ?? row['water_temp'] ?? 0.0,
      'vocIndex': row['vocIndex'] ?? row['voc_index'] ?? 0,
      'weatherTemp': row['weatherTemp'] ?? row['weather_temp'] ?? 0.0,
      'humidity': row['humidity'] ?? 0.0,
      'uvIndex': row['uvIndex'] ?? row['uv_index'] ?? 0.0,
      'moisture': row['soilMoisture'] ?? row['soil_moisture'] ?? 0.0,
      'waterSupplied': 0.0,
      'timestamp': row['moistureTimestamp'] ?? row['moisture_timestamp'] ?? DateTime.now().toIso8601String(),
    };
  }

  /// Get sensor history for charts from /dashboard/rows/{row_id}/history
  Future<List<BlockSensorData>> getSensorHistory(
    String rowId, {
    int hours = 24,
    String? unusedRowId,
  }) async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.rowHistoryEndpoint(rowId, hours: hours)),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return _mapHistoryResponse(rowId, data);
      }
      return _getMockSensorHistory(rowId, hours);
    } catch (e) {
      print('Error fetching sensor history: $e');
      // Return mock history for demo
      return _getMockSensorHistory(rowId, hours);
    }
  }
  
  /// Convert RowHistoryResponse to list of BlockSensorData
  List<BlockSensorData> _mapHistoryResponse(String rowId, Map<String, dynamic> history) {
    final List<BlockSensorData> result = [];
    final moisture = history['moisture'] as List<dynamic>? ?? [];
    final uvIndex = history['uv_index'] as List<dynamic>? ?? [];
    final weatherTemp = history['weather_temp'] as List<dynamic>? ?? [];
    final humidity = history['humidity'] as List<dynamic>? ?? [];
    final phLevel = history['ph_level'] as List<dynamic>? ?? [];
    final ecLevel = history['ec_level'] as List<dynamic>? ?? [];
    final waterTemp = history['water_temp'] as List<dynamic>? ?? [];
    
    // Use moisture timestamps as base (most reliable)
    for (int i = 0; i < moisture.length; i++) {
      final point = moisture[i];
      result.add(BlockSensorData(
        blockId: rowId,
        phLevel: i < phLevel.length ? (phLevel[i]['value'] ?? 0.0).toDouble() : 0.0,
        ecLevel: i < ecLevel.length ? (ecLevel[i]['value'] ?? 0.0).toDouble() : 0.0,
        waterTemp: i < waterTemp.length ? (waterTemp[i]['value'] ?? 0.0).toDouble() : 0.0,
        vocIndex: 0,
        weatherTemp: i < weatherTemp.length ? (weatherTemp[i]['value'] ?? 0.0).toDouble() : 0.0,
        humidity: i < humidity.length ? (humidity[i]['value'] ?? 0.0).toDouble() : 0.0,
        uvIndex: i < uvIndex.length ? (uvIndex[i]['value'] ?? 0.0).toDouble() : 0.0,
        timestamp: point['timestamp'] ?? DateTime.now().toIso8601String(),
      ));
    }
    return result;
  }

  /// Get list of available plant rows from /dashboard/overview
  Future<List<String>> getAvailableBlocks() async {
    try {
      final response = await _client.get(
        Uri.parse(ApiConstants.overviewEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> overview = json.decode(response.body);
        final List<dynamic> rows = overview['rows'] ?? [];
        return rows.map((r) => (r['rowId'] ?? r['row_id'] ?? 'Unknown') as String).toList();
      }
      return _getMockBlocks();
    } catch (e) {
      print('Error fetching rows: $e');
      return _getMockBlocks();
    }
  }

  List<String> _getMockBlocks() {
    return ['row_1', 'row_2', 'row_3'];
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
