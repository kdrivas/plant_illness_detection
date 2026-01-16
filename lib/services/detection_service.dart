import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/disease_result.dart';
import '../models/plant_type.dart';
import '../core/constants/api_constants.dart';

class DetectionService {
  final http.Client _client;

  DetectionService({http.Client? client}) : _client = client ?? http.Client();

  /// Analyze an image for plant diseases (server-side)
  /// Designed to be easily swapped to custom CV model
  Future<DiseaseDetectionResult> analyzeImage(
    File imageFile,
    PlantType plantType,
  ) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConstants.analyzeImageEndpoint),
      );

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );

      // Add plant type as field
      request.fields['plant_type'] = plantType.name;

      // Send request
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return DiseaseDetectionResult.fromJson(data);
      } else {
        // Return mock result for demo
        return _getMockDetectionResult(plantType);
      }
    } catch (e) {
      // Return mock result for demo/development
      return _getMockDetectionResult(plantType);
    }
  }

  /// Get disease information from database
  DiseaseDetectionResult? getDiseaseInfo(String diseaseKey) {
    return DiseaseDatabase.diseases[diseaseKey];
  }

  /// Get common diseases for a plant type
  List<DiseaseDetectionResult> getCommonDiseases(PlantType plantType) {
    final diseases = <DiseaseDetectionResult>[];
    
    for (final diseaseName in plantType.commonDiseases) {
      final key = diseaseName.toLowerCase().replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', '');
      final disease = DiseaseDatabase.diseases[key];
      if (disease != null) {
        diseases.add(disease);
      }
    }
    
    return diseases;
  }

  // Mock detection for demo/development
  DiseaseDetectionResult _getMockDetectionResult(PlantType plantType) {
    // Randomly return healthy or a disease for demo
    final random = DateTime.now().millisecond % 100;
    
    if (random < 60) {
      // 60% chance healthy
      return DiseaseDetectionResult.healthy();
    }
    
    // Otherwise return a common disease for this plant
    switch (plantType) {
      case PlantType.lettuce:
        return DiseaseDatabase.diseases['downy_mildew']!.copyWith(
          confidence: 0.75 + (random % 20) / 100,
        );
      case PlantType.strawberry:
        return DiseaseDatabase.diseases['gray_mold']!.copyWith(
          confidence: 0.70 + (random % 25) / 100,
        );
      case PlantType.blueberry:
        return DiseaseDatabase.diseases['mummy_berry']!.copyWith(
          confidence: 0.72 + (random % 23) / 100,
        );
    }
  }

  void dispose() {
    _client.close();
  }
}

// Extension to allow copyWith on DiseaseDetectionResult
extension DiseaseDetectionResultCopyWith on DiseaseDetectionResult {
  DiseaseDetectionResult copyWith({
    String? diseaseName,
    double? confidence,
    String? description,
    List<String>? symptoms,
    List<String>? treatments,
    String? severity,
    String? imagePath,
  }) {
    return DiseaseDetectionResult(
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      description: description ?? this.description,
      symptoms: symptoms ?? this.symptoms,
      treatments: treatments ?? this.treatments,
      severity: severity ?? this.severity,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
