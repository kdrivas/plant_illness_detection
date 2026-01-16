import 'plant_type.dart';

class PlantingInfo {
  final PlantType plantType;
  final String region;
  final List<PlantingSeason> seasons;
  final List<String> tips;

  PlantingInfo({
    required this.plantType,
    required this.region,
    required this.seasons,
    required this.tips,
  });
}

class PlantingSeason {
  final String name;
  final int startMonth;
  final int endMonth;
  final SeasonType type;
  final String description;

  PlantingSeason({
    required this.name,
    required this.startMonth,
    required this.endMonth,
    required this.type,
    required this.description,
  });

  bool isCurrentSeason(int currentMonth) {
    if (startMonth <= endMonth) {
      return currentMonth >= startMonth && currentMonth <= endMonth;
    } else {
      // Handles seasons that span year boundary (e.g., Nov-Feb)
      return currentMonth >= startMonth || currentMonth <= endMonth;
    }
  }
}

enum SeasonType {
  ideal,
  possible,
  notRecommended,
}

extension SeasonTypeExtension on SeasonType {
  String get displayName {
    switch (this) {
      case SeasonType.ideal:
        return 'Ideal';
      case SeasonType.possible:
        return 'Possible';
      case SeasonType.notRecommended:
        return 'Not Recommended';
    }
  }
}

// Planting data for different hemispheres
class PlantingData {
  static PlantingInfo getPlantingInfo(PlantType plantType, bool isNorthernHemisphere) {
    switch (plantType) {
      case PlantType.lettuce:
        return _getLettuceInfo(isNorthernHemisphere);
      case PlantType.strawberry:
        return _getStrawberryInfo(isNorthernHemisphere);
      case PlantType.blueberry:
        return _getBlueberryInfo(isNorthernHemisphere);
    }
  }

  static PlantingInfo _getLettuceInfo(bool isNorthern) {
    final seasons = isNorthern
        ? [
            PlantingSeason(
              name: 'Spring Planting',
              startMonth: 3,
              endMonth: 5,
              type: SeasonType.ideal,
              description: 'Perfect time for cool-season lettuce',
            ),
            PlantingSeason(
              name: 'Fall Planting',
              startMonth: 9,
              endMonth: 10,
              type: SeasonType.ideal,
              description: 'Another ideal window before frost',
            ),
            PlantingSeason(
              name: 'Summer',
              startMonth: 6,
              endMonth: 8,
              type: SeasonType.possible,
              description: 'Choose heat-tolerant varieties',
            ),
            PlantingSeason(
              name: 'Winter',
              startMonth: 11,
              endMonth: 2,
              type: SeasonType.notRecommended,
              description: 'Indoor growing only',
            ),
          ]
        : [
            PlantingSeason(
              name: 'Autumn Planting',
              startMonth: 3,
              endMonth: 5,
              type: SeasonType.ideal,
              description: 'Perfect cool-season conditions',
            ),
            PlantingSeason(
              name: 'Spring Planting',
              startMonth: 9,
              endMonth: 11,
              type: SeasonType.ideal,
              description: 'Ideal temperatures for growth',
            ),
          ];

    return PlantingInfo(
      plantType: PlantType.lettuce,
      region: isNorthern ? 'Northern Hemisphere' : 'Southern Hemisphere',
      seasons: seasons,
      tips: [
        'Plant in partial shade during warmer months',
        'Keep soil consistently moist',
        'Harvest outer leaves first for continuous growth',
        'Succession plant every 2-3 weeks for continuous harvest',
      ],
    );
  }

  static PlantingInfo _getStrawberryInfo(bool isNorthern) {
    final seasons = isNorthern
        ? [
            PlantingSeason(
              name: 'Early Spring',
              startMonth: 3,
              endMonth: 4,
              type: SeasonType.ideal,
              description: 'Best time for bare-root strawberries',
            ),
            PlantingSeason(
              name: 'Late Summer/Fall',
              startMonth: 8,
              endMonth: 9,
              type: SeasonType.possible,
              description: 'Plant for next year\'s harvest',
            ),
          ]
        : [
            PlantingSeason(
              name: 'Autumn',
              startMonth: 3,
              endMonth: 5,
              type: SeasonType.ideal,
              description: 'Plant for spring harvest',
            ),
            PlantingSeason(
              name: 'Late Winter',
              startMonth: 8,
              endMonth: 9,
              type: SeasonType.possible,
              description: 'Early planting for longer season',
            ),
          ];

    return PlantingInfo(
      plantType: PlantType.strawberry,
      region: isNorthern ? 'Northern Hemisphere' : 'Southern Hemisphere',
      seasons: seasons,
      tips: [
        'Choose a sunny location with 6-8 hours of sunlight',
        'Use raised beds for better drainage',
        'Mulch to keep berries clean and retain moisture',
        'Remove runners for larger berries, keep for more plants',
      ],
    );
  }

  static PlantingInfo _getBlueberryInfo(bool isNorthern) {
    final seasons = isNorthern
        ? [
            PlantingSeason(
              name: 'Early Spring',
              startMonth: 3,
              endMonth: 4,
              type: SeasonType.ideal,
              description: 'Plant before new growth begins',
            ),
            PlantingSeason(
              name: 'Fall',
              startMonth: 10,
              endMonth: 11,
              type: SeasonType.possible,
              description: 'Allow roots to establish before winter',
            ),
          ]
        : [
            PlantingSeason(
              name: 'Autumn',
              startMonth: 4,
              endMonth: 6,
              type: SeasonType.ideal,
              description: 'Ideal planting window',
            ),
            PlantingSeason(
              name: 'Late Winter',
              startMonth: 8,
              endMonth: 9,
              type: SeasonType.possible,
              description: 'Before spring growth',
            ),
          ];

    return PlantingInfo(
      plantType: PlantType.blueberry,
      region: isNorthern ? 'Northern Hemisphere' : 'Southern Hemisphere',
      seasons: seasons,
      tips: [
        'Require acidic soil (pH 4.5-5.5)',
        'Plant at least 2 varieties for cross-pollination',
        'Add sulfur to lower soil pH if needed',
        'Patience required - full production takes 3-4 years',
      ],
    );
  }
}
