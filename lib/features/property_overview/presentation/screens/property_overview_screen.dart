import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/busy_overlay.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/errors/failure_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/providers/api_providers.dart';
import '../../../../core/locale/region_provider.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/theme/themes.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/real_estate_dialog.dart';
import '../../../../core/widgets/searchable_picker.dart';
import '../../../home/presentation/screens/home_screen.dart'
    show listingsProvider;
import '../../data/models/enums/property_type.dart';
import '../../data/models/property_state.dart';
import '../../data/models/room_score.dart';
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
  bool _isSaving = false;

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
    final currency = ref.watch(regionProvider).currencySymbol;
    final textTheme = theme.toThemeData().textTheme;

    final sections = [
      _SectionData(
        title: 'Address',
        subtitle: state.street.isNotEmpty
            ? '${state.streetNumber} ${state.street}'
            : 'Not provided',
        icon: Icons.location_on_outlined,
        route: AppRoutes.address(propertyId),
        isComplete: state.isAddressComplete,
      ),
      _SectionData(
        title: 'Building Info',
        subtitle: state.erfSize.isNotEmpty
            ? '${state.erfSize} m\u00B2'
            : 'Not provided',
        icon: Icons.architecture_outlined,
        route: AppRoutes.buildingInfo(propertyId),
        isComplete: state.isBuildingInfoComplete,
      ),
      _SectionData(
        title: 'Property Features',
        subtitle: state.rooms.isEmpty
            ? 'Not provided'
            : state.isFeaturesComplete
            ? '${state.rooms.length} room${state.rooms.length == 1 ? '' : 's'}'
            : '${state.ratedRoomCount} of ${state.rooms.length} rooms rated',
        icon: Icons.meeting_room_outlined,
        route: AppRoutes.propertyFeatures(propertyId),
        isComplete: state.isFeaturesComplete,
      ),
      _SectionData(
        title: 'Expenses',
        subtitle: _expensesSummary(state, currency),
        icon: Icons.account_balance_wallet_outlined,
        route: AppRoutes.expenses(propertyId),
        isComplete: state.isExpensesComplete,
      ),
      _SectionData(
        title: 'Owner Details',
        subtitle: state.primaryContact.fullName.isNotEmpty
            ? state.primaryContact.fullName
            : 'Not provided',
        icon: Icons.contacts_outlined,
        route: AppRoutes.ownerDetails(propertyId),
        isComplete: state.isOwnerComplete,
      ),
      // Last on purpose: pricing is settled once the property has been walked.
      _SectionData(
        title: 'Valuation',
        subtitle: state.listingValuation.ownersNetPrice.isNotEmpty
            ? '$currency ${state.listingValuation.ownersNetPrice}'
            : 'Not provided',
        icon: Icons.sell_outlined,
        route: AppRoutes.valuation(propertyId),
        isComplete: state.isValuationComplete,
      ),
    ];

    final selectedType = PropertyTypeExtension.fromId(state.propertyTypeId);
    final allComplete =
        selectedType != null && sections.every((s) => s.isComplete);

    final completeCount = sections.where((s) => s.isComplete).length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isSaving) _leave();
      },
      child: BusyOverlay(
        busy: _isSaving,
        theme: theme,
        title: 'Saving the property…',
        child: Scaffold(
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
              onPressed: _leave,
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
                  // Clamping (not bouncing) so a pointer/hover landing mid-pop
                  // never hit-tests overscroll geometry on a detaching viewport
                  // (viewport.dart:1034 "Unexpected null value" on web/desktop).
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                          baseUrl: ref.watch(apiClientProvider).baseUrl,
                        ),
                        const SizedBox(height: 24),
                        _ProgressSummary(
                          completeCount: completeCount,
                          totalCount: sections.length,
                          houseScore: state.houseScore,
                          isManual: state.houseScoreIsManual,
                          theme: theme,
                          textTheme: textTheme,
                          onAdjustScore: () => _adjustHouseScore(state),
                        ),
                        const SizedBox(height: 16),
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
                _BottomActions(
                  theme: theme,
                  isSaving: _isSaving,
                  canSubmit: allComplete,
                  onSave: _saveAndExit,
                  onSubmit: () async {
                    setState(() => _isSaving = true);
                    final success = await viewModel.submitAndSave();
                    if (!context.mounted) return;
                    setState(() => _isSaving = false);
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
                      _exitToHome(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            ref.read(propertyViewModelProvider).errorMessage ??
                                'Failed to submit evaluation',
                          ),
                          backgroundColor: theme.error,
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Lets the agent set the house score themselves, starting from the app's
  /// weighted suggestion, or go back to the suggestion.
  Future<void> _adjustHouseScore(PropertyState state) async {
    final theme = ref.read(themeConfigProvider);
    final result = await showRealEstateBottomSheet<_HouseScoreChoice>(
      context: context,
      theme: theme,
      builder: (_) => _HouseScoreSheet(
        current: state.houseScore ?? state.suggestedHouseScore ?? 70,
        suggested: state.suggestedHouseScore,
        isManual: state.houseScoreIsManual,
        theme: theme,
      ),
    );
    if (result == null || !mounted) return;
    final error = await ref
        .read(propertyViewModelProvider.notifier)
        .setHouseScore(result.useSuggested ? null : result.value);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: theme.error),
      );
    }
  }

  /// Returns to the home list by popping this screen, so whoever pushed it
  /// sees its push complete (Home refreshes the list on that). Falls back to
  /// go() only when there is nothing to pop, e.g. after a deep link.
  void _exitToHome(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.homePath);
    }
  }

  /// Back arrow / back gesture. Photos still waiting to upload are retried
  /// first, and the agent is warned before leaving loses any that failed. A
  /// listing left without anything worth keeping is deleted rather than
  /// lingering on the home screen as an empty card.
  Future<void> _leave() async {
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    if (viewModel.pendingPhotoCount > 0) {
      await viewModel.saveExteriorPhotos();
      if (!mounted) return;
      final pending = viewModel.pendingPhotoCount;
      if (pending > 0 && !await _confirmLeaveWithPendingPhotos(pending)) {
        return;
      }
      if (!mounted) return;
    }
    final discarded = await viewModel.discardIfEmpty();
    if (!mounted) return;
    if (discarded) {
      ref.invalidate(listingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing was captured, so it was not kept.'),
        ),
      );
    }
    _exitToHome(context);
  }

  /// Photos not on the server live only in memory, so leaving loses them.
  Future<bool> _confirmLeaveWithPendingPhotos(int count) async {
    final photos = count == 1 ? '1 photo has' : '$count photos have';
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Photos not uploaded'),
        content: Text(
          "$photos not uploaded yet, so they aren't saved. If you leave now "
          'they will be lost. Stay, check your connection, and save again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Leave anyway'),
          ),
        ],
      ),
    );
    return leave == true;
  }

  /// Saves anything the overview still holds, then returns to the home list.
  Future<void> _saveAndExit() async {
    setState(() => _isSaving = true);
    final viewModel = ref.read(propertyViewModelProvider.notifier);
    if (await viewModel.discardIfEmpty()) {
      if (!mounted) return;
      ref.invalidate(listingsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to save yet, so it was not kept.'),
        ),
      );
      _exitToHome(context);
      return;
    }
    final error = await viewModel.saveOverview();
    if (!mounted) return;
    setState(() => _isSaving = false);
    final theme = ref.read(themeConfigProvider);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: theme.error),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Property saved'),
        backgroundColor: theme.primaryColor,
      ),
    );
    ref.invalidate(listingsProvider);
    _exitToHome(context);
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
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
        _exitToHome(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(mapFailure(e).message)));
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

