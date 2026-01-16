import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';
import '../models/sensor_data.dart';
import '../models/plant_alert.dart';
import '../models/plant_type.dart';
import '../core/constants/api_constants.dart';

/// Abstract LLM service interface
abstract class LLMService {
  Future<String> sendMessage(
    String message, {
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  });
}

/// Chat service that manages conversations with LLM
class ChatService {
  final http.Client _client;
  LLMProvider _currentProvider;
  late LLMService _llmService;

  ChatService({
    http.Client? client,
    LLMProvider provider = LLMProvider.gemini,
  }) : _client = client ?? http.Client(),
       _currentProvider = provider {
    _updateService();
  }

  LLMProvider get currentProvider => _currentProvider;

  void setProvider(LLMProvider provider) {
    _currentProvider = provider;
    _updateService();
  }

  void _updateService() {
    switch (_currentProvider) {
      case LLMProvider.gemini:
        _llmService = GeminiService(client: _client);
        break;
      case LLMProvider.openai:
        _llmService = OpenAIService(client: _client);
        break;
    }
  }

  /// Send a message to the LLM with optional context
  Future<ChatMessage> sendMessage(
    String message, {
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  }) async {
    try {
      final response = await _llmService.sendMessage(
        message,
        sensorData: sensorData,
        activeAlerts: activeAlerts,
        selectedPlant: selectedPlant,
      );
      
      return ChatMessage.assistant(response);
    } catch (e) {
      return ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${e.toString()}',
        isUser: false,
        timestamp: DateTime.now(),
        type: MessageType.error,
      );
    }
  }

  void dispose() {
    _client.close();
  }
}

/// Gemini AI Service Implementation
class GeminiService implements LLMService {
  final http.Client _client;

