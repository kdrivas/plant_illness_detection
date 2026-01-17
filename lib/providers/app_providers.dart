import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sensor_service.dart';
import '../services/alert_service.dart';
import '../services/harvest_service.dart';
import '../services/chat_service.dart';
import '../services/detection_service.dart';
import '../services/location_service.dart';
import '../models/sensor_data.dart';
import '../models/plant_alert.dart';
import '../models/plant_type.dart';
import '../models/harvest_tracker.dart';
import '../models/chat_message.dart';
import '../core/constants/api_constants.dart';

// ============================================================================
// Service Providers
// ============================================================================

final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorService();
  ref.onDispose(() => service.dispose());
  return service;
});

final alertServiceProvider = Provider<AlertService>((ref) {
  final service = AlertService();
  ref.onDispose(() => service.dispose());
  return service;
});

final harvestServiceProvider = Provider<HarvestService>((ref) {
  final service = HarvestService();
  ref.onDispose(() => service.dispose());
  return service;
});

final chatServiceProvider = Provider<ChatService>((ref) {
  final service = ChatService();
  ref.onDispose(() => service.dispose());
  return service;
});

final detectionServiceProvider = Provider<DetectionService>((ref) {
  final service = DetectionService();
  ref.onDispose(() => service.dispose());
  return service;
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

// ============================================================================
// State Providers
// ============================================================================

/// Currently selected plant type
final selectedPlantProvider = StateProvider<PlantType>((ref) {
  return PlantType.lettuce;
});

/// Currently selected sensor block (matches backend block_A, block_B, etc.)
final selectedBlockProvider = StateProvider<String>((ref) {
  return 'block_A';
});

/// Currently selected row within a block (matches backend row_1, row_2, etc.)
final selectedRowProvider = StateProvider<String>((ref) {
  return 'row_1';
});

/// Cached overview data from API
final dashboardOverviewProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.watch(sensorServiceProvider);
  return service.getDashboardOverview();
});

/// Available rows for the selected plant type (from API)
final availableRowsProvider = Provider<List<String>>((ref) {
  final overviewAsync = ref.watch(dashboardOverviewProvider);
  final selectedPlant = ref.watch(selectedPlantProvider);
  
  return overviewAsync.when(
    data: (overview) {
      final rows = overview['rows'] as List<dynamic>? ?? [];
      // Filter rows by selected plant type
      return rows
          .where((r) => (r['plantType'] ?? r['plant_type']) == selectedPlant.name)
          .map((r) => (r['rowId'] ?? r['row_id'] ?? 'unknown') as String)
          .toList();
    },
    loading: () => ['row_1'], // Default while loading
    error: (_, __) => ['row_1'], // Default on error
  );
});

/// Chart timeframe selection (1h, 6h, 24h)
final chartTimeframeProvider = StateProvider<ChartTimeframe>((ref) {
  return ChartTimeframe.twentyFourHours; // Default 24h
});

/// LLM provider selection
final llmProviderProvider = StateProvider<LLMProvider>((ref) {
  return LLMProvider.gemini;
});

/// Whether to include sensor data in chat
final includeSensorDataInChatProvider = StateProvider<bool>((ref) {
  return false;
});

// ============================================================================
// Sensor Data Providers
// ============================================================================

/// Stream of real-time sensor data with polling
final sensorDataStreamProvider = StreamProvider.family<BlockSensorData, String>((ref, blockId) {
  final service = ref.watch(sensorServiceProvider);
  service.startPolling(blockId);
  
  ref.onDispose(() => service.stopPolling());
  
  return service.sensorDataStream;
});

/// Current sensor data (auto-updates)
final currentSensorDataProvider = FutureProvider<BlockSensorData?>((ref) async {
  final blockId = ref.watch(selectedBlockProvider);
  final service = ref.watch(sensorServiceProvider);
  return service.getSensorData(blockId);
});

/// Sensor history for charts
final sensorHistoryProvider = FutureProvider.family<List<BlockSensorData>, int>((ref, hours) async {
  final rowId = ref.watch(selectedBlockProvider);
  final service = ref.watch(sensorServiceProvider);
  return service.getSensorHistory(rowId, hours: hours);
});

/// Available sensor blocks
final availableBlocksProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.watch(sensorServiceProvider);
  return service.getAvailableBlocks();
});

