import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum PlantType {
  lettuce,
  strawberry,
  blueberry,
}

extension PlantTypeExtension on PlantType {
  String get displayName {
    switch (this) {
      case PlantType.lettuce:
        return 'Lettuce';
      case PlantType.strawberry:
        return 'Strawberry';
      case PlantType.blueberry:
        return 'Blueberry';
    }
  }

  String get emoji {
    switch (this) {
      case PlantType.lettuce:
        return '🥬';
      case PlantType.strawberry:
        return '🍓';
      case PlantType.blueberry:
        return '🫐';
    }
  }

  Color get color {
    switch (this) {
      case PlantType.lettuce:
        return AppColors.lettuce;
      case PlantType.strawberry:
        return AppColors.strawberry;
      case PlantType.blueberry:
        return AppColors.blueberry;
    }
  }

  String get description {
    switch (this) {
      case PlantType.lettuce:
        return 'Fast-growing leafy green, perfect for beginners';
      case PlantType.strawberry:
        return 'Sweet fruit that thrives in various climates';
      case PlantType.blueberry:
        return 'Antioxidant-rich berries for cooler regions';
    }
  }

  String get imagePath {
    switch (this) {
      case PlantType.lettuce:
        return 'assets/images/lettuce.png';
      case PlantType.strawberry:
        return 'assets/images/strawberry.png';
      case PlantType.blueberry:
        return 'assets/images/blueberry.png';
    }
  }

  List<String> get commonDiseases {
    switch (this) {
      case PlantType.lettuce:
        return [
          'Downy Mildew',
          'Lettuce Mosaic Virus',
          'Bottom Rot',
          'Tipburn',
          'Gray Mold',
        ];
      case PlantType.strawberry:
        return [
          'Gray Mold (Botrytis)',
          'Powdery Mildew',
          'Leaf Spot',
          'Anthracnose',
          'Verticillium Wilt',
        ];
      case PlantType.blueberry:
        return [
          'Mummy Berry',
          'Botrytis Blight',
          'Phomopsis Twig Blight',
          'Anthracnose',
          'Bacterial Canker',
        ];
    }
  }

  Map<String, String> get idealConditions {
    switch (this) {
      case PlantType.lettuce:
        return {
          'pH Level': '6.0 - 7.0',
          'EC Level': '0.8 - 1.2 mS/cm',
          'Water Temp': '18 - 22°C',
          'Humidity': '50 - 70%',
          'UV Index': 'Low to Moderate',
        };
      case PlantType.strawberry:
        return {
          'pH Level': '5.5 - 6.5',
          'EC Level': '1.0 - 1.5 mS/cm',
          'Water Temp': '18 - 24°C',
          'Humidity': '60 - 75%',
          'UV Index': 'Moderate',
        };
      case PlantType.blueberry:
        return {
          'pH Level': '4.5 - 5.5',
          'EC Level': '1.2 - 1.8 mS/cm',
          'Water Temp': '15 - 21°C',
          'Humidity': '60 - 80%',
          'UV Index': 'Moderate to High',
        };
    }
  }
}
