import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../core/widgets/wizard_scaffold.dart';
import '../../data/models/enums/property_type.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_actions.dart';

class PropertyTypeStep extends ConsumerWidget {
  const PropertyTypeStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final types = [
      {'type': PropertyType.house, 'icon': Icons.home_outlined, 'id': 1},
      {'type': PropertyType.townhouse, 'icon': Icons.business_outlined, 'id': 2},
      {'type': PropertyType.apartment, 'icon': Icons.corporate_fare_outlined, 'id': 3},
      {'type': PropertyType.vacantLand, 'icon': Icons.terrain_outlined, 'id': 4},
      {'type': PropertyType.plot, 'icon': Icons.grid_view_outlined, 'id': 5},
    ];

    return WizardScaffold(
      title: 'What type of property is this?',
      onBack: () => goBackWizard(context, ref),
      onNext: () => advanceWizard(context, ref),
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.35,
          ),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final item = types[index];
            final itemType = item['type'] as PropertyType;
            final itemIcon = item['icon'] as IconData;
            final itemId = item['id'] as int;
            final isSelected = state.propertyTypeId == itemId;
            return CustomCard(
              theme: theme,
              isSelected: isSelected,
              onTap: () => viewModel.selectPropertyType(itemId),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    itemIcon,
                    size: 26,
                    color: isSelected
                        ? theme.primaryColor
                        : theme.textPrimary.withValues(alpha: 0.6),
                  ),
                  Text(
                    itemType.displayString,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