// ============================================================================
// Alert Providers
// ============================================================================

/// Active alerts based on current sensor data
final activeAlertsProvider = Provider<List<PlantAlert>>((ref) {
  final sensorDataAsync = ref.watch(currentSensorDataProvider);
  final plantType = ref.watch(selectedPlantProvider);
  final alertService = ref.watch(alertServiceProvider);
  final harvestService = ref.watch(harvestServiceProvider);
  
  final alerts = <PlantAlert>[];
  
  // Add sensor-based alerts
  sensorDataAsync.whenData((data) {
    if (data != null) {
      alerts.addAll(alertService.evaluateSensorData(data, plantType));
    }
  });
  
  // Add harvest-ready alerts
  alerts.addAll(harvestService.getHarvestReadyAlerts());
  
  // Sort by severity (critical first)
  alerts.sort((a, b) => b.severity.priority.compareTo(a.severity.priority));
  
  return alerts;
});

// ============================================================================
// Harvest Providers
// ============================================================================

/// Harvest tracker for current block
final currentHarvestTrackerProvider = Provider<HarvestTracker?>((ref) {
  final blockId = ref.watch(selectedBlockProvider);
  final service = ref.watch(harvestServiceProvider);
  return service.getTracker(blockId);
});

/// Harvest summary
final harvestSummaryProvider = Provider<HarvestSummary>((ref) {
  final service = ref.watch(harvestServiceProvider);
  return service.getSummary();
});

/// Harvest actions notifier
final harvestActionsProvider = Provider<HarvestActions>((ref) {
  final service = ref.watch(harvestServiceProvider);
  return HarvestActions(service, ref);
});

class HarvestActions {
  final HarvestService _service;
  final Ref _ref;
  
  HarvestActions(this._service, this._ref);
  
  HarvestTracker startTracking(String blockId, PlantType plantType, {String? notes}) {
    return _service.startTracking(
      blockId: blockId,
      plantType: plantType,
      notes: notes,
    );
  }
  
  HarvestTracker? markComplete(String blockId) {
    return _service.markHarvestComplete(blockId);
  }
  
  HarvestTracker resetAndStartNew(String blockId, PlantType plantType, {String? notes}) {
    return _service.resetAndStartNew(
      blockId: blockId,
      plantType: plantType,
      notes: notes,
    );
  }
}

// ============================================================================
// Chat Providers
// ============================================================================

/// Chat messages state
class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final ChatService _chatService;
  final Ref _ref;
  
  ChatNotifier(this._chatService, this._ref) : super([]);
  
  Future<void> sendMessage(String content) async {
    // Add user message
    final userMessage = ChatMessage.user(content);
    state = [...state, userMessage];
    
    // Add loading indicator
    state = [...state, ChatMessage.loading()];
    
    // Get context if enabled
    BlockSensorData? sensorData;
    List<PlantAlert>? alerts;
    PlantType? plantType;
    
    if (_ref.read(includeSensorDataInChatProvider)) {
      final sensorAsync = _ref.read(currentSensorDataProvider);
      sensorData = sensorAsync.value;
      alerts = _ref.read(activeAlertsProvider);
      plantType = _ref.read(selectedPlantProvider);
    }
    
    // Send to LLM
    final response = await _chatService.sendMessage(
      content,
      sensorData: sensorData,
      activeAlerts: alerts,
      selectedPlant: plantType,
    );
    
    // Remove loading and add response
    state = [
      ...state.where((m) => m.type != MessageType.loading),
      response,
    ];
  }
  
  void clearChat() {
    state = [];
  }
}

final chatMessagesProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  return ChatNotifier(chatService, ref);
});

// ============================================================================
// Location Providers
// ============================================================================

/// Location details
final locationDetailsProvider = FutureProvider<LocationDetails?>((ref) async {
  final service = ref.watch(locationServiceProvider);
  return service.getLocationDetails();
});

/// Is Northern Hemisphere
final isNorthernHemisphereProvider = FutureProvider<bool>((ref) async {
  final locationAsync = ref.watch(locationDetailsProvider);
  return locationAsync.when(
    data: (location) => location?.isNorthernHemisphere ?? true,
    loading: () => true,
    error: (_, __) => true,
  );
});
