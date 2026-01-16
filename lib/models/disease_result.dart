class DiseaseDetectionResult {
  final String diseaseName;
  final double confidence;
  final String description;
  final List<String> symptoms;
  final List<String> treatments;
  final String severity;
  final String imagePath;

  DiseaseDetectionResult({
    required this.diseaseName,
    required this.confidence,
    required this.description,
    required this.symptoms,
    required this.treatments,
    required this.severity,
    this.imagePath = '',
  });

  bool get isHealthy => diseaseName.toLowerCase() == 'healthy';

  factory DiseaseDetectionResult.healthy() {
    return DiseaseDetectionResult(
      diseaseName: 'Healthy',
      confidence: 0.95,
      description: 'Your plant appears to be healthy with no visible signs of disease.',
      symptoms: [],
      treatments: [
        'Continue current care routine',
        'Monitor regularly for any changes',
        'Maintain proper watering schedule',
      ],
      severity: 'None',
    );
  }

  factory DiseaseDetectionResult.fromJson(Map<String, dynamic> json) {
    return DiseaseDetectionResult(
      diseaseName: json['disease_name'] ?? json['diseaseName'] ?? 'Unknown',
      confidence: (json['confidence'] ?? 0).toDouble(),
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      treatments: List<String>.from(json['treatments'] ?? []),
      severity: json['severity'] ?? 'Unknown',
      imagePath: json['image_path'] ?? json['imagePath'] ?? '',
    );
  }
}

// Predefined disease information for demo/offline mode
class DiseaseDatabase {
  static final Map<String, DiseaseDetectionResult> diseases = {
    'downy_mildew': DiseaseDetectionResult(
      diseaseName: 'Downy Mildew',
      confidence: 0.0,
      description: 'A fungal disease that causes yellow patches on leaf surfaces with fuzzy gray growth underneath.',
      symptoms: [
        'Yellow or pale green patches on upper leaf surface',
        'Fuzzy gray or purple growth on leaf undersides',
        'Leaves may curl or become distorted',
        'Stunted growth in severe cases',
      ],
      treatments: [
        'Remove and destroy infected leaves',
        'Improve air circulation around plants',
        'Avoid overhead watering',
        'Apply copper-based fungicide',
        'Use resistant varieties for future plantings',
      ],
      severity: 'Moderate to High',
    ),
    'gray_mold': DiseaseDetectionResult(
      diseaseName: 'Gray Mold (Botrytis)',
      confidence: 0.0,
      description: 'A fungal disease causing gray fuzzy mold on leaves, stems, and fruit.',
      symptoms: [
        'Gray fuzzy mold on affected areas',
        'Brown rotting of fruit',
        'Water-soaked spots on leaves',
        'Stem cankers',
      ],
      treatments: [
        'Remove all infected plant material',
        'Increase spacing between plants',
        'Reduce humidity if possible',
        'Apply appropriate fungicide',
        'Avoid wetting foliage when watering',
      ],
      severity: 'High',
    ),
    'powdery_mildew': DiseaseDetectionResult(
      diseaseName: 'Powdery Mildew',
      confidence: 0.0,
      description: 'A fungal disease creating white powdery coating on leaves and stems.',
      symptoms: [
        'White powdery spots on leaves',
        'Leaves may yellow and drop',
        'Distorted new growth',
        'Reduced fruit production',
      ],
      treatments: [
        'Remove heavily infected leaves',
        'Apply neem oil or sulfur-based fungicide',
        'Improve air circulation',
        'Avoid overhead irrigation',
        'Plant resistant varieties',
      ],
      severity: 'Moderate',
    ),
    'leaf_spot': DiseaseDetectionResult(
      diseaseName: 'Leaf Spot',
      confidence: 0.0,
      description: 'Various fungal or bacterial infections causing spots on foliage.',
      symptoms: [
        'Dark spots with defined edges on leaves',
        'Yellow halos around spots',
        'Spots may merge causing leaf death',
        'Premature leaf drop',
      ],
      treatments: [
        'Remove infected leaves immediately',
        'Avoid wetting foliage',
        'Apply copper fungicide',
        'Maintain good sanitation',
        'Rotate crops annually',
      ],
      severity: 'Low to Moderate',
    ),
    'mummy_berry': DiseaseDetectionResult(
      diseaseName: 'Mummy Berry',
      confidence: 0.0,
      description: 'A fungal disease affecting blueberries, causing fruit to shrivel and drop.',
      symptoms: [
        'Wilting of new shoots in spring',
        'Brown discoloration of flowers',
        'Fruit becomes pink then shrivels',
        'Mummified berries on ground',
      ],
      treatments: [
        'Remove and destroy fallen mummified fruit',
        'Apply mulch to bury mummies',
        'Use fungicide during bloom',
        'Plant resistant varieties',
        'Improve drainage',
      ],
      severity: 'High',
    ),
  };
}
