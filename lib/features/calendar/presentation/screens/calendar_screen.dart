import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../models/plant_type.dart';
import '../../../../models/planting_info.dart';
import '../../../../providers/app_providers.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  PlantType _selectedPlant = PlantType.lettuce;
  bool _isNorthern = true;

  @override
  void initState() {
    super.initState();
    _detectHemisphere();
  }

  Future<void> _detectHemisphere() async {
    try {
      final locationService = ref.read(locationServiceProvider);
      final isNorthern = await locationService.isNorthernHemisphere();
      setState(() {
        _isNorthern = isNorthern;
      });
    } catch (e) {
      // Default to northern hemisphere
    }
  }

  @override
  Widget build(BuildContext context) {
    final plantingInfo = PlantingData.getPlantingInfo(_selectedPlant, _isNorthern);
    final currentMonth = DateTime.now().month;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.primaryGreen,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Planting Calendar',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 4),
                        Text(
                          _isNorthern
                              ? '🌍 Northern Hemisphere'
                              : '🌍 Southern Hemisphere',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                color: Colors.white.withOpacity(0.8),
                              ),
                        ).animate().fadeIn(delay: 100.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  _isNorthern ? Icons.north : Icons.south,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isNorthern = !_isNorthern;
                  });
                },
                tooltip: 'Toggle Hemisphere',
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // Plant selector
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: PlantType.values.map((plant) {
                      final isSelected = plant == _selectedPlant;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _PlantTab(
                            plant: plant,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedPlant = plant;
                              });
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 24),

                // Year overview
                const SectionHeader(title: '📅 Year Overview'),
                _YearCalendar(
                  plantingInfo: plantingInfo,
                  currentMonth: currentMonth,
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 24),

                // Season details
                const SectionHeader(title: '🌱 Planting Seasons'),
                ..._buildSeasonCards(plantingInfo),

                const SizedBox(height: 24),

                // Growing tips
                const SectionHeader(title: '💡 Growing Tips'),
                _TipsCard(plant: _selectedPlant).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSeasonCards(PlantingInfo info) {
    final cards = <Widget>[];

    for (var i = 0; i < info.seasons.length; i++) {
      cards.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: _SeasonCard(season: info.seasons[i]),
        ).animate(delay: (400 + i * 100).ms).fadeIn().slideX(begin: 0.1),
      );
    }

    return cards;
  }
}

class _PlantTab extends StatelessWidget {
  final PlantType plant;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlantTab({
    required this.plant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? plant.color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? plant.color : AppColors.textHint.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              plant.emoji,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 4),
            Text(
              plant.displayName,
              style: TextStyle(
                color: isSelected ? plant.color : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _YearCalendar extends StatelessWidget {
  final PlantingInfo plantingInfo;
  final int currentMonth;

  const _YearCalendar({
    required this.plantingInfo,
    required this.currentMonth,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          Row(
            children: List.generate(12, (index) {
              final month = index + 1;
              final isCurrent = month == currentMonth;
              final seasonType = _getSeasonTypeForMonth(month);

              return Expanded(
                child: Column(
                  children: [
                    Text(
                      months[index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent
                            ? AppColors.primaryGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: _getSeasonColor(seasonType),
                        borderRadius: BorderRadius.circular(4),
                        border: isCurrent
                            ? Border.all(color: AppColors.primaryGreenDark, width: 2)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LegendItem(
                color: AppColors.success.withOpacity(0.3),
                label: 'Ideal',
              ),
              _LegendItem(
                color: AppColors.harvestGold.withOpacity(0.3),
                label: 'Possible',
              ),
              _LegendItem(
                color: AppColors.surfaceLight,
                label: 'Not Recommended',
              ),
            ],
          ),
        ],
      ),
    );
  }

  SeasonType? _getSeasonTypeForMonth(int month) {
    for (final season in plantingInfo.seasons) {
      if (season.isCurrentSeason(month)) {
        return season.type;
      }
    }
    return null;
  }

  Color _getSeasonColor(SeasonType? type) {
    switch (type) {
      case SeasonType.ideal:
        return AppColors.success.withOpacity(0.3);
      case SeasonType.possible:
        return AppColors.harvestGold.withOpacity(0.3);
      case SeasonType.notRecommended:
      case null:
        return AppColors.surfaceLight;
    }
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SeasonCard extends StatelessWidget {
  final PlantingSeason season;

  const _SeasonCard({required this.season});

  @override
  Widget build(BuildContext context) {
    final iconData = _getSeasonIcon(season.type);
    final color = _getSeasonCardColor(season.type);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  season.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_monthName(season.startMonth)} - ${_monthName(season.endMonth)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  season.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSeasonIcon(SeasonType type) {
    switch (type) {
      case SeasonType.ideal:
        return Icons.spa;
      case SeasonType.possible:
        return Icons.trending_up;
      case SeasonType.notRecommended:
        return Icons.warning_amber;
    }
  }

  Color _getSeasonCardColor(SeasonType type) {
    switch (type) {
      case SeasonType.ideal:
        return AppColors.success;
      case SeasonType.possible:
        return AppColors.harvestGold;
      case SeasonType.notRecommended:
        return AppColors.textSecondary;
    }
  }

  String _monthName(int month) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[month];
  }
}

class _TipsCard extends StatelessWidget {
  final PlantType plant;

  const _TipsCard({required this.plant});

  @override
  Widget build(BuildContext context) {
    final tips = _getTips(plant);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                plant.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                '${plant.displayName} Tips',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  List<String> _getTips(PlantType plant) {
    switch (plant) {
      case PlantType.lettuce:
        return [
          'Plant in cool weather, ideally between 60-70°F (15-21°C)',
          'Provide partial shade in warmer months to prevent bolting',
          'Keep soil consistently moist but not waterlogged',
          'Harvest outer leaves first, allowing center to continue growing',
          'Succession plant every 2-3 weeks for continuous harvest',
        ];
      case PlantType.strawberry:
        return [
          'Plant in early spring or fall for best establishment',
          'Space plants 12-18 inches apart with crowns at soil level',
          'Mulch around plants to retain moisture and prevent fruit rot',
          'Remove runners to promote larger berries, or let them root for new plants',
          'Protect from birds with netting once berries start to ripen',
        ];
      case PlantType.blueberry:
        return [
          'Blueberries require acidic soil with pH between 4.5-5.5',
          'Plant at least two different varieties for cross-pollination',
          'Mulch heavily with pine needles or acidic mulch',
          'Water regularly - they need 1-2 inches per week',
          'Prune in late winter to remove old canes and promote new growth',
        ];
    }
  }
}
