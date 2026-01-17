import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/widgets/sensor_line_chart.dart';
import '../../../../core/widgets/sensor_gauge_card.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/widgets/alert_widgets.dart';
import '../../../../models/sensor_data.dart';
import '../../../../models/plant_type.dart';
import '../../../../providers/app_providers.dart';

class SensorsScreen extends ConsumerStatefulWidget {
  const SensorsScreen({super.key});

  @override
  ConsumerState<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends ConsumerState<SensorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChartTimeframe _selectedTimeframe = ChartTimeframe.twentyFourHours;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedBlock = ref.watch(selectedBlockProvider);
    final selectedRow = ref.watch(selectedRowProvider);
    final selectedPlant = ref.watch(selectedPlantProvider);
    final availableRows = ref.watch(availableRowsProvider);
    final sensorDataAsync = ref.watch(sensorDataStreamProvider(selectedBlock));
    final alerts = ref.watch(activeAlertsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // Fixed Header
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title and Plant selector
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sensor Data',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        // Plant selector chip
                        _PlantChip(
                          plant: selectedPlant,
                          onTap: () => _showPlantPicker(context, ref),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Charts'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _OverviewTab(
                  sensorDataAsync: sensorDataAsync,
                  alerts: alerts,
                  selectedRow: selectedRow,
                ),

                // Charts Tab
                _ChartsTab(
                  selectedBlock: selectedBlock,
                  selectedRow: selectedRow,
                  timeframe: _selectedTimeframe,
                  onTimeframeChanged: (tf) {
                    setState(() {
                      _selectedTimeframe = tf;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPlantPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Plant',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...PlantType.values.map((plant) => ListTile(
                  leading: Icon(
                    plant == PlantType.lettuce
                        ? Icons.eco
                        : plant == PlantType.strawberry
                            ? Icons.spa
                            : Icons.grass,
                    color: plant == PlantType.lettuce
                        ? AppColors.lettuce
                        : plant == PlantType.strawberry
                            ? AppColors.strawberry
                            : AppColors.blueberry,
                  ),
                  title: Text(plant.displayName),
                  trailing: ref.watch(selectedPlantProvider) == plant
                      ? const Icon(Icons.check, color: AppColors.primaryGreen)
                      : null,
                  onTap: () {
                    ref.read(selectedPlantProvider.notifier).state = plant;
                    ref.read(selectedRowProvider.notifier).state = 'row_1';
                    Navigator.pop(context);
                  },
                )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _PlantChip extends StatelessWidget {
  final PlantType plant;
  final VoidCallback onTap;

  const _PlantChip({required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = plant == PlantType.lettuce
        ? AppColors.lettuce
        : plant == PlantType.strawberry
            ? AppColors.strawberry
            : AppColors.blueberry;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              plant.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _RowSelector extends StatelessWidget {
  final String selectedRow;
  final List<String> rows;
  final ValueChanged<String> onChanged;

  const _RowSelector({
    required this.selectedRow,
    required this.rows,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure selectedRow is in the list, otherwise use first available
    final validatedRow = rows.contains(selectedRow) 
        ? selectedRow 
        : (rows.isNotEmpty ? rows.first : null);
    
    if (validatedRow == null || rows.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: validatedRow,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
          dropdownColor: AppColors.primaryGreen,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          items: rows.map((row) {
            return DropdownMenuItem(
              value: row,
              child: Text(row),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) onChanged(value);
          },
        ),
      ),
    );
  }
}

class _RowSelectorCard extends StatelessWidget {
  final String selectedRow;
  final List<String> rows;
  final ValueChanged<String> onChanged;

  const _RowSelectorCard({
    required this.selectedRow,
    required this.rows,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure selectedRow is in the list, otherwise use first available
    final validatedRow = rows.contains(selectedRow) 
        ? selectedRow 
        : (rows.isNotEmpty ? rows.first : null);
    
    if (validatedRow == null || rows.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Icon(
            Icons.view_column_outlined,
            color: AppColors.primaryGreen,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Row:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: validatedRow,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryGreen),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  items: rows.map((row) {
                    return DropdownMenuItem(
                      value: row,
                      child: Text(row),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) onChanged(value);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  final AsyncValue<BlockSensorData> sensorDataAsync;
  final List alerts;
  final String selectedRow;

  const _OverviewTab({
    required this.sensorDataAsync,
    required this.alerts,
    required this.selectedRow,
  });

  @override
  Widget build(BuildContext context) {
    return sensorDataAsync.when(
      loading: () => _buildEmptyStateView(context, isLoading: true),
      error: (e, _) => _buildEmptyStateView(context, isLoading: false),
      data: (data) => _buildDataView(context, data),
    );
  }

  Widget _buildEmptyStateView(BuildContext context, {required bool isLoading}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Not Connected status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading ? 'Connecting...' : 'Data Not Connected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      isLoading 
                          ? 'Establishing connection to sensors...'
                          : 'Connect your sensors to view real-time data',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.8),
                          ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Current Values Section
        const SectionHeader(title: '📊 Current Values'),
        const SizedBox(height: 12),

        // Grid of gauges - all showing no data
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: [
            SensorGaugeCard(
              title: 'EC Level',
              value: 0,
              unit: 'mS/cm',
              minValue: 0,
              maxValue: 5,
              optimalMin: 1.2,
              optimalMax: 2.5,
              color: AppColors.chartEC.withOpacity(0.3),
              icon: Icons.electric_bolt,
              showNoData: true,
            ),
            SensorGaugeCard(
              title: 'pH Level',
              value: 0,
              unit: '',
              minValue: 0,
              maxValue: 14,
              optimalMin: 5.5,
              optimalMax: 7.0,
              color: AppColors.chartPH.withOpacity(0.3),
              icon: Icons.science,
              showNoData: true,
            ),
            SensorGaugeCard(
              title: 'Water Temp',
              value: 0,
              unit: '°C',
              minValue: 0,
              maxValue: 40,
              optimalMin: 18,
              optimalMax: 24,
              color: AppColors.chartWaterTemp.withOpacity(0.3),
              icon: Icons.thermostat,
              showNoData: true,
            ),
            SensorGaugeCard(
              title: 'Weather Temp',
              value: 0,
              unit: '°C',
              minValue: -10,
              maxValue: 50,
              optimalMin: 15,
              optimalMax: 30,
              color: AppColors.chartWeatherTemp.withOpacity(0.3),
              icon: Icons.wb_sunny,
              showNoData: true,
            ),
            SensorGaugeCard(
              title: 'Humidity',
              value: 0,
              unit: '%',
              minValue: 0,
              maxValue: 100,
              optimalMin: 50,
              optimalMax: 70,
              color: AppColors.chartHumidity.withOpacity(0.3),
              icon: Icons.water_drop,
              showNoData: true,
            ),
            SensorGaugeCard(
              title: 'UV Index',
              value: 0,
              unit: '',
              minValue: 0,
              maxValue: 11,
              optimalMin: 3,
              optimalMax: 6,
              color: AppColors.chartUV.withOpacity(0.3),
              icon: Icons.wb_twilight,
              showNoData: true,
            ),
          ],
        ),

        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildDataView(BuildContext context, BlockSensorData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Connection status
        _ConnectionStatus(
          rowId: selectedRow,
          timestamp: data.timestamp,
        ).animate().fadeIn(delay: 100.ms),

        const SizedBox(height: 16),

        // Alerts section
        if (alerts.isNotEmpty) ...[
          const SectionHeader(title: '⚠️ Active Alerts'),
          const SizedBox(height: 8),
          ...alerts.take(3).map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AlertCard(alert: alert),
              )),
          const SizedBox(height: 16),
        ],

        // Current Values Section
        const SectionHeader(title: '📊 Current Values'),
        const SizedBox(height: 12),

        // Grid of gauges with real data
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.75,
          children: [
            SensorGaugeCard(
              title: 'EC Level',
              value: data.ecLevel,
              unit: 'mS/cm',
              minValue: 0,
              maxValue: 5,
              optimalMin: 1.2,
              optimalMax: 2.5,
              color: AppColors.chartEC,
              icon: Icons.electric_bolt,
            ),
            SensorGaugeCard(
              title: 'pH Level',
              value: data.phLevel,
              unit: '',
              minValue: 0,
              maxValue: 14,
              optimalMin: 5.5,
              optimalMax: 7.0,
              color: AppColors.chartPH,
              icon: Icons.science,
            ),
            SensorGaugeCard(
              title: 'Water Temp',
              value: data.waterTemp,
              unit: '°C',
              minValue: 0,
              maxValue: 40,
              optimalMin: 18,
              optimalMax: 24,
              color: AppColors.chartWaterTemp,
              icon: Icons.thermostat,
            ),
            SensorGaugeCard(
              title: 'Weather Temp',
              value: data.weatherTemp,
              unit: '°C',
              minValue: -10,
              maxValue: 50,
              optimalMin: 15,
              optimalMax: 30,
              color: AppColors.chartWeatherTemp,
              icon: Icons.wb_sunny,
            ),
            SensorGaugeCard(
              title: 'Humidity',
              value: data.humidity,
              unit: '%',
              minValue: 0,
              maxValue: 100,
              optimalMin: 50,
              optimalMax: 70,
              color: AppColors.chartHumidity,
              icon: Icons.water_drop,
            ),
            SensorGaugeCard(
              title: 'UV Index',
              value: data.uvIndex,
              unit: '',
              minValue: 0,
              maxValue: 11,
              optimalMin: 3,
              optimalMax: 6,
              color: AppColors.chartUV,
              icon: Icons.wb_twilight,
            ),
          ],
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

class _ChartsTab extends ConsumerWidget {
  final String selectedBlock;
  final String selectedRow;
  final ChartTimeframe timeframe;
  final ValueChanged<ChartTimeframe> onTimeframeChanged;

  const _ChartsTab({
    required this.selectedBlock,
    required this.selectedRow,
    required this.timeframe,
    required this.onTimeframeChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sensorHistoryProvider(timeframe.hours));
    final availableRows = ref.watch(availableRowsProvider);

    return historyAsync.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => _buildEmptyChartsView(context, ref, availableRows),
      data: (historyData) {
        if (historyData.isEmpty) {
          return _buildEmptyChartsView(context, ref, availableRows);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Row selector at the top
            _RowSelectorCard(
              selectedRow: selectedRow,
              rows: availableRows,
              onChanged: (row) {
                ref.read(selectedRowProvider.notifier).state = row;
              },
            ),

            const SizedBox(height: 16),

            // Timeframe selector
            TimeframeChips(
              selected: timeframe,
              onChanged: onTimeframeChanged,
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 20),

            // AI Insights Card (Recommendations based on historical data)
            _InsightsCard(
              historyData: historyData,
              selectedRow: selectedRow,
            ).animate().fadeIn(delay: 150.ms),

            const SizedBox(height: 20),

            // Moisture Chart
            _ChartSection(
              title: 'Soil Moisture',
              subtitle: 'Optimal range: 40-70%',
              metric: SensorMetric.moisture,
              data: historyData,
              timeframe: timeframe,
            ).animate().fadeIn(delay: 200.ms),

            // Water Supplied Chart
            _ChartSection(
              title: 'Water Supplied',
              subtitle: 'Liters dispensed',
              metric: SensorMetric.waterSupplied,
              data: historyData,
              timeframe: timeframe,
              showOptimalRange: false,
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 100),
          ],
        );
      },
    );
  }

  Widget _buildEmptyChartsView(BuildContext context, WidgetRef ref, List<String> availableRows) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Row selector at the top
        _RowSelectorCard(
          selectedRow: selectedRow,
          rows: availableRows,
          onChanged: (row) {
            ref.read(selectedRowProvider.notifier).state = row;
          },
        ),

        const SizedBox(height: 16),

        // Timeframe selector
        TimeframeChips(
          selected: timeframe,
          onChanged: onTimeframeChanged,
        ),

        const SizedBox(height: 20),

        // Empty Moisture Chart
        _EmptyChartSection(
          title: 'Soil Moisture',
          subtitle: 'Optimal range: 40-70%',
          icon: Icons.grass,
          color: AppColors.chartMoisture,
        ),

        // Empty Water Supplied Chart
        _EmptyChartSection(
          title: 'Water Supplied',
          subtitle: 'Liters dispensed',
          icon: Icons.water,
          color: AppColors.chartWaterSupplied,
        ),

        const SizedBox(height: 100),
      ],
    );
  }
}

class _InsightsCard extends StatelessWidget {
  final List<BlockSensorData> historyData;
  final String selectedRow;

  const _InsightsCard({
    required this.historyData,
    required this.selectedRow,
  });

  @override
  Widget build(BuildContext context) {
    final insights = _generateInsights();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryGreen.withOpacity(0.1),
            AppColors.accentBlue.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Insights for $selectedRow',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryGreen,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      insight.icon,
                      size: 16,
                      color: insight.color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.message,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
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

  List<_Insight> _generateInsights() {
    if (historyData.isEmpty) {
      return [
        _Insight(
          icon: Icons.info_outline,
          message: 'No historical data available for analysis.',
          color: AppColors.info,
        ),
      ];
    }

    final insights = <_Insight>[];
    
    // Analyze moisture trends
    final moistureValues = historyData.map((d) => d.moisture).toList();
    final avgMoisture = moistureValues.reduce((a, b) => a + b) / moistureValues.length;
    final recentMoisture = moistureValues.length > 3 
        ? moistureValues.sublist(moistureValues.length - 3).reduce((a, b) => a + b) / 3
        : avgMoisture;

    if (recentMoisture < 40) {
      insights.add(_Insight(
        icon: Icons.warning_amber,
        message: 'Moisture is trending low (${recentMoisture.toStringAsFixed(0)}%). Consider increasing irrigation.',
        color: AppColors.warningAmber,
      ));
    } else if (recentMoisture > 70) {
      insights.add(_Insight(
        icon: Icons.warning_amber,
        message: 'Moisture is high (${recentMoisture.toStringAsFixed(0)}%). Reduce watering to prevent root issues.',
        color: AppColors.warningAmber,
      ));
    } else {
      insights.add(_Insight(
        icon: Icons.check_circle_outline,
        message: 'Moisture levels are optimal (${recentMoisture.toStringAsFixed(0)}%). Plants are well hydrated.',
        color: AppColors.success,
      ));
    }

    // Analyze water consumption
    final waterValues = historyData.map((d) => d.waterSupplied).toList();
    final totalWater = waterValues.reduce((a, b) => a + b);
    
    insights.add(_Insight(
      icon: Icons.water_drop,
      message: 'Total water supplied: ${totalWater.toStringAsFixed(1)}L in the selected timeframe.',
      color: AppColors.info,
    ));

    // Trend prediction
    if (moistureValues.length >= 6) {
      final trend = recentMoisture - avgMoisture;
      if (trend < -5) {
        insights.add(_Insight(
          icon: Icons.trending_down,
          message: 'Moisture is decreasing. Next irrigation recommended in ~2 hours.',
          color: AppColors.accentOrange,
        ));
      } else if (trend > 5) {
        insights.add(_Insight(
          icon: Icons.trending_up,
          message: 'Moisture is increasing. Consider delaying next irrigation.',
          color: AppColors.accentBlue,
        ));
      }
    }

    return insights;
  }
}

class _Insight {
  final IconData icon;
  final String message;
  final Color color;

  _Insight({
    required this.icon,
    required this.message,
    required this.color,
  });
}

class _ConnectionStatus extends StatelessWidget {
  final String rowId;
  final String timestamp;

  const _ConnectionStatus({
    required this.rowId,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final parsedTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    final timeDiff = DateTime.now().difference(parsedTime);
    final isRecent = timeDiff.inMinutes < 5;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isRecent
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warningAmber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecent
              ? AppColors.success.withOpacity(0.3)
              : AppColors.warningAmber.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isRecent ? Icons.wifi : Icons.wifi_off,
            color: isRecent ? AppColors.success : AppColors.warningAmber,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRecent ? 'Connected' : 'Connection Delayed',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: isRecent
                            ? AppColors.success
                            : AppColors.warningAmber,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  '$rowId • Updated ${_formatTimeDiff(timeDiff)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isRecent ? AppColors.success : AppColors.warningAmber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isRecent
                      ? AppColors.success.withOpacity(0.5)
                      : AppColors.warningAmber.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimeDiff(Duration diff) {
    if (diff.inSeconds < 60) {
      return 'just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }
}

class _ChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final SensorMetric metric;
  final List<BlockSensorData> data;
  final ChartTimeframe timeframe;
  final bool showOptimalRange;

  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.metric,
    required this.data,
    required this.timeframe,
    this.showOptimalRange = true,
  });

  @override
  Widget build(BuildContext context) {
    final latestValue = data.isNotEmpty ? metric.getValue(data.last) : 0.0;
    final isOptimal = showOptimalRange ? metric.isOptimal(latestValue) : true;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(metric.icon, color: metric.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOptimal
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.warningAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${latestValue.toStringAsFixed(1)} ${metric.unit}',
                  style: TextStyle(
                    color: isOptimal ? AppColors.success : AppColors.warningAmber,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: SensorLineChart(
              data: data,
              metric: metric,
              minThreshold: showOptimalRange ? metric.optimalMin : null,
              maxThreshold: showOptimalRange ? metric.optimalMax : null,
              timeframe: timeframe,
            ),
          ),
          if (showOptimalRange) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _LegendDot(color: metric.color, label: 'Value'),
                const SizedBox(width: 20),
                _LegendDot(
                  color: AppColors.success.withOpacity(0.3),
                  label: 'Optimal: ${metric.optimalMin.toStringAsFixed(0)} - ${metric.optimalMax.toStringAsFixed(0)}${metric.unit}',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyChartSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _EmptyChartSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color.withOpacity(0.5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '--',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.backgroundLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.show_chart,
                    size: 48,
                    color: AppColors.textHint.withOpacity(0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No data available',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
