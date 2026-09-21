import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../../home/presentation/screens/home_screen.dart'
    show listingsProvider;
import '../../data/models/enums/property_type.dart';
import '../../providers/property_provider.dart';
import '../widgets/exterior_photos_section.dart';
import '../widgets/section_card.dart';

class PropertyOverviewScreen extends ConsumerStatefulWidget {
  final int propertyId;

  const PropertyOverviewScreen({super.key, required this.propertyId});

  @override
  ConsumerState<PropertyOverviewScreen> createState() =>
      _PropertyOverviewScreenState();
}

class _PropertyOverviewScreenState
    extends ConsumerState<PropertyOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Loading used to be kicked off from build(), which fired again on every
    // rebuild and could run several overlapping fetches for one listing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = ref.read(propertyViewModelProvider);
      if (state.listingId != widget.propertyId) {
        ref
            .read(propertyViewModelProvider.notifier)
            .loadListing(widget.propertyId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertyId = widget.propertyId;
    final state = ref.watch(propertyViewModelProvider);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    final theme = ref.watch(themeConfigProvider);
    final textTheme = theme.toThemeData().textTheme;

    final sections = [
      _SectionData(
        title: 'Address',
        subtitle: state.street.isNotEmpty
            ? '${state.streetNumber} ${state.street}'
            : 'Not provided',
        icon: Icons.location_on_outlined,
        route: AppRoutes.address(propertyId),
        isComplete: state.street.isNotEmpty && state.city.isNotEmpty,
      ),
      _SectionData(
        title: 'Building Info',
        subtitle: state.erfSize.isNotEmpty
            ? '${state.erfSize} m\u00B2'
            : 'Not provided',
        icon: Icons.architecture_outlined,
        route: AppRoutes.buildingInfo(propertyId),
        isComplete: state.erfSize.isNotEmpty || state.floorArea.isNotEmpty,
      ),
      _SectionData(
        title: 'Property Features',
        subtitle: state.rooms.isNotEmpty
            ? '${state.rooms.length} room(s)'
            : 'Not provided',
        icon: Icons.meeting_room_outlined,
        route: AppRoutes.propertyFeatures(propertyId),
        isComplete: state.rooms.isNotEmpty,
      ),
      _SectionData(
        title: 'Expenses',
        subtitle: state.propertyRunningCosts.monthlyRates.isNotEmpty
            ? 'Rates R ${state.propertyRunningCosts.monthlyRates}/month'
            : 'Not provided',
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.expenses(propertyId),
        // Valuation moved out of this section, so completion now tracks the
        // running costs the agent actually captures on site.
        isComplete: state.propertyRunningCosts.monthlyRates.isNotEmpty,
      ),
      _SectionData(
        title: 'Owner Details',
        subtitle: state.primaryContact.fullName.isNotEmpty
            ? state.primaryContact.fullName
            : 'Not provided',
        icon: Icons.contacts_outlined,
        route: AppRoutes.ownerDetails(propertyId),
        isComplete: state.primaryContact.fullName.isNotEmpty,
      ),
      // Last on purpose: pricing is settled once the property has been walked.
      _SectionData(
        title: 'Valuation',
        subtitle: state.listingValuation.ownersNetPrice.isNotEmpty
            ? 'R ${state.listingValuation.ownersNetPrice}'
            : 'Not provided',
        icon: Icons.sell_outlined,
        route: AppRoutes.valuation(propertyId),
        isComplete: state.listingValuation.ownersNetPrice.isNotEmpty,
      ),
    ];

    final selectedType = PropertyTypeExtension.fromId(state.propertyTypeId);
    final allComplete =
        selectedType != null && sections.every((s) => s.isComplete);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.cardBackgroundColor,
        surfaceTintColor: theme.cardBackgroundColor,
        title: Text(
          'Property Details',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.textPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.error),
            onPressed: () =>
                _confirmDelete(context, ref, viewModel, propertyId),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: theme.borderLight, height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reference: ${state.referenceNumber}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PropertyTypeField(
                      selected: selectedType,
                      theme: theme,
                      textTheme: textTheme,
                      onSelected: (type) async {
                        viewModel.selectPropertyType(type.id);
                        await viewModel.savePropertyType();
                        final error = ref
                            .read(propertyViewModelProvider)
                            .errorMessage;
                        if (error != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                friendlySaveMessage(error, 'property type'),
                              ),
                              backgroundColor: theme.error,
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ExteriorPhotosSection(
                      photos: state.exteriorPhotos,
                      theme: theme,
                      textTheme: textTheme,
                      viewModel: viewModel,
                    ),
                    const SizedBox(height: 24),
                    ...sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SectionCard(
                          title: section.title,
                          subtitle: section.subtitle,
                          icon: section.icon,
                          isComplete: section.isComplete,
                          theme: theme,
                          textTheme: textTheme,
                          onTap: () => context.push(section.route),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (allComplete)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: theme.cardBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.borderLight, width: 1),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: CustomButton(
                      text: 'Submit Evaluation',
                      onTap: () async {
                        final success = await viewModel.submitAndSave();
                        if (!context.mounted) return;
                        if (success) {
                          viewModel.reset();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Evaluation submitted successfully!',
                              ),
                              backgroundColor: theme.primaryColor,
                            ),
                          );
                          context.go(AppRoutes.homePath);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.errorMessage ??
                                    'Failed to submit evaluation',
                              ),
                              backgroundColor: theme.error,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    PropertyViewModel viewModel,
    int propertyId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text(
          'Are you sure you want to delete this property? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await viewModel.deleteListing();
      if (context.mounted) {
        ref.invalidate(listingsProvider);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Property deleted')));
        context.go(AppRoutes.homePath);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mapFailure(e).message)),
        );
      }
    }
  }
}

/// Inline property-type dropdown.
///
/// Property type used to own a whole screen holding five tiles. It is a single
/// value, so it lives on this screen as a field and opens a searchable sheet.
class _PropertyTypeField extends StatelessWidget {
  final PropertyType? selected;
  final RealEstateTheme theme;
  final TextTheme textTheme;
  final ValueChanged<PropertyType> onSelected;

  const _PropertyTypeField({
    required this.selected,
    required this.theme,
    required this.textTheme,
    required this.onSelected,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showSearchablePicker<PropertyType>(
      context: context,
      theme: theme,
      title: 'Property Type',
      searchHint: 'Search property types…',
      selectedValue: selected,
      options: PropertyType.values
          .map(
            (t) => PickerOption<PropertyType>(
              value: t,
              label: t.displayString,
              icon: t.icon,
            ),
          )
          .toList(),
    );
    final picked = result?.option?.value;
    if (picked != null) onSelected(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isSet = selected != null;
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSet ? theme.borderLight : theme.pendingColor,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.borderLight.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                selected?.icon ?? Icons.home_outlined,
                size: 20,
                color: isSet ? theme.primaryColor : theme.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Property Type',
                    style: textTheme.labelLarge?.copyWith(
                      color: theme.textLabel,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected?.displayString ?? 'Select a property type',
                    style: textTheme.titleMedium?.copyWith(
                      color: isSet ? theme.textPrimary : theme.textSecondary,
                      fontWeight: isSet ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: theme.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionData {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
  final bool isComplete;

  const _SectionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
    required this.isComplete,
  });
}
