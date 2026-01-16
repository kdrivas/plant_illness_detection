import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/plant_type.dart';
import '../theme/app_colors.dart';

class PlantPickerSheet extends StatelessWidget {
  final PlantType? selectedPlant;
  final ValueChanged<PlantType> onSelected;

  const PlantPickerSheet({
    super.key,
    this.selectedPlant,
    required this.onSelected,
  });

  static Future<PlantType?> show(
    BuildContext context, {
    PlantType? currentSelection,
  }) {
    return showModalBottomSheet<PlantType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PlantPickerSheet(
        selectedPlant: currentSelection,
        onSelected: (plant) => Navigator.pop(context, plant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textHint.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Text(
            'Select Plant Type',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the plant you want to monitor',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          
          // Plant options
          ...PlantType.values.map((plant) => _PlantOption(
            plant: plant,
            isSelected: plant == selectedPlant,
            onTap: () => onSelected(plant),
          )).toList(),
          
          const SizedBox(height: 16),
        ],
      ),
    ).animate().slideY(
      begin: 0.3,
      end: 0,
      duration: 300.ms,
      curve: Curves.easeOut,
    );
  }
}

class _PlantOption extends StatelessWidget {
  final PlantType plant;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlantOption({
    required this.plant,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? plant.color.withOpacity(0.15) 
                : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? plant.color : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Plant emoji/icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: plant.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    plant.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Plant info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.displayName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? plant.color : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plant.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: plant.color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ).animate().scale(
                  begin: const Offset(0, 0),
                  end: const Offset(1, 1),
                  duration: 200.ms,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline plant selector chip
class PlantSelectorChip extends StatelessWidget {
  final PlantType selectedPlant;
  final ValueChanged<PlantType> onChanged;

  const PlantSelectorChip({
    super.key,
    required this.selectedPlant,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final result = await PlantPickerSheet.show(
          context,
          currentSelection: selectedPlant,
        );
        if (result != null) {
          onChanged(result);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selectedPlant.color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selectedPlant.color.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(selectedPlant.emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
              selectedPlant.displayName,
              style: TextStyle(
                color: selectedPlant.color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down,
              color: selectedPlant.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
