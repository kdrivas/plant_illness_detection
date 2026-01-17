import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration Constants
class ApiConstants {
  // Base URL for plant-gardener-agent backend
  // For Android emulator, use 10.0.2.2 to access localhost
  // For iOS simulator, use localhost or 127.0.0.1
  // For real device on same network, use your computer's IP address
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000';
  
  // ============================================================================
  // Dashboard Endpoints (New Row-based Architecture)
  // ============================================================================
  
  // Get dashboard overview with all rows: GET /dashboard/overview
  static String get overviewEndpoint => '$baseUrl/dashboard/overview';
  
  // Get all plant rows: GET /dashboard/rows
  static String get rowsEndpoint => '$baseUrl/dashboard/rows';
  
  // Get single row detail: GET /dashboard/rows/{row_id}
  static String rowDetailEndpoint(String rowId) => '$baseUrl/dashboard/rows/$rowId';
  
  // Get row history for charts: GET /dashboard/rows/{row_id}/history?hours=24
  static String rowHistoryEndpoint(String rowId, {int hours = 24}) => 
      '$baseUrl/dashboard/rows/$rowId/history?hours=$hours';
  
  // Get daily stats for a row: GET /dashboard/rows/{row_id}/stats?days=7
  static String rowStatsEndpoint(String rowId, {int days = 7}) => 
      '$baseUrl/dashboard/rows/$rowId/stats?days=$days';
  
  // Trigger manual pump: POST /dashboard/pump
  static String get pumpEndpoint => '$baseUrl/dashboard/pump';
  
  // Get water tanks: GET /dashboard/tanks
  static String get tanksEndpoint => '$baseUrl/dashboard/tanks';
  
  // Get ambient zones: GET /dashboard/ambient
  static String get ambientEndpoint => '$baseUrl/dashboard/ambient';
  
  // Get system configuration: GET /dashboard/config
  static String get configEndpoint => '$baseUrl/dashboard/config';
  
  // ============================================================================
  // Prediction Endpoints
  // ============================================================================
  
  // POST /predict - Send sensor data, get watering actions
  static String get predictEndpoint => '$baseUrl/predict';
  
  // ============================================================================
  // Health Endpoints
  // ============================================================================
  
  // GET /health
  static String get healthEndpoint => '$baseUrl/health';
  
  // ============================================================================
  // Legacy/Fallback Endpoints (kept for compatibility)
  // ============================================================================
  // Legacy Compatibility (mapped to new endpoints)
  // ============================================================================
  
  // Sensor Endpoints (mapped to rows)
  static String get sensorsEndpoint => overviewEndpoint;
  static String sensorDataEndpoint(String rowId) => rowStatsEndpoint(rowId);
  static String sensorHistoryEndpoint(String rowId, int hours) => 
      rowHistoryEndpoint(rowId, hours: hours);
  static String get availableBlocksEndpoint => rowsEndpoint;
  
  // Alert Endpoints (TODO: implement in backend)
  static String get alertsEndpoint => '$baseUrl/api/alerts';
  static String blockAlertsEndpoint(String blockId) => '$alertsEndpoint/$blockId';
  static String get alertThresholdsEndpoint => '$alertsEndpoint/thresholds';
  
  // Detection Endpoints (TODO: implement in backend)
  static String get detectionEndpoint => '$baseUrl/api/detection';
  static String get analyzeImageEndpoint => '$detectionEndpoint/analyze';
  
  // Chat/LLM Endpoints (TODO: implement in backend)
  static String get chatEndpoint => '$baseUrl/api/chat';
  static String get geminiEndpoint => '$chatEndpoint/gemini';
  static String get openaiEndpoint => '$chatEndpoint/openai';
  
  // Harvest Endpoints (mapped to dashboard)
  static String get harvestEndpoint => '$baseUrl/dashboard';
  static String harvestStatusEndpoint(String rowId) => rowStatsEndpoint(rowId);
  static String get harvestPredictEndpoint => predictEndpoint;
  
  // LLM Direct APIs (when not using proxy server)
  static const String geminiDirectUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  static const String openaiDirectUrl = 
      'https://api.openai.com/v1/chat/completions';
}

/// App Configuration Constants
class AppConstants {
  // Sensor polling interval (in seconds) - default 60 (1 minute)
  static int get sensorPollingIntervalSeconds => 
      int.tryParse(dotenv.env['SENSOR_POLLING_INTERVAL_SECONDS'] ?? '60') ?? 60;
  
  // Number of consecutive readings required for sustained alert
  static int get sustainedReadingThreshold => 
      int.tryParse(dotenv.env['SUSTAINED_READING_THRESHOLD'] ?? '3') ?? 3;
  
  // Default chart timeframe in hours
  static int get defaultChartHours => 
      int.tryParse(dotenv.env['DEFAULT_CHART_HOURS'] ?? '24') ?? 24;
  
  // Available chart timeframes
  static const List<int> chartTimeframeOptions = [1, 6, 24];
  
  // LLM API Keys
  static String get geminiApiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get openaiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
}

/// LLM Provider Selection
enum LLMProvider {
  gemini,
  openai,
}

extension LLMProviderExtension on LLMProvider {
  String get displayName {
    switch (this) {
      case LLMProvider.gemini:
        return 'Gemini AI';
      case LLMProvider.openai:
        return 'OpenAI';
    }
  }
  
  String get modelName {
    switch (this) {
      case LLMProvider.gemini:
        return 'gemini-pro';
      case LLMProvider.openai:
        return 'gpt-4-turbo-preview';
    }
  }
}

/// Alert Severity Levels
enum AlertSeverity {
  info,
  warning,
  critical,
}

extension AlertSeverityExtension on AlertSeverity {
  String get displayName {
    switch (this) {
      case AlertSeverity.info:
        return 'Info';
      case AlertSeverity.warning:
        return 'Warning';
      case AlertSeverity.critical:
        return 'Critical';
    }
  }
  
  int get priority {
    switch (this) {
      case AlertSeverity.info:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.critical:
        return 2;
    }
  }
}

/// Chart Timeframe
enum ChartTimeframe {
  oneHour,
  sixHours,
  twentyFourHours,
}

extension ChartTimeframeExtension on ChartTimeframe {
  int get hours {
    switch (this) {
      case ChartTimeframe.oneHour:
        return 1;
      case ChartTimeframe.sixHours:
        return 6;
      case ChartTimeframe.twentyFourHours:
        return 24;
    }
  }
  
  String get displayName {
    switch (this) {
      case ChartTimeframe.oneHour:
        return '1H';
      case ChartTimeframe.sixHours:
        return '6H';
      case ChartTimeframe.twentyFourHours:
        return '24H';
    }
  }
}
