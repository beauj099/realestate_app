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
import '../../data/models/listing_details.dart';
import '../widgets/details_fields.dart';
import '../widgets/section_list.dart';
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
        if (ref.read(propertyViewModelProvider).errorMessage == null) {
          await viewModel.saveDetails();
        }
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            onChanged: (val) => viewModel.updateTechnicalSpecs(erfSize: val),
          ),
          const SizedBox(height: 18),
          CustomTextInput(
            theme: theme,
            label: 'Floor Area (m\u00B2)',
            placeholder: '0.00',
            initialValue: state.floorArea,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
            ],
            onChanged: (val) => viewModel.updateTechnicalSpecs(floorArea: val),
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
          const SizedBox(height: 28),
          _BuildingDetails(
            details: state.details,
            theme: theme,
            onChanged: (change) => viewModel.editDetails(change),
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

/// The myEdge form's building details: ownership and type of home, the
/// home's overall condition, construction and views.
class _BuildingDetails extends StatelessWidget {
  final ListingDetails details;
  final RealEstateTheme theme;
  final void Function(ListingDetails Function(ListingDetails d)) onChanged;

  const _BuildingDetails({
    required this.details,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final d = details;
    const gap = SizedBox(height: 24);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldHeading('Ownership', theme: theme),
        SingleChoiceChips(
          options: ListingDetails.ownershipTypes,
          selected: d.ownershipType,
          theme: theme,
          onChanged: (v) => onChanged((d) => d.copyWith(ownershipType: v)),
        ),
        gap,
        FieldHeading('Type of home', theme: theme),
        SingleChoiceChips(
          options: ListingDetails.subtypes,
          selected: d.subtype,
          theme: theme,
          onChanged: (v) => onChanged((d) => d.copyWith(subtype: v)),
        ),
        gap,
        FieldHeading(
          'Overall condition',
          hint: 'The home as a whole, as CMA tools rate it.',
          theme: theme,
        ),
        SingleChoiceChips(
          options: ListingDetails.overallConditions,
          selected: d.overallCondition,
          theme: theme,
          onChanged: (v) => onChanged((d) => d.copyWith(overallCondition: v)),
        ),
        gap,
        FieldHeading('Construction', theme: theme),
        RowsCard(
          theme: theme,
          children: [
            PickRow(
              title: 'Style',
              icon: Icons.architecture_outlined,
              options: ListingDetails.styles,
              selected: [if (d.style.isNotEmpty) d.style],
              multi: false,
              theme: theme,
              onChanged: (v) =>
                  onChanged((d) => d.copyWith(style: v.isEmpty ? '' : v.first)),
            ),
            PickRow(
              title: 'Roof',
              icon: Icons.roofing_outlined,
              options: ListingDetails.roofs,
              selected: d.roof,
              theme: theme,
              onChanged: (v) => onChanged((d) => d.copyWith(roof: v)),
            ),
            PickRow(
              title: 'Walls',
              icon: Icons.foundation_outlined,
              options: ListingDetails.wallTypes,
              selected: d.walls,
              theme: theme,
              onChanged: (v) => onChanged((d) => d.copyWith(walls: v)),
            ),
            PickRow(
              title: 'Windows',
              icon: Icons.window_outlined,
              options: ListingDetails.windowTypes,
              selected: d.windows,
              theme: theme,
              onChanged: (v) => onChanged((d) => d.copyWith(windows: v)),
            ),
          ],
        ),
        gap,
        FieldHeading('Views', theme: theme),
        MultiChoiceChips(
          options: ListingDetails.viewOptions,
          selected: d.views,
          theme: theme,
          onChanged: (v) => onChanged((d) => d.copyWith(views: v)),
        ),
        gap,
        CustomTextInput(
          theme: theme,
          label: 'Height restriction',
          placeholder: 'e.g. 2 storeys, 8 m',
          initialValue: d.heightRestriction,
          onChanged: (v) => onChanged((d) => d.copyWith(heightRestriction: v)),
        ),
        const SizedBox(height: 14),
        CustomTextInput(
          theme: theme,
          label: 'Special features',
          placeholder: 'e.g. separate flat, wine cellar, solar',
          initialValue: d.specialFeatures,
          maxLines: 2,
          onChanged: (v) => onChanged((d) => d.copyWith(specialFeatures: v)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Subdivision rights'),
          value: d.subdivisionRights,
          onChanged: (v) => onChanged((d) => d.copyWith(subdivisionRights: v)),
        ),
      ],
    );
  }
}