  GeminiService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String> sendMessage(
    String message, {
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  }) async {
    final apiKey = AppConstants.geminiApiKey;
    
    if (apiKey.isEmpty || apiKey == 'your_gemini_api_key_here') {
      return _getMockResponse(message, sensorData, activeAlerts, selectedPlant);
    }

    final contextPrompt = _buildContextPrompt(sensorData, activeAlerts, selectedPlant);
    final fullPrompt = contextPrompt.isNotEmpty 
        ? '$contextPrompt\n\nUser question: $message'
        : message;

    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.geminiDirectUrl}?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1024,
          },
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        return text ?? 'No response generated';
      } else {
        return _getMockResponse(message, sensorData, activeAlerts, selectedPlant);
      }
    } catch (e) {
      return _getMockResponse(message, sensorData, activeAlerts, selectedPlant);
    }
  }

  String _buildContextPrompt(
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('You are a helpful plant care assistant specialized in hydroponic and traditional gardening, '
        'particularly for lettuce, strawberries, and blueberries. Provide concise, actionable advice.');

    if (selectedPlant != null) {
      buffer.writeln('\nCurrently monitoring: ${selectedPlant.displayName}');
      buffer.writeln('Ideal conditions for ${selectedPlant.displayName}:');
      selectedPlant.idealConditions.forEach((key, value) {
        buffer.writeln('  - $key: $value');
      });
    }

    if (sensorData != null) {
      buffer.writeln('\nCurrent sensor readings:');
      buffer.writeln('  - pH Level: ${sensorData.phLevel.toStringAsFixed(1)}');
      buffer.writeln('  - EC Level: ${sensorData.ecLevel.toStringAsFixed(2)} mS/cm');
      buffer.writeln('  - Water Temperature: ${sensorData.waterTemp.toStringAsFixed(1)}°C');
      buffer.writeln('  - Air Temperature: ${sensorData.weatherTemp.toStringAsFixed(1)}°C');
      buffer.writeln('  - Humidity: ${sensorData.humidity.toStringAsFixed(0)}%');
      buffer.writeln('  - UV Index: ${sensorData.uvIndex.toStringAsFixed(1)}');
      buffer.writeln('  - VOC Index: ${sensorData.vocIndex}');
    }

    if (activeAlerts != null && activeAlerts.isNotEmpty) {
      buffer.writeln('\nActive alerts:');
      for (final alert in activeAlerts) {
        buffer.writeln('  - ${alert.title}: ${alert.message}');
      }
    }

    return buffer.toString();
  }

  String _getMockResponse(
    String message,
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  ) {
    final lowerMessage = message.toLowerCase();
    
    if (sensorData != null) {
      if (lowerMessage.contains('status') || lowerMessage.contains('how')) {
        return _generateStatusResponse(sensorData, selectedPlant);
      }
    }

    if (activeAlerts != null && activeAlerts.isNotEmpty) {
      if (lowerMessage.contains('alert') || lowerMessage.contains('warning') || lowerMessage.contains('problem')) {
        return _generateAlertResponse(activeAlerts);
      }
    }

    if (lowerMessage.contains('harvest')) {
      return '🌱 **Harvest Tips**\n\n'
          'Based on your growing conditions, here are some recommendations:\n\n'
          '1. **Check maturity signs** - Look for the appropriate size and color\n'
          '2. **Harvest timing** - Early morning is usually best\n'
          '3. **Gentle handling** - Avoid bruising your produce\n\n'
          'Would you like specific advice for a particular plant?';
    }

    if (lowerMessage.contains('disease') || lowerMessage.contains('illness')) {
      return '🔬 **Disease Prevention Tips**\n\n'
          '1. **Monitor humidity** - High humidity can promote fungal diseases\n'
          '2. **Air circulation** - Ensure proper ventilation\n'
          '3. **Clean tools** - Sanitize between uses\n'
          '4. **Regular inspection** - Check leaves daily for early signs\n\n'
          'Use the Detection feature to scan your plants for potential issues!';
    }

    return '🌿 **Plant Care Assistant**\n\n'
        'I can help you with:\n\n'
        '• **Sensor Analysis** - Tap "Include Sensor Data" to get insights on your current readings\n'
        '• **Disease Prevention** - Tips for keeping your plants healthy\n'
        '• **Harvest Guidance** - Know when your crops are ready\n'
        '• **Growing Tips** - Specific advice for lettuce, strawberries, and blueberries\n\n'
        'What would you like to know?';
  }

  String _generateStatusResponse(BlockSensorData data, PlantType? plant) {
    final plantName = plant?.displayName ?? 'your plants';
    final issues = <String>[];
    final goods = <String>[];

    // Simple analysis
    if (data.phLevel < 5.5 || data.phLevel > 7.5) {
      issues.add('pH level (${data.phLevel.toStringAsFixed(1)}) needs adjustment');
    } else {
      goods.add('pH level is good');
    }

    if (data.humidity < 40) {
      issues.add('Humidity is too low (${data.humidity.toStringAsFixed(0)}%)');
    } else if (data.humidity > 80) {
      issues.add('Humidity is too high (${data.humidity.toStringAsFixed(0)}%)');
    } else {
      goods.add('Humidity is optimal');
    }

    if (data.weatherTemp < 15) {
      issues.add('Temperature is too cold (${data.weatherTemp.toStringAsFixed(1)}°C)');
    } else if (data.weatherTemp > 30) {
      issues.add('Temperature is too hot (${data.weatherTemp.toStringAsFixed(1)}°C)');
    } else {
      goods.add('Temperature is comfortable');
    }

    final buffer = StringBuffer('📊 **Current Status for $plantName**\n\n');
    
    if (goods.isNotEmpty) {
      buffer.writeln('✅ **Looking Good:**');
      for (final good in goods) {
        buffer.writeln('  • $good');
      }
      buffer.writeln();
    }

    if (issues.isNotEmpty) {
      buffer.writeln('⚠️ **Needs Attention:**');
      for (final issue in issues) {
        buffer.writeln('  • $issue');
      }
    } else {
      buffer.writeln('🎉 All conditions are optimal!');
    }

    return buffer.toString();
  }

  String _generateAlertResponse(List<PlantAlert> alerts) {
    final buffer = StringBuffer('🚨 **Active Alerts Summary**\n\n');
    
    for (final alert in alerts) {
      buffer.writeln('**${alert.title}**');
      buffer.writeln(alert.message);
      if (alert.recommendation != null) {
        buffer.writeln('💡 *${alert.recommendation}*');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }
}

/// OpenAI Service Implementation
class OpenAIService implements LLMService {
  final http.Client _client;

  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  @override
  Future<String> sendMessage(
    String message, {
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  }) async {
    final apiKey = AppConstants.openaiApiKey;
    
    if (apiKey.isEmpty || apiKey == 'your_openai_api_key_here') {
      // Fall back to mock response
      return GeminiService()._getMockResponse(message, sensorData, activeAlerts, selectedPlant);
    }

    final systemPrompt = _buildSystemPrompt(sensorData, activeAlerts, selectedPlant);

    try {
      final response = await _client.post(
        Uri.parse(ApiConstants.openaiDirectUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: json.encode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': message},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['choices']?[0]?['message']?['content'] ?? 'No response generated';
      } else {
        return GeminiService()._getMockResponse(message, sensorData, activeAlerts, selectedPlant);
      }
    } catch (e) {
      return GeminiService()._getMockResponse(message, sensorData, activeAlerts, selectedPlant);
    }
  }

  String _buildSystemPrompt(
    BlockSensorData? sensorData,
    List<PlantAlert>? activeAlerts,
    PlantType? selectedPlant,
  ) {
    // Reuse GeminiService's context building
    return GeminiService()._buildContextPrompt(sensorData, activeAlerts, selectedPlant);
  }
}
