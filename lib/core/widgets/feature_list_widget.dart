import 'package:flutter/material.dart';

import '../theme/themes.dart';
import 'custom_chip.dart';
import 'multi_select_sheet.dart';

class FeatureListWidget extends StatelessWidget {
  final List<String> selectedFeatures;
  final List<String> availableDefaults;
  final ValueChanged<String> onAdd;
  final ValueChanged<String> onRemove;
  final String categoryLabel;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const FeatureListWidget({
    super.key,
    required this.selectedFeatures,
    required this.availableDefaults,
    required this.onAdd,
    required this.onRemove,
    required this.categoryLabel,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedFeatures.isEmpty) {
      return _buildEmpty(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: selectedFeatures
              .map(
                (f) => CustomChip(
                  label: f,
                  onDelete: () => onRemove(f),
                  theme: theme,
                ),
              )
              .toList(),
        ),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'None selected',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _showAddSheet(context),
          icon: const Icon(Icons.add, size: 20),
          label: Text('Add $categoryLabel'),
          style: OutlinedButton.styleFrom(
            backgroundColor: theme.cardBackgroundColor,
            foregroundColor: theme.primaryColor,
            side: BorderSide(
              color: theme.primaryColor.withValues(alpha: 0.4),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSheet(BuildContext context) async {
    final picked = await showMultiSelectSheet<String>(
      context: context,
      theme: theme,
      title: 'Add $categoryLabel',
      options: availableDefaults
          .where((d) => !selectedFeatures.contains(d))
          .toList(),
      labelOf: (f) => f,
      createCustom: (text) => text,
    );
    for (final feature in picked ?? const <String>[]) {
      onAdd(feature);
    }
  }
}
