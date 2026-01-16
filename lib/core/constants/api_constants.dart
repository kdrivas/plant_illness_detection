import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API Configuration Constants
class ApiConstants {
  // Base URLs (placeholder - configure in .env)
  static String get baseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'https://api.yourserver.com';
  
  // Sensor Endpoints
  static String get sensorsEndpoint => '$baseUrl/api/sensors';
  static String sensorDataEndpoint(String blockId) => '$sensorsEndpoint/$blockId';
  static String sensorHistoryEndpoint(String blockId, int hours) => 
      '$sensorsEndpoint/$blockId/history?hours=$hours';
  static String get availableBlocksEndpoint => '$sensorsEndpoint/blocks';
  
  // Alert Endpoints
  static String get alertsEndpoint => '$baseUrl/api/alerts';
  static String blockAlertsEndpoint(String blockId) => '$alertsEndpoint/$blockId';
  static String get alertThresholdsEndpoint => '$alertsEndpoint/thresholds';
  
  // Detection Endpoints
  static String get detectionEndpoint => '$baseUrl/api/detection';
  static String get analyzeImageEndpoint => '$detectionEndpoint/analyze';
  
  // Chat/LLM Endpoints
  static String get chatEndpoint => '$baseUrl/api/chat';
  static String get geminiEndpoint => '$chatEndpoint/gemini';
  static String get openaiEndpoint => '$chatEndpoint/openai';
  
  // Harvest Endpoints
  static String get harvestEndpoint => '$baseUrl/api/harvest';
  static String harvestStatusEndpoint(String blockId) => '$harvestEndpoint/$blockId';
  static String get harvestPredictEndpoint => '$harvestEndpoint/predict';
  
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