/// Pinned footer: Save Property always, plus Submit Evaluation once every
/// section is complete.
class _BottomActions extends StatelessWidget {
  final RealEstateTheme theme;
  final bool isSaving;
  final bool canSubmit;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  const _BottomActions({
    required this.theme,
    required this.isSaving,
    required this.canSubmit,
    required this.onSave,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        border: Border(top: BorderSide(color: theme.borderLight, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 54,
          child: isSaving
              ? Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.primaryColor,
                    ),
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Save Property',
                        fullWidth: true,
                        // Submit is the main action once it is available.
                        type: canSubmit
                            ? ButtonType.outline
                            : ButtonType.primary,
                        theme: theme,
                        onTap: onSave,
                      ),
                    ),
                    if (canSubmit) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Submit',
                          fullWidth: true,
                          theme: theme,
                          onTap: onSubmit,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

/// "3 costs captured" / "Rates R 800/month" / "Not provided", in the
/// currency chosen in Settings.
String _expensesSummary(PropertyState state, String currency) {
  final c = state.propertyRunningCosts;
  final filled = [
    c.monthlyLevy,
    c.monthlyRates,
    c.electricity,
    c.water,
    c.sewage,
    c.refuse,
  ].where((v) => v.trim().isNotEmpty).length;
  if (filled == 0) return 'Not provided';
  if (filled == 1 && c.monthlyRates.trim().isNotEmpty) {
    return 'Rates $currency ${c.monthlyRates}/month';
  }
  return '$filled cost${filled == 1 ? '' : 's'} captured';
}

/// Section progress and the house score.
class _ProgressSummary extends StatelessWidget {
  final int completeCount;
  final int totalCount;
  final double? houseScore;
  final bool isManual;
  final VoidCallback onAdjustScore;
  final RealEstateTheme theme;
  final TextTheme textTheme;

  const _ProgressSummary({
    required this.completeCount,
    required this.totalCount,
    required this.houseScore,
    required this.isManual,
    required this.onAdjustScore,
    required this.theme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completeCount / totalCount;
    final score = houseScore;
    return Container(
      decoration: BoxDecoration(
        color: theme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.borderLight),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$completeCount of $totalCount sections complete',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: theme.borderLight,
                        color: completeCount == totalCount
                            ? theme.completeColor
                            : theme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            VerticalDivider(width: 1, color: theme.borderLight),
            InkWell(
              onTap: onAdjustScore,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score == null ? '–' : RoomScore.percent(score),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: score == null
                                ? theme.textSecondary
                                : theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.tune, size: 16, color: theme.textSecondary),
                      ],
                    ),
                    Text(
                      score == null
                          ? 'House score'
                          : isManual
                          ? 'House score · set by you'
                          : 'House score · suggested',
                      style: textTheme.bodyMedium?.copyWith(
                        color: theme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HouseScoreChoice {
  final double? value;
  final bool useSuggested;

  const _HouseScoreChoice.value(double this.value) : useSuggested = false;
  const _HouseScoreChoice.suggested() : value = null, useSuggested = true;
}

/// House score editor: a 0–100 slider starting at the current score, the
/// app's suggestion for reference, and a way back to it.
class _HouseScoreSheet extends StatefulWidget {
  final double current;
  final double? suggested;
  final bool isManual;
  final RealEstateTheme theme;

  const _HouseScoreSheet({
    required this.current,
    required this.suggested,
    required this.isManual,
    required this.theme,
  });

  @override
  State<_HouseScoreSheet> createState() => _HouseScoreSheetState();
}

class _HouseScoreSheetState extends State<_HouseScoreSheet> {
  late double _value = widget.current.clamp(0, 100).roundToDouble();

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final textTheme = theme.toThemeData().textTheme;
    final suggested = widget.suggested;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.borderLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'House Score',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              suggested == null
                  ? 'Score the rooms and the app suggests one, weighting '
                        'kitchens, bathrooms and main rooms more heavily.'
                  : 'Suggested ${RoomScore.percent(suggested)} from the room '
                        'scores, weighting kitchens, bathrooms and main rooms '
                        'more heavily. Adjust it if the whole house tells a '
                        'different story.',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                RoomScore.percent(_value),
                style: textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
            ),
            Slider(
              value: _value,
              min: 0,
              max: 100,
              divisions: 100,
              label: RoomScore.percent(_value),
              activeColor: theme.primaryColor,
              onChanged: (v) => setState(() => _value = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (suggested != null && widget.isManual)
                  TextButton(
                    onPressed: () => Navigator.pop(
                      context,
                      const _HouseScoreChoice.suggested(),
                    ),
                    child: Text(
                      'Use suggested',
                      style: TextStyle(color: theme.textSecondary),
                    ),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, _HouseScoreChoice.value(_value)),
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: theme.onPrimary,
                    minimumSize: const Size(120, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save score'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
