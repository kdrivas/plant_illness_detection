import 'plant_type.dart';

/// Harvest tracking model for counting optimal growing days
class HarvestTracker {
  final String id;
  final String blockId;
  final PlantType plantType;
  final DateTime startDate;
  final int optimalDaysCount;
  final int targetDays;
  final bool isComplete;
  final DateTime? completedDate;
  final String? notes;

  HarvestTracker({
    required this.id,
    required this.blockId,
    required this.plantType,
    required this.startDate,
    this.optimalDaysCount = 0,
    required this.targetDays,
    this.isComplete = false,
    this.completedDate,
    this.notes,
  });

  /// Calculate progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetDays <= 0) return 0.0;
    return (optimalDaysCount / targetDays).clamp(0.0, 1.0);
  }

  /// Days remaining until harvest
  int get daysRemaining {
    final remaining = targetDays - optimalDaysCount;
    return remaining > 0 ? remaining : 0;
  }

  /// Whether the plant is ready for harvest
  bool get isReadyForHarvest => optimalDaysCount >= targetDays;

  /// Current growing duration in days
  int get growingDays {
    final now = DateTime.now();
    return now.difference(startDate).inDays;
  }

  /// Estimated harvest date based on current progress
  DateTime? get estimatedHarvestDate {
    if (isComplete) return completedDate;
    if (optimalDaysCount <= 0) return null;
    
    // Calculate average optimal days per real day
    final realDays = growingDays;
    if (realDays <= 0) return null;
    
    final avgOptimalPerDay = optimalDaysCount / realDays;
    if (avgOptimalPerDay <= 0) return null;
    
    final remainingRealDays = (daysRemaining / avgOptimalPerDay).ceil();
    return DateTime.now().add(Duration(days: remainingRealDays));
  }

  factory HarvestTracker.create({
    required String blockId,
    required PlantType plantType,
    String? notes,
  }) {
    return HarvestTracker(
      id: '${blockId}_${DateTime.now().millisecondsSinceEpoch}',
      blockId: blockId,
      plantType: plantType,
      startDate: DateTime.now(),
      targetDays: _getTargetDays(plantType),
      notes: notes,
    );
  }

  static int _getTargetDays(PlantType plantType) {
    switch (plantType) {
      case PlantType.lettuce:
        return 45; // 45 days to harvest
      case PlantType.strawberry:
        return 90; // 90 days to harvest
      case PlantType.blueberry:
        return 120; // 120 days to harvest (for established plants)
    }
  }

  factory HarvestTracker.fromJson(Map<String, dynamic> json) {
    return HarvestTracker(
      id: json['id'] ?? '',
      blockId: json['blockId'] ?? json['block_id'] ?? '',
      plantType: PlantType.values.firstWhere(
        (e) => e.name == (json['plantType'] ?? json['plant_type']),
        orElse: () => PlantType.lettuce,
      ),
      startDate: json['startDate'] != null || json['start_date'] != null
          ? DateTime.parse(json['startDate'] ?? json['start_date'])
          : DateTime.now(),
      optimalDaysCount: json['optimalDaysCount'] ?? json['optimal_days_count'] ?? 0,
      targetDays: json['targetDays'] ?? json['target_days'] ?? 45,
      isComplete: json['isComplete'] ?? json['is_complete'] ?? false,
      completedDate: json['completedDate'] != null || json['completed_date'] != null
          ? DateTime.parse(json['completedDate'] ?? json['completed_date'])
          : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'blockId': blockId,
      'plantType': plantType.name,
      'startDate': startDate.toIso8601String(),
      'optimalDaysCount': optimalDaysCount,
      'targetDays': targetDays,
      'isComplete': isComplete,
      'completedDate': completedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  HarvestTracker copyWith({
    String? id,
    String? blockId,
    PlantType? plantType,
    DateTime? startDate,
    int? optimalDaysCount,
    int? targetDays,
    bool? isComplete,
    DateTime? completedDate,
    String? notes,
  }) {
    return HarvestTracker(
      id: id ?? this.id,
      blockId: blockId ?? this.blockId,
      plantType: plantType ?? this.plantType,
      startDate: startDate ?? this.startDate,
      optimalDaysCount: optimalDaysCount ?? this.optimalDaysCount,
      targetDays: targetDays ?? this.targetDays,
      isComplete: isComplete ?? this.isComplete,
      completedDate: completedDate ?? this.completedDate,
      notes: notes ?? this.notes,
    );
  }

  /// Mark this harvest as complete
  HarvestTracker markComplete() {
    return copyWith(
      isComplete: true,
      completedDate: DateTime.now(),
    );
  }

  /// Increment optimal days count
  HarvestTracker incrementOptimalDays([int days = 1]) {
    return copyWith(
      optimalDaysCount: optimalDaysCount + days,
    );
  }
}

/// Summary of harvest status for UI display
class HarvestSummary {
  final int activeHarvests;
  final int readyForHarvest;
  final int completedThisMonth;
  final List<HarvestTracker> trackers;

  HarvestSummary({
    required this.activeHarvests,
    required this.readyForHarvest,
    required this.completedThisMonth,
    required this.trackers,
  });

  factory HarvestSummary.fromTrackers(List<HarvestTracker> trackers) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    
    final active = trackers.where((t) => !t.isComplete).toList();
    final ready = active.where((t) => t.isReadyForHarvest).length;
    final completedThisMonth = trackers
        .where((t) => 
            t.isComplete && 
            t.completedDate != null &&
            t.completedDate!.isAfter(thisMonth))
        .length;

    return HarvestSummary(
      activeHarvests: active.length,
      readyForHarvest: ready,
      completedThisMonth: completedThisMonth,
      trackers: trackers,
    );
  }
}
