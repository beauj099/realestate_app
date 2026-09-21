import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_chip.dart';
import '../../../../core/widgets/custom_text_input.dart';
import '../../data/models/enums/facing_direction.dart';
import '../../providers/property_provider.dart';
import '../widgets/wizard_section_scaffold.dart';

class BuildingInfoScreen extends ConsumerWidget {
  const BuildingInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    return WizardSectionScaffold(
      title: 'Building Info',
      sectionName: 'building info',
      onSave: () async {
        await viewModel.saveBuildingInfo();
        final error = ref.read(propertyViewModelProvider).errorMessage;
        return error == null
            ? null
            : friendlySaveMessage(error, 'building info');
      },
      child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Physical Blueprint',
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextInput(
                  theme: theme,
                  label: 'Erf Size (m\u00B2)',
                  placeholder: '0.00',
                  initialValue: state.erfSize,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  onChanged: (val) =>
                      viewModel.updateTechnicalSpecs(erfSize: val),
                ),
                const SizedBox(height: 18),
                CustomTextInput(
                  theme: theme,
                  label: 'Floor Area (m\u00B2)',
                  placeholder: '0.00',
                  initialValue: state.floorArea,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                  ],
                  onChanged: (val) =>
                      viewModel.updateTechnicalSpecs(floorArea: val),
                ),
                const SizedBox(height: 18),
                CustomTextInput(
                  theme: theme,
                  label: 'Construction Year',
                  placeholder: 'YYYY',
                  initialValue: state.constructionYear,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (val) =>
                      viewModel.updateTechnicalSpecs(constructionYear: val),
                ),
                const SizedBox(height: 28),
                _buildChipSelector<FacingDirection>(
                  theme: theme,
                  textTheme: textTheme,
                  label: 'Facing Direction',
                  options: FacingDirection.values,
                  selectedOption: state.facingId != null
                      ? FacingDirection.values.firstWhere(
                          (f) => f.index + 1 == state.facingId,
                          orElse: () => FacingDirection.north,
                        )
                      : FacingDirection.north,
                  getLabel: (opt) => opt.displayString,
                  onSelected: (val) => viewModel.selectFacingId(val.index + 1),
                ),
                const SizedBox(height: 24),
                Text(
                  'Zoning',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.textPrimary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 10.0,
                  children:
                      [
                        'Residential 1',
                        'Residential 2',
                        'Commercial',
                        'Agricultural',
                        'Mixed Use',
                      ].map((zone) {
                        final isSelected =
                            (state.zoningId != null &&
                            [1, 2, 3, 4, 5][[
                                  'Residential 1',
                                  'Residential 2',
                                  'Commercial',
                                  'Agricultural',
                                  'Mixed Use',
                                ].indexOf(zone)] ==
                                state.zoningId);
                        return CustomChip(
                          theme: theme,
                          label: zone,
                          isSelected: isSelected,
                          onTap: () => viewModel.selectZoningId(
                            [
                                  'Residential 1',
                                  'Residential 2',
                                  'Commercial',
                                  'Agricultural',
                                  'Mixed Use',
                                ].indexOf(zone) +
                                1,
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
    );
  }

  Widget _buildChipSelector<T>({
    required RealEstateTheme theme,
    required TextTheme textTheme,
    required String label,
    required List<T> options,
    required T selectedOption,
    required String Function(T) getLabel,
    required ValueChanged<T> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 10.0,
          children: options.map((opt) {
            final isSelected = selectedOption == opt;
            return CustomChip(
              theme: theme,
              label: getLabel(opt),
              isSelected: isSelected,
              onTap: () => onSelected(opt),
            );
          }).toList(),
        ),
      ],
    );
  }
}
